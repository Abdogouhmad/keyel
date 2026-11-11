//! Unlocked session and safe on-disk storage.
//!
//! A [`Session`] owns the decrypted [`Vault`] and the vault key. It never
//! exposes the key and drops it (zeroized) when the session is locked.
//!
//! Saves are atomic: the new bytes go to a sibling `.tmp` file, are `fsync`ed,
//! the previous file is copied to `.bak`, and only then is the temp file
//! renamed over the main file.

use std::fmt;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};

use uuid::Uuid;
use zeroize::Zeroizing;

use crate::crypto::kdf::Argon2Params;
use crate::crypto::keys::VaultKey;
use crate::error::Error;
use crate::format::{self, CreatedVault, Header, UnlockedVault};

use super::migrate::migrate;
use super::model::{now_unix, Entry, Vault};

/// An unlocked vault bound to a file.
pub struct Session {
    header: Header,
    vault_key: VaultKey,
    vault: Vault,
    path: PathBuf,
}

impl fmt::Debug for Session {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Session")
            .field("path", &self.path)
            .field("entries", &self.vault.entries.len())
            .field("vault", &"[REDACTED]")
            .field("vault_key", &self.vault_key)
            .finish()
    }
}

impl Session {
    /// Create a new vault file and return the unlocked session plus the
    /// one-time recovery key.
    pub fn create(
        path: impl Into<PathBuf>,
        master: &str,
        params: Argon2Params,
    ) -> Result<(Self, String), Error> {
        let path = path.into();
        let vault = Vault::new();
        let payload = Zeroizing::new(vault.to_bytes()?);
        let CreatedVault {
            bytes,
            recovery_key,
            header,
            vault_key,
        } = format::create(master, &payload, params)?;
        write_atomic(&path, &bytes)?;
        Ok((
            Self {
                header,
                vault_key,
                vault,
                path,
            },
            recovery_key,
        ))
    }

    /// Open an existing vault with the master password.
    pub fn open(path: impl Into<PathBuf>, master: &str) -> Result<Self, Error> {
        let path = path.into();
        open_with_fallback(&path, |bytes, path| {
            let unlocked = format::unlock_with_master(bytes, master)?;
            Self::from_unlocked(unlocked, path.to_path_buf())
        })
    }

    /// Open an existing vault with the recovery key.
    pub fn open_with_recovery(path: impl Into<PathBuf>, recovery: &str) -> Result<Self, Error> {
        let path = path.into();
        open_with_fallback(&path, |bytes, path| {
            let unlocked = format::unlock_with_recovery(bytes, recovery)?;
            Self::from_unlocked(unlocked, path.to_path_buf())
        })
    }

    /// Encrypt and atomically write the current vault.
    pub fn save(&self) -> Result<(), Error> {
        let payload = Zeroizing::new(self.vault.to_bytes()?);
        let bytes = format::seal(&self.header, &payload, &self.vault_key)?;
        write_atomic(&self.path, &bytes)
    }

    /// Re-wrap the vault key with a new master password.
    ///
    /// The old master password is verified before the vault file is modified.
    /// Unsaved changes are preserved. Only the master keyslot is rewritten;
    /// the encrypted body is copied byte for byte.
    pub fn change_master(
        &mut self,
        old_master: &str,
        new_master: &str,
        params: Argon2Params,
    ) -> Result<(), Error> {
        let payload = Zeroizing::new(self.vault.to_bytes()?);

        // Encrypt the current in-memory vault without writing to disk.
        let bytes = format::seal(&self.header, &payload, &self.vault_key)?;

        // Verify old_master and re-wrap the master keyslot.
        let rekeyed = format::change_master(&bytes, old_master, new_master, params)?;

        // Write only after successful password verification and re-keying.
        write_atomic(&self.path, &rekeyed)?;

        // Refresh the session with the new master password.
        *self = Self::open(&self.path, new_master)?;

        Ok(())
    }
    /// Re-wrap the vault key with a new master password using this session's
    /// already-authenticated key.
    ///
    /// This is the recovery path: the caller unlocked with the recovery key,
    /// so the old master password is unknown. The recovery keyslot is left
    /// untouched, so the same recovery key keeps working afterwards. The
    /// session is reopened with `new_master`.
    pub fn reset_master(&mut self, new_master: &str, params: Argon2Params) -> Result<(), Error> {
        self.save()?;
        let path = self.path.clone();
        let bytes = fs::read(&path).map_err(storage_error)?;
        let rekeyed =
            format::change_master_with_vault_key(&bytes, &self.vault_key, new_master, params)?;
        write_atomic(&path, &rekeyed)?;
        *self = Self::open(&path, new_master)?;
        Ok(())
    }

