//! Encrypted backup and CSV import/export, exposed to Dart.
//!
//! Rust owns the file I/O: Dart passes paths (from the system file picker or a
//! temp directory) and never handles plaintext secrets itself. The only
//! plaintext that leaves Rust here is an unencrypted CSV export, which the UI
//! guards behind a red warning and an explicit confirmation.

use keyel_core::backup;
use keyel_core::crypto::kdf::Argon2Params;
use keyel_core::import::{self, ParsedImport};
use zeroize::Zeroizing;

use super::error::VaultApiError;
use super::models::{ImportModeDto, ImportPreviewDto, ImportReportDto};
use super::session::with_session;

/// Parse an import file and report what it contains, without changing anything.
///
/// Use this to show a preview (counts and failures) before the user commits to
/// [`import_csv`].
pub fn preview_import(path: String) -> Result<ImportPreviewDto, VaultApiError> {
    Ok(read_and_parse(&path)?.into())
}

/// Import a Bitwarden or Chrome CSV export into the unlocked vault.
pub fn import_csv(path: String, mode: ImportModeDto) -> Result<ImportReportDto, VaultApiError> {
    let parsed = read_and_parse(&path)?;
    with_session(|session| {
        let report = import::apply(session.vault_mut(), parsed, mode.into());
        session.save()?;
        Ok(report.into())
    })
}

/// Write the unlocked vault to `path` as an encrypted backup.
///
/// The backup uses a separate password and the same on-disk format as the
/// vault, so it can be restored with [`import_backup`] or opened on its own.
pub fn export_backup(path: String, password: String) -> Result<(), VaultApiError> {
    let password = Zeroizing::new(password);
    if password.is_empty() {
        return Err(VaultApiError::InvalidField);
    }
    with_session(|session| {
        backup::export_encrypted(
            &path,
            session.vault(),
            password.as_str(),
            Argon2Params::default(),
        )?;
        Ok(())
    })
}

/// Restore an encrypted backup into the unlocked vault.
///
/// Merge keeps the current contents and adds entries whose id is missing;
/// replace swaps the whole vault for the backup.
pub fn import_backup(
    path: String,
    password: String,
    mode: ImportModeDto,
) -> Result<ImportReportDto, VaultApiError> {
    let password = Zeroizing::new(password);
    let source = backup::read_encrypted(&path, password.as_str())?;
    with_session(|session| {
        let report = backup::apply(session.vault_mut(), source, mode.into());
        session.save()?;
        Ok(report.into())
    })
}

/// Write the unlocked vault to `path` as an **unencrypted** CSV export.
///
/// Every password in the vault ends up in plaintext on disk. The UI must warn
/// the user and get explicit confirmation first, then delete the file after
/// sharing it. The file is created with `create_new` and mode `0600` on Unix so
/// it never inherits a permissive umask or follows a pre-existing symlink.
pub fn export_csv(path: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        let csv = Zeroizing::new(import::export_csv(session.vault()));
        write_private_file(&path, csv.as_bytes())
    })
}

/// Create a brand-new file with owner-only permissions, then write and sync it.
#[cfg(unix)]
fn write_private_file(path: &str, bytes: &[u8]) -> Result<(), VaultApiError> {
    use std::io::Write;
    use std::os::unix::fs::OpenOptionsExt;

    let mut file = std::fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(0o600)
        .open(path)
        .map_err(|_| VaultApiError::Storage)?;
    file.write_all(bytes).map_err(|_| VaultApiError::Storage)?;
    file.sync_all().map_err(|_| VaultApiError::Storage)
}

#[cfg(not(unix))]
fn write_private_file(path: &str, bytes: &[u8]) -> Result<(), VaultApiError> {
    use std::io::Write;

    let mut file = std::fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(path)
        .map_err(|_| VaultApiError::Storage)?;
    file.write_all(bytes).map_err(|_| VaultApiError::Storage)?;
    file.sync_all().map_err(|_| VaultApiError::Storage)
}

fn read_and_parse(path: &str) -> Result<ParsedImport, VaultApiError> {
    // Both buffers carry the full plaintext export; keep them zeroized.
    let raw = Zeroizing::new(std::fs::read(path).map_err(|_| VaultApiError::Storage)?);
    let text = Zeroizing::new(
        std::str::from_utf8(&raw)
            .map_err(|_| VaultApiError::MalformedImport)?
            .to_owned(),
    );
    Ok(import::parse(&text)?)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[cfg(unix)]
    fn private_file_is_owner_only_and_never_overwritten() {
        use std::os::unix::fs::PermissionsExt;
        use std::time::{SystemTime, UNIX_EPOCH};

        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let path = std::env::temp_dir().join(format!("keyel-csv-perms-{nonce}"));
        let name = path.to_str().unwrap();

        write_private_file(name, b"secret").unwrap();
        let mode = std::fs::metadata(&path).unwrap().permissions().mode();
        assert_eq!(mode & 0o777, 0o600);

        // A second write must fail rather than truncate an existing export.
        assert!(write_private_file(name, b"other").is_err());
        assert_eq!(std::fs::read(&path).unwrap(), b"secret");
        std::fs::remove_file(&path).unwrap();
    }
}
