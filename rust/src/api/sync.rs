//! Sync APIs exposed to Dart.
//!
//! The sync key and pairing code stay inside Rust. Only non-secret status and
//! report DTOs, plus the pairing code returned once to enable/join, cross the
//! bridge. All calls require an unlocked session.

use zeroize::Zeroizing;

use crate::api::error::VaultApiError;
use crate::api::models::{SyncReportDto, SyncStatusDto};
use crate::api::session::with_session;
use keyel_core::sync as core;

/// Current non-secret sync state.
pub fn sync_status() -> Result<SyncStatusDto, VaultApiError> {
    with_session(|session| Ok(core::status(session.vault()).into()))
}

/// Enable sync and return the one-time pairing code.
///
/// The UI must show it once and require explicit confirmation that it was
/// stored before leaving the screen.
pub fn sync_enable(folder_hint: String) -> Result<String, VaultApiError> {
    with_session(|session| {
        let code = core::enable(session.vault_mut(), folder_hint)?;
        session.save()?;
        Ok(code)
    })
}

/// Re-display the pairing code from the secret already in the vault.
pub fn sync_pairing_code() -> Result<String, VaultApiError> {
    with_session(|session| Ok(core::pairing_code(session.vault())?))
}

/// Join a sync group using a pairing code from another device.
pub fn sync_join(code: String, folder_hint: String) -> Result<SyncStatusDto, VaultApiError> {
    let code = Zeroizing::new(code);
    with_session(|session| {
        let status = core::join(session.vault_mut(), &code, folder_hint)?;
        session.save()?;
        Ok(status.into())
    })
}

/// Disable sync locally. Remote files are left untouched.
pub fn sync_disable() -> Result<(), VaultApiError> {
    with_session(|session| {
        core::disable(session.vault_mut())?;
        session.save()?;
        Ok(())
    })
}

/// Pull, merge and push manually. `folder_path` is supplied by Dart (Rust never
/// hard-codes a platform-specific location).
pub fn sync_now(folder_path: String) -> Result<SyncReportDto, VaultApiError> {
    with_session(|session| {
        let report = core::sync_now(session, folder_path)?;
        Ok(report.into())
    })
}
