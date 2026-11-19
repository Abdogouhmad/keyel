//! Transport-agnostic sync backend, starting with a user-chosen folder.
//!
//! Keyel never opens a network connection for sync: the user's own tool
//! (Syncthing, Nextcloud, a cloud-drive client, a USB stick) moves these files.
//! One file per device means devices never write the same file, so no write
//! conflicts can occur at the transport layer.

use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};

use data_encoding::HEXLOWER;

use crate::error::Error;

use super::version::DeviceId;

const FILE_PREFIX: &str = "keyel-sync-";
const FILE_SUFFIX: &str = ".kys";
const ID_HEX_LEN: usize = 32;

/// A remote sync file and the device that wrote it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RemoteFile {
    pub path: PathBuf,
    pub device_id: DeviceId,
}

/// Minimal storage contract for sync transports.
pub trait SyncBackend {
    /// All files belonging to `sync_id`, sorted by path.
    fn list(&self, sync_id: &DeviceId) -> Result<Vec<RemoteFile>, Error>;
    /// Read one encrypted blob.
    fn read(&self, file: &RemoteFile) -> Result<Vec<u8>, Error>;
    /// Atomically write the local device's blob, returning its path.
    fn write(
        &self,
        sync_id: &DeviceId,
        device_id: &DeviceId,
        bytes: &[u8],
    ) -> Result<RemoteFile, Error>;
}

/// A backend rooted at a folder picked by the user.
#[derive(Debug, Clone)]
pub struct FolderBackend {
    root: PathBuf,
}

impl FolderBackend {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn root(&self) -> &Path {
        &self.root
    }

    fn path_for(&self, sync_id: &DeviceId, device_id: &DeviceId) -> PathBuf {
        self.root.join(format!(
            "{FILE_PREFIX}{}-{}{FILE_SUFFIX}",
            HEXLOWER.encode(sync_id),
            HEXLOWER.encode(device_id)
        ))
    }
}

impl SyncBackend for FolderBackend {
    fn list(&self, sync_id: &DeviceId) -> Result<Vec<RemoteFile>, Error> {
        let expected = format!("{FILE_PREFIX}{}-", HEXLOWER.encode(sync_id));
        let entries = match fs::read_dir(&self.root) {
            Ok(entries) => entries,
            // An empty or not-yet-created sync folder is not an error.
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(Vec::new()),
            Err(error) => return Err(storage_error(error)),
        };

        let mut files = Vec::new();
        for entry in entries {
            let entry = entry.map_err(storage_error)?;
            if !entry.file_type().map_err(storage_error)?.is_file() {
                continue;
            }
            let name = entry.file_name().to_string_lossy().into_owned();
            if !name.starts_with(&expected) || !name.ends_with(FILE_SUFFIX) {
                continue;
            }
            let id_part = &name[expected.len()..name.len() - FILE_SUFFIX.len()];
            if id_part.len() != ID_HEX_LEN {
                continue;
            }
            let Ok(bytes) = HEXLOWER.decode(id_part.as_bytes()) else {
                continue;
            };
            let Ok(device_id) = <[u8; 16]>::try_from(bytes) else {
                continue;
            };
            files.push(RemoteFile {
                path: entry.path(),
                device_id,
            });
        }
        files.sort_by(|a, b| a.path.cmp(&b.path));
        Ok(files)
    }

    fn read(&self, file: &RemoteFile) -> Result<Vec<u8>, Error> {
        fs::read(&file.path).map_err(storage_error)
    }

    fn write(
        &self,
        sync_id: &DeviceId,
        device_id: &DeviceId,
        bytes: &[u8],
    ) -> Result<RemoteFile, Error> {
        let path = self.path_for(sync_id, device_id);
        atomic_write(&path, bytes)?;
        Ok(RemoteFile {
            path,
            device_id: *device_id,
        })
    }
}

/// Mirror of the vault writer: `.tmp` → `fsync` → `.bak` → rename.
fn atomic_write(path: &Path, bytes: &[u8]) -> Result<(), Error> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).map_err(storage_error)?;
        }
    }
    let tmp = with_suffix(path, "tmp");
    let write_result = (|| -> std::io::Result<()> {
        let mut file = File::create(&tmp)?;
        file.write_all(bytes)?;
        file.sync_all()?;
        Ok(())
    })();
    if let Err(error) = write_result {
        let _ = fs::remove_file(&tmp);
        return Err(storage_error(error));
    }

    if path.exists() {
        let backup = with_suffix(path, "bak");
        fs::copy(path, &backup).map_err(storage_error)?;
        if let Ok(file) = File::open(&backup) {
            let _ = file.sync_all();
        }
    }
    fs::rename(&tmp, path).map_err(storage_error)?;
    if let Some(parent) = path.parent() {
        if let Ok(dir) = File::open(parent) {
            let _ = dir.sync_all();
        }
    }
    Ok(())
}

fn with_suffix(path: &Path, suffix: &str) -> PathBuf {
    let mut name = path
        .file_name()
        .map(|name| name.to_os_string())
        .unwrap_or_default();
    name.push(".");
    name.push(suffix);
    path.with_file_name(name)
}

fn storage_error(error: std::io::Error) -> Error {
    Error::Storage(error.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn id(n: u8) -> DeviceId {
        let mut value = [0u8; 16];
        value[15] = n;
        value
    }

    #[test]
    fn list_ignores_other_groups_and_temporary_files() {
        let dir = tempfile::tempdir().unwrap();
        let backend = FolderBackend::new(dir.path());
        let sync_id = id(1);
        let device = id(2);

        backend.write(&sync_id, &device, b"blob").unwrap();
        fs::write(
            dir.path()
                .join(format!("keyel-sync-{}-ab.bak", HEXLOWER.encode(&sync_id))),
            b"x",
        )
        .unwrap();
        fs::write(dir.path().join("unrelated.txt"), b"x").unwrap();
        backend.write(&id(9), &device, b"other").unwrap();

        let files = backend.list(&sync_id).unwrap();
        assert_eq!(files.len(), 1);
        assert_eq!(files[0].device_id, device);
        assert_eq!(backend.read(&files[0]).unwrap(), b"blob");
    }

    #[test]
    fn write_is_atomic_and_keeps_a_backup() {
        let dir = tempfile::tempdir().unwrap();
        let backend = FolderBackend::new(dir.path());
        let sync_id = id(1);
        let device = id(2);
        backend.write(&sync_id, &device, b"first").unwrap();
        backend.write(&sync_id, &device, b"second").unwrap();

        let file = backend.list(&sync_id).unwrap().remove(0);
        assert_eq!(backend.read(&file).unwrap(), b"second");
        assert!(with_suffix(&file.path, "bak").exists());
        assert!(!with_suffix(&file.path, "tmp").exists());
    }

    #[test]
    fn an_empty_folder_lists_no_files() {
        let dir = tempfile::tempdir().unwrap();
        let backend = FolderBackend::new(dir.path().join("missing"));
        assert!(backend.list(&id(1)).unwrap().is_empty());
    }
}
