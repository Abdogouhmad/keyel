//! Encrypted vault backups.
//!
//! A backup is a complete `vault.keyel` file sealed under a **separate**
//! backup password. It uses the same on-disk format as the primary vault, but
//! with a single master slot and no recovery slot: the file only ever needs one
//! password to open.
//!
//! Restoring a backup combines it with the live vault in one of two ways:
//! [`ImportMode::Merge`] keeps the current contents and adds what is missing,
//! while [`ImportMode::Replace`] swaps them out entirely. Duplicate detection
//! compares stable entry and folder **ids**, which is distinct from the
//! content-based de-duplication used by CSV import — restoring the same backup
//! twice is a no-op, and entries the user edited on one side are never merged
//! field-by-field.

use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};

use zeroize::Zeroizing;

use crate::crypto::kdf::Argon2Params;
use crate::error::Error;
use crate::format;
use crate::import::{ImportMode, ImportReport};
use crate::vault::{migrate, Vault};

/// Encrypt `vault` under `password` and write it to `path`.
///
/// The write is atomic: bytes go to a sibling `.tmp` file that is `fsync`ed
/// and then renamed over `path`, so an interrupted export never leaves a
/// half-written backup behind.
pub fn export_encrypted(
    path: impl AsRef<Path>,
    vault: &Vault,
    password: &str,
    params: Argon2Params,
) -> Result<(), Error> {
    let payload = Zeroizing::new(vault.to_bytes()?);
    let bytes = format::seal_new(password, &payload, params)?;
    write_atomic(path.as_ref(), &bytes)
}

/// Read and decrypt a backup file into a vault.
///
/// Returns [`Error::WrongPassword`] when the password is wrong or the file was
/// tampered with, and [`Error::Corrupted`] when it is not a vault file at all.
pub fn read_encrypted(path: impl AsRef<Path>, password: &str) -> Result<Vault, Error> {
    let path = path.as_ref();
    let bytes = fs::read(path).map_err(|error| {
        Error::Storage(format!("cannot read backup {}: {error}", path.display()))
    })?;
    let unlocked = format::unlock_with_master(&bytes, password)?;
    let vault = Vault::from_bytes(&unlocked.plaintext[..])?;
    // Backups may pre-date the current schema; migrate before merging or use.
    let from_version = vault.schema_version;
    migrate(vault, from_version)
}

/// Combine a decrypted backup with the live vault.
///
/// In [`ImportMode::Merge`] existing folders and entries are kept and only
/// items whose id is not already present are added; in [`ImportMode::Replace`]
/// the live vault is emptied first. The returned [`ImportReport`] counts what
/// happened, so the UI can summarise a restore.
pub fn apply(target: &mut Vault, source: Vault, mode: ImportMode) -> ImportReport {
    match mode {
        ImportMode::Merge => merge(target, source),
        ImportMode::Replace => replace(target, source),
    }
}

fn merge(target: &mut Vault, mut source: Vault) -> ImportReport {
    let mut report = ImportReport::default();

    let mut folder_ids: std::collections::HashSet<_> =
        target.folders.iter().map(|folder| folder.id).collect();
    for mut folder in std::mem::take(&mut source.folders) {
        if folder_ids.insert(folder.id) {
            // Append after the folders the user already has.
            folder.order = target.folders.len() as u32;
            target.folders.push(folder);
            report.folders_added += 1;
        }
    }

    let mut entry_ids: std::collections::HashSet<_> =
        target.entries.iter().map(|entry| entry.id).collect();
    for entry in std::mem::take(&mut source.entries) {
        if entry_ids.insert(entry.id) {
            report.record(&entry);
            target.add_entry(entry);
            report.added += 1;
        } else {
            report.skipped += 1;
        }
    }

    report
}

fn replace(target: &mut Vault, source: Vault) -> ImportReport {
    let mut report = ImportReport {
        added: source.entries.len() as u32,
        folders_added: source.folders.len() as u32,
        ..ImportReport::default()
    };
    for entry in &source.entries {
        report.record(entry);
    }

    // Drop the old contents; the old `Vault` wipes its secrets on drop.
    let old = std::mem::replace(target, source);
    drop(old);
    report
}

