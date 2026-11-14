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
/// sharing it.
pub fn export_csv(path: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        let csv = import::export_csv(session.vault());
        std::fs::write(&path, csv).map_err(|_| VaultApiError::Storage)
    })
}

fn read_and_parse(path: &str) -> Result<ParsedImport, VaultApiError> {
    let bytes = std::fs::read(path).map_err(|_| VaultApiError::Storage)?;
    let text = String::from_utf8(bytes).map_err(|_| VaultApiError::MalformedImport)?;
    Ok(import::parse(&text)?)
}