    /// Drop the vault key and the decrypted payload.
    pub fn lock(self) {
        // `self` is dropped here; `VaultKey` and `Vault` wipe/drop their data.
    }

    /// Path of the backing file.
    pub fn path(&self) -> &Path {
        &self.path
    }

    /// Read the decrypted vault.
    pub fn vault(&self) -> &Vault {
        &self.vault
    }

    /// Mutate the decrypted vault. Call [`Session::save`] afterwards.
    pub fn vault_mut(&mut self) -> &mut Vault {
        &mut self.vault
    }

    /// Add an entry to the unlocked vault.
    pub fn add_entry(&mut self, entry: Entry) -> Uuid {
        self.vault.add_entry(entry)
    }

    fn from_unlocked(unlocked: UnlockedVault, path: PathBuf) -> Result<Self, Error> {
        let mut vault = Vault::from_bytes(&unlocked.plaintext[..])?;
        let from_version = vault.schema_version;
        vault = migrate(vault, from_version)?;
        vault.purge_expired(now_unix());
        Ok(Self {
            header: unlocked.header,
            vault_key: unlocked.vault_key,
            vault,
            path,
        })
    }
}

/// Try the main file, then fall back to `.bak` only for structural damage.
///
/// An AEAD failure is reported as `WrongPassword` and is *not* retried against
/// the backup, because a stale backup may be protected by an old password.
/// Structural failures (bad magic, truncation, invalid header, unknown
/// version) cannot be a wrong password and safely trigger the fallback.
fn open_with_fallback<F>(path: &Path, attempt: F) -> Result<Session, Error>
where
    F: Fn(&[u8], &Path) -> Result<Session, Error>,
{
    match fs::read(path) {
        Ok(bytes) => match attempt(&bytes, path) {
            Ok(session) => Ok(session),
            Err(error) if is_structural(&error) => {
                let backup = backup_path(path);
                match fs::read(&backup) {
                    Ok(bytes) => attempt(&bytes, path).map_err(|_| error),
                    Err(_) => Err(error),
                }
            }
            Err(error) => Err(error),
        },
        Err(_) => {
            let backup = backup_path(path);
            let bytes = fs::read(&backup).map_err(|_| {
                Error::Storage(format!("cannot read vault file {}", path.display()))
            })?;
            attempt(&bytes, path)
        }
    }
}

fn is_structural(error: &Error) -> bool {
    matches!(error, Error::Corrupted | Error::UnsupportedVersion(_))
}

/// Write `bytes` to `path` atomically, keeping one `.bak` of the previous file.
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

    if path.exists() {
        let backup = backup_path(path);
        fs::copy(path, &backup).map_err(storage_error)?;
        // Best-effort durability for the backup; the main file is untouched.
        if let Ok(file) = File::open(&backup) {
            let _ = file.sync_all();
        }
    }

    fs::rename(&tmp, path).map_err(storage_error)?;
    sync_parent(path);
    Ok(())
}

fn backup_path(path: &Path) -> PathBuf {
    with_suffix(path, "bak")
}

fn temp_path(path: &Path) -> PathBuf {
    with_suffix(path, "tmp")
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

fn sync_parent(path: &Path) {
    if let Some(parent) = path.parent() {
        if let Ok(dir) = File::open(parent) {
            let _ = dir.sync_all();
        }
    }
}

fn storage_error(error: std::io::Error) -> Error {
    Error::Storage(error.to_string())
}