/// Atomic write: `path.tmp` -> fsync -> rename over `path`.
fn write_atomic(path: &Path, bytes: &[u8]) -> Result<(), Error> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).map_err(storage_error)?;
        }
    }

    let tmp = temp_path(path);
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

    fs::rename(&tmp, path).map_err(storage_error)?;
    if let Some(parent) = path.parent() {
        if let Ok(dir) = File::open(parent) {
            let _ = dir.sync_all();
        }
    }
    Ok(())
}

fn temp_path(path: &Path) -> PathBuf {
    let mut name = path
        .file_name()
        .map(|name| name.to_os_string())
        .unwrap_or_default();
    name.push(".tmp");
    path.with_file_name(name)
}

fn storage_error(error: std::io::Error) -> Error {
    Error::Storage(error.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::kdf::Argon2Params;
    use crate::vault::{Entry, Login, Note};

    /// Cheap KDF parameters: these tests exercise the file plumbing, not the
    /// Argon2 cost.
    fn params() -> Argon2Params {
        Argon2Params {
            m_kib: 8,
            t: 1,
            p: 1,
        }
    }

    fn sample_vault() -> Vault {
        let mut vault = Vault::new();
        let folder = vault.add_folder("Work");
        let mut entry = Entry::login(
            "Mail",
            Login {
                username: "ada".into(),
                password: "hunter2".into(),
                url: "https://mail.example".into(),
                ..Login::default()
            },
        );
        entry.folder_id = Some(folder);
        entry.tags = vec!["email".into()];
        vault.add_entry(entry);
        vault.add_entry(Entry::note(
            "Recovery codes",
            Note {
                content: "abc-123".into(),
            },
        ));
        vault
    }

    #[test]
    fn round_trips_through_a_backup_file() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("backup.keyel");
        let vault = sample_vault();

        export_encrypted(&path, &vault, "backup-pw", params()).unwrap();
        let restored = read_encrypted(&path, "backup-pw").unwrap();

        assert_eq!(vault, restored);
    }

    #[test]
    fn wrong_password_is_rejected() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("backup.keyel");
        export_encrypted(&path, &sample_vault(), "right", params()).unwrap();

        assert_eq!(
            read_encrypted(&path, "wrong").unwrap_err(),
            Error::WrongPassword
        );
    }

    #[test]
    fn a_corrupt_file_is_rejected() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("backup.keyel");
        fs::write(&path, b"not a vault").unwrap();

        assert_eq!(
            read_encrypted(&path, "whatever").unwrap_err(),
            Error::Corrupted
        );
    }

    #[test]
    fn merge_skips_ids_that_already_exist() {
        let mut target = sample_vault();
        let source = target.clone();
        let report = apply(&mut target, source, ImportMode::Merge);

        assert_eq!(report.added, 0);
        assert_eq!(report.skipped, 2);
        assert_eq!(target.entries.len(), 2);
    }

    #[test]
    fn merge_adds_only_the_missing_entries() {
        let mut target = Vault::new();
        target.add_entry(Entry::note("Mine", Note::default()));
        let source = sample_vault();

        let report = apply(&mut target, source, ImportMode::Merge);
        assert_eq!(report.added, 2);
        assert_eq!(report.skipped, 0);
        assert_eq!(report.logins, 1);
        assert_eq!(report.notes, 1);
        assert_eq!(report.folders_added, 1);
        assert_eq!(target.entries.len(), 3);
        assert_eq!(target.folders.len(), 1);
    }

    #[test]
    fn replace_discards_the_existing_vault() {
        let mut target = Vault::new();
        target.add_entry(Entry::note("Old", Note::default()));
        target.add_folder("Old folder");
        let source = sample_vault();

        let report = apply(&mut target, source, ImportMode::Replace);
        assert_eq!(report.added, 2);
        assert_eq!(report.folders_added, 1);
        assert_eq!(target.entries.len(), 2);
        assert_eq!(target.folders.len(), 1);
        assert!(target.entries.iter().all(|entry| entry.title != "Old"));
    }
}
