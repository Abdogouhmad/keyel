//! Session lifecycle exposed to Dart.
//!
//! Exactly one unlocked [`Session`] lives in Rust at a time. Dart can ask for
//! state, create/unlock/lock, and subscribe to lock events, but never receives
//! the vault key or any secret from this module.

use std::path::PathBuf;
use std::sync::{Mutex, MutexGuard};

use keyel_core::crypto::kdf::Argon2Params;
use keyel_core::vault::Session;

use crate::frb_generated::StreamSink;

use super::error::VaultApiError;

static SESSION: Mutex<Option<Session>> = Mutex::new(None);
static VAULT_PATH: Mutex<Option<PathBuf>> = Mutex::new(None);
static LOCK_SINK: Mutex<Option<StreamSink<String>>> = Mutex::new(None);

fn session_slot() -> MutexGuard<'static, Option<Session>> {
    SESSION
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

fn path_slot() -> MutexGuard<'static, Option<PathBuf>> {
    VAULT_PATH
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

fn lock_sink_slot() -> MutexGuard<'static, Option<StreamSink<String>>> {
    LOCK_SINK
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

fn current_path() -> Result<PathBuf, VaultApiError> {
    path_slot().clone().ok_or(VaultApiError::NotInitialized)
}

/// Configure the vault file path. Call once during app startup.
///
/// Changing the path locks any open session, so a session is never silently
/// bound to the wrong file.
#[flutter_rust_bridge::frb(sync)]
pub fn init(path: String) -> Result<(), VaultApiError> {
    let trimmed = path.trim();
    if trimmed.is_empty() {
        return Err(VaultApiError::InvalidPath);
    }

    let new_path = PathBuf::from(trimmed);
    let changed = {
        let mut slot = path_slot();
        let changed = slot.as_ref() != Some(&new_path);
        *slot = Some(new_path);
        changed
    };
    if changed {
        drop_session(true);
    }
    Ok(())
}

/// Whether a vault file exists at the configured path.
#[flutter_rust_bridge::frb(sync)]
pub fn vault_exists() -> bool {
    path_slot().as_ref().is_some_and(|path| path.exists())
}

/// Whether a vault is currently unlocked in Rust.
#[flutter_rust_bridge::frb(sync)]
pub fn is_unlocked() -> bool {
    session_slot().is_some()
}

/// The configured vault file path, for diagnostics and the debug screen.
#[flutter_rust_bridge::frb(sync)]
pub fn vault_path() -> Option<String> {
    path_slot()
        .as_ref()
        .map(|path| path.to_string_lossy().into_owned())
}

/// Create a new vault and leave it unlocked.
///
/// Returns the one-time recovery key. Show it to the user once and let them
/// store it offline; it is never returned again.
pub fn create_vault(master: String) -> Result<String, VaultApiError> {
    if master.is_empty() {
        return Err(VaultApiError::InvalidField);
    }
    let path = current_path()?;
    if path.exists() {
        return Err(VaultApiError::VaultExists);
    }

    let (session, recovery_key) = Session::create(&path, &master, Argon2Params::default())?;
    *session_slot() = Some(session);
    Ok(recovery_key)
}

/// Unlock the vault with the master password.
pub fn unlock_with_master(master: String) -> Result<(), VaultApiError> {
    if master.is_empty() {
        return Err(VaultApiError::WrongPassword);
    }
    let path = current_path()?;
    if !path.exists() {
        return Err(VaultApiError::VaultMissing);
    }

    let session = Session::open(&path, &master)?;
    *session_slot() = Some(session);
    Ok(())
}

/// Unlock the vault with the one-time recovery key.
pub fn unlock_with_recovery(recovery_key: String) -> Result<(), VaultApiError> {
    let path = current_path()?;
    if !path.exists() {
        return Err(VaultApiError::VaultMissing);
    }

    let session = Session::open_with_recovery(&path, &recovery_key)?;
    *session_slot() = Some(session);
    Ok(())
}

/// Verify a master password without changing the current session.
///
/// Opening the vault is the verification: the key must unwrap correctly. This
/// is used before persisting a credential for biometric unlock.
pub fn verify_master(master: String) -> Result<bool, VaultApiError> {
    if master.is_empty() {
        return Ok(false);
    }
    let path = current_path()?;
    if !path.exists() {
        return Err(VaultApiError::VaultMissing);
    }
    match Session::open(&path, &master) {
        Ok(session) => {
            session.lock();
            Ok(true)
        }
        Err(keyel_core::error::Error::WrongPassword) => Ok(false),
        Err(error) => Err(error.into()),
    }
}

/// Reset the master password after authenticating with the recovery key.
///
/// The recovery keyslot is preserved, so the same recovery key remains valid.
/// On success the session is left unlocked with the new master password.
pub fn reset_master_with_recovery(
    recovery_key: String,
    new_master: String,
) -> Result<(), VaultApiError> {
    if new_master.is_empty() {
        return Err(VaultApiError::InvalidField);
    }
    let path = current_path()?;
    if !path.exists() {
        return Err(VaultApiError::VaultMissing);
    }

    let mut session = Session::open_with_recovery(&path, &recovery_key)?;
    session.reset_master(&new_master, Argon2Params::default())?;
    *session_slot() = Some(session);
    Ok(())
}

/// Lock the vault now: drop the key, the decrypted payload and the session.
#[flutter_rust_bridge::frb(sync)]
pub fn lock() {
    drop_session(true);
}

/// Re-wrap the vault key with a new master password.
pub fn change_master(old_master: String, new_master: String) -> Result<(), VaultApiError> {
    if new_master.is_empty() {
        return Err(VaultApiError::InvalidField);
    }

    let mut guard = session_slot();
    let session = guard.as_mut().ok_or(VaultApiError::Locked)?;
    session.change_master(&old_master, &new_master, Argon2Params::default())?;
    Ok(())
}

/// Subscribe to session lock events.
///
/// Emits `"locked"` whenever a session is dropped: explicitly through
/// [`lock`], by changing the vault path, or by any future auto-lock.
pub fn lock_events(sink: StreamSink<String>) {
    *lock_sink_slot() = Some(sink);
}

/// Run `f` against the unlocked session, or fail with [`VaultApiError::Locked`].
pub(crate) fn with_session<T>(
    f: impl FnOnce(&mut Session) -> Result<T, VaultApiError>,
) -> Result<T, VaultApiError> {
    let mut guard = session_slot();
    let session = guard.as_mut().ok_or(VaultApiError::Locked)?;
    f(session)
}

fn drop_session(emit_event: bool) {
    let taken = session_slot().take();
    if let Some(session) = taken {
        session.lock();
        if emit_event {
            emit_lock_event();
        }
    }
}

fn emit_lock_event() {
    let sink = lock_sink_slot().clone();
    if let Some(sink) = sink {
        let _ = sink.add("locked".to_string());
    }
}
