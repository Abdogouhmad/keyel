//! High-level sync operations bound to the unlocked session.
//!
//! Every operation here runs in Rust: the sync key never crosses the bridge,
//! remote blobs are authenticated before anything is applied, and local saves
//! go through the existing atomic session writer.

use std::path::Path;
use zeroize::{Zeroize, Zeroizing};

use data_encoding::HEXLOWER;
use uuid::Uuid;

use crate::error::Error;
use crate::vault::model::{now_unix, SyncConfig, Vault, VAULT_SCHEMA_VERSION};
use crate::vault::Session;

use super::backend::{FolderBackend, SyncBackend};
use super::envelope;
use super::merge;
use super::pairing::PairingCode;
use super::payload::SyncPayload;

/// Non-secret sync state shown in the UI.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncStatus {
    pub enabled: bool,
    /// Hex sync group id, if enabled.
    pub sync_id: Option<String>,
    /// Hex device id, if enabled.
    pub device_id: Option<String>,
    /// Informational folder hint supplied by the user.
    pub folder_hint: String,
    /// Unix seconds of the last successful sync.
    pub last_sync_at: u64,
    /// Monotonic blob sequence, exposed so stale files can be detected.
    pub sequence: u64,
}

impl SyncStatus {
    /// Status for a disabled or missing configuration.
    pub fn disabled() -> Self {
        Self {
            enabled: false,
            sync_id: None,
            device_id: None,
            folder_hint: String::new(),
            last_sync_at: 0,
            sequence: 0,
        }
    }
}

/// Non-secret outcome of one manual sync.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SyncReport {
    pub pulled_files: usize,
    pub pushed_file: bool,
    pub entries_added: usize,
    pub entries_updated: usize,
    pub folders_added: usize,
    pub folders_updated: usize,
    pub conflicts_created: usize,
    pub tombstones_applied: usize,
    /// Non-secret, user-facing problems (for example a stale remote file).
    pub errors: Vec<String>,
}

/// Read the current, non-secret sync status.
pub fn status(vault: &Vault) -> SyncStatus {
    match vault.sync_config.as_ref().filter(|config| config.enabled) {
        None => SyncStatus::disabled(),
        Some(config) => SyncStatus {
            enabled: true,
            sync_id: Some(HEXLOWER.encode(&config.sync_id)),
            device_id: Some(HEXLOWER.encode(&config.device_id)),
            folder_hint: config.folder_hint.clone(),
            last_sync_at: config.last_sync_at,
            sequence: config.sequence,
        },
    }
}

/// Enable sync on this device and return the one-time pairing code.
///
/// The caller must show the code once and obtain explicit confirmation that it
/// was stored before letting the user leave the screen.
pub fn enable(vault: &mut Vault, folder_hint: impl Into<String>) -> Result<String, Error> {
    clear_stale_sync_config(vault)?;
    let pairing = PairingCode::generate();
    let code = pairing.encode();
    vault.sync_config = Some(SyncConfig {
        enabled: true,
        sync_id: pairing.sync_id,
        device_id: *Uuid::now_v7().as_bytes(),
        sync_key: *pairing.sync_key,
        folder_hint: folder_hint.into(),
        last_sync_at: 0,
        sequence: 0,
    });
    Ok(code)
}

/// Re-display the pairing code from the secret already stored in the vault.
pub fn pairing_code(vault: &Vault) -> Result<String, Error> {
    let config = vault
        .sync_config
        .as_ref()
        .filter(|config| config.enabled)
        .ok_or(Error::NotFound)?;
    Ok(PairingCode {
        sync_id: config.sync_id,
        sync_key: Zeroizing::new(config.sync_key),
    }
    .encode())
}

/// Join an existing sync group using a pairing code from another device.
pub fn join(
    vault: &mut Vault,
    code: &str,
    folder_hint: impl Into<String>,
) -> Result<SyncStatus, Error> {
    clear_stale_sync_config(vault)?;
    let pairing = PairingCode::parse(code)?;
    vault.sync_config = Some(SyncConfig {
        enabled: true,
        sync_id: pairing.sync_id,
        device_id: *Uuid::now_v7().as_bytes(),
        sync_key: *pairing.sync_key,
        folder_hint: folder_hint.into(),
        last_sync_at: 0,
        sequence: 0,
    });
    Ok(status(vault))
}

/// Disable sync locally. Remote files are left untouched so a later re-enable
/// can restore from the same group.
pub fn disable(vault: &mut Vault) -> Result<(), Error> {
    let mut config = vault.sync_config.take().ok_or(Error::NotFound)?;
    config.sync_key.zeroize();
    Ok(())
}

/// Refuse to change an active group, but allow a disabled leftover config to be
/// replaced. `status()` reports disabled configs as off, so the UI rightly
/// offers Create/Join; the old code rejected that path and left users stuck.
fn clear_stale_sync_config(vault: &mut Vault) -> Result<(), Error> {
    if vault
        .sync_config
        .as_ref()
        .is_some_and(|config| config.enabled)
    {
        return Err(Error::Storage(
            "sync is already enabled on this vault".into(),
        ));
    }
    if let Some(config) = vault.sync_config.as_mut() {
        config.sync_key.zeroize();
    }
    Ok(())
}

/// Pull every remote file, merge, push this device's file and save locally.
///
/// Remote authentication and decoding happen before any local state is
/// changed: a corrupt or tampered blob aborts the whole operation.
pub fn sync_now(session: &mut Session, folder: impl AsRef<Path>) -> Result<SyncReport, Error> {
    let config = session
        .vault()
        .sync_config
        .as_ref()
        .filter(|config| config.enabled)
        .ok_or(Error::NotFound)?
        .clone();
    let backend = FolderBackend::new(folder.as_ref());

    // Read and authenticate all remote state first. Nothing below this point
    // runs if a file is corrupt, tampered with or from the wrong group.
    let files = backend.list(&config.sync_id)?;
    let mut payloads = Vec::with_capacity(files.len());
    let mut last_self_sequence = 0u64;
    let mut report = SyncReport {
        pulled_files: files.len(),
        ..SyncReport::default()
    };
    for file in &files {
        let bytes = backend.read(file)?;
        let (header, plaintext) = envelope::open(&config.sync_key, &bytes)?;
        if header.sync_id != config.sync_id {
            return Err(Error::Corrupted);
        }
        // A restored vault may have an older local counter than a file this
        // device wrote before the restore. Keep sequences monotonic so a
        // transport cannot mistake our new blob for a stale copy.
        if header.device_id == config.device_id {
            last_self_sequence = last_self_sequence.max(header.sequence);
        }
        payloads.push(SyncPayload::from_bytes(&plaintext)?);
    }
    let sequence = config.sequence.max(last_self_sequence.saturating_add(1));

    let (merged, merge_report) = merge::merge(session.vault(), &payloads, &config.device_id)?;
    *session.vault_mut() = merged;
    report.entries_added = merge_report.entries_added;
    report.entries_updated = merge_report.entries_updated;
    report.folders_added = merge_report.folders_added;
    report.folders_updated = merge_report.folders_updated;
    report.conflicts_created = merge_report.conflicts_created;
    report.tombstones_applied = merge_report.tombstones_applied;

    let local = session.vault();
    let payload = SyncPayload {
        schema_version: VAULT_SCHEMA_VERSION,
        folders: local.folders.clone(),
        entries: local.entries.clone(),
        tombstones: local.tombstones.clone(),
    };
    let plaintext = Zeroizing::new(payload.to_bytes()?);
    let blob = envelope::seal(
        &config.sync_key,
        &config.sync_id,
        &config.device_id,
        sequence,
        &plaintext,
    )?;
    backend.write(&config.sync_id, &config.device_id, &blob)?;
    report.pushed_file = true;

    {
        let stored = session
            .vault_mut()
            .sync_config
            .as_mut()
            .ok_or(Error::NotFound)?;
        stored.sequence = sequence.saturating_add(1);
        stored.last_sync_at = now_unix();
    }
    session.save()?;
    Ok(report)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::model::{Entry, Login, Note};

    fn fast_vault(path: &std::path::Path) -> Session {
        let (session, _) = Session::create(
            path,
            "master",
            crate::crypto::kdf::Argon2Params {
                m_kib: 8,
                t: 1,
                p: 1,
            },
        )
        .unwrap();
        session
    }

    #[test]
    fn enable_join_and_status_never_expose_the_key_in_debug() {
        let mut vault = Vault::new();
        let code = enable(&mut vault, "/sync").unwrap();
        assert!(vault.sync_config.is_some());
        let current = status(&vault);
        assert!(current.enabled);
        assert_eq!(current.folder_hint, "/sync");
        assert_eq!(pairing_code(&vault).unwrap(), code);

        assert!(enable(&mut vault, "/sync").is_err());
        assert!(join(&mut vault, &code, "/sync").is_err());
        disable(&mut vault).unwrap();
        assert!(!status(&vault).enabled);
        let debug = format!("{:?}", status(&vault));
        assert!(!debug.contains("sync_key"));
    }

    #[test]
    fn join_rejects_bad_codes() {
        let mut vault = Vault::new();
        assert!(join(&mut vault, "nope", "/sync").is_err());
        assert!(vault.sync_config.is_none());
    }

    #[test]
    fn disabled_leftover_config_can_be_replaced() {
        let mut first = Vault::new();
        let code = enable(&mut first, "/group-a").unwrap();

        let mut second = Vault::new();
        let old_code = enable(&mut second, "/old").unwrap();
        second.sync_config.as_mut().unwrap().enabled = false;
        assert!(!status(&second).enabled);

        let joined = join(&mut second, &code, "/group-b").unwrap();
        assert!(joined.enabled);
        assert_eq!(joined.folder_hint, "/group-b");
        assert_eq!(pairing_code(&second).unwrap(), code);
        assert_ne!(code, old_code);
    }

    #[test]
    fn two_devices_converge_through_a_shared_folder() {
        let dir = tempfile::tempdir().unwrap();
        let folder = dir.path().join("sync");
        let mut a = fast_vault(&dir.path().join("a.keyel"));
        let code = enable(a.vault_mut(), folder.to_string_lossy().into_owned()).unwrap();
        a.save().unwrap();

        let mut b = fast_vault(&dir.path().join("b.keyel"));
        join(b.vault_mut(), &code, folder.to_string_lossy().into_owned()).unwrap();
        b.save().unwrap();

        a.vault_mut().add_entry(Entry::note(
            "from A",
            Note {
                content: "secret a".into(),
            },
        ));
        a.save().unwrap();
        let first = sync_now(&mut a, &folder).unwrap();
        assert!(first.pushed_file);
        assert_eq!(first.pulled_files, 0);

        let second = sync_now(&mut b, &folder).unwrap();
        assert_eq!(second.entries_added, 1);
        assert_eq!(b.vault().entries.len(), 1);

        b.vault_mut().add_entry(Entry::note(
            "from B",
            Note {
                content: "secret b".into(),
            },
        ));
        sync_now(&mut b, &folder).unwrap();
        sync_now(&mut a, &folder).unwrap();
        assert_eq!(a.vault().entries.len(), 2);
        assert_eq!(b.vault().entries.len(), 2);
    }

    #[test]
    fn paired_devices_merge_login_entries_and_secrets() {
        let dir = tempfile::tempdir().unwrap();
        let folder = dir.path().join("sync");
        let mut a = fast_vault(&dir.path().join("a.keyel"));
        let code = enable(a.vault_mut(), folder.to_string_lossy().into_owned()).unwrap();
        a.save().unwrap();

        let mut b = fast_vault(&dir.path().join("b.keyel"));
        join(b.vault_mut(), &code, folder.to_string_lossy().into_owned()).unwrap();
        b.save().unwrap();

        a.vault_mut().add_entry(Entry::login(
            "Bank A",
            Login {
                username: "a@example.com".into(),
                password: "secret-a".into(),
                ..Login::default()
            },
        ));
        a.save().unwrap();
        b.vault_mut().add_entry(Entry::login(
            "Bank B",
            Login {
                username: "b@example.com".into(),
                password: "secret-b".into(),
                ..Login::default()
            },
        ));
        b.save().unwrap();

        sync_now(&mut a, &folder).unwrap();
        sync_now(&mut b, &folder).unwrap();
        sync_now(&mut a, &folder).unwrap();

        for vault in [a.vault(), b.vault()] {
            assert_eq!(vault.entries.len(), 2);
            assert!(vault.entries.iter().any(|entry| entry.title == "Bank A"));
            assert!(vault.entries.iter().any(|entry| entry.title == "Bank B"));
            let passwords = vault
                .entries
                .iter()
                .filter_map(|entry| match &entry.body {
                    crate::vault::model::EntryBody::Login(login) => Some(login.password.as_str()),
                    _ => None,
                })
                .collect::<Vec<_>>();
            assert!(passwords.contains(&"secret-a"));
            assert!(passwords.contains(&"secret-b"));
        }
    }

    #[test]
    fn tampered_remote_file_aborts_without_changing_local_state() {
        let dir = tempfile::tempdir().unwrap();
        let folder = dir.path().join("sync");
        let mut a = fast_vault(&dir.path().join("a.keyel"));
        enable(a.vault_mut(), folder.to_string_lossy().into_owned()).unwrap();
        a.vault_mut().add_entry(Entry::note(
            "local",
            Note {
                content: "keep".into(),
            },
        ));
        sync_now(&mut a, &folder).unwrap();
        let before = a.vault().clone();

        let files = FolderBackend::new(&folder)
            .list(&a.vault().sync_config.as_ref().unwrap().sync_id)
            .unwrap();
        let mut bytes = FolderBackend::new(&folder).read(&files[0]).unwrap();
        let last = bytes.len() - 1;
        bytes[last] ^= 1;
        std::fs::write(&files[0].path, bytes).unwrap();

        assert!(sync_now(&mut a, &folder).is_err());
        assert_eq!(a.vault(), &before);
    }

    #[test]
    fn concurrent_edits_are_synced_as_conflict_copies() {
        let dir = tempfile::tempdir().unwrap();
        let folder = dir.path().join("sync");
        let mut a = fast_vault(&dir.path().join("a.keyel"));
        let code = enable(a.vault_mut(), folder.to_string_lossy().into_owned()).unwrap();
        a.vault_mut().add_entry(Entry::note(
            "shared",
            Note {
                content: "base".into(),
            },
        ));
        sync_now(&mut a, &folder).unwrap();

        let mut b = fast_vault(&dir.path().join("b.keyel"));
        join(b.vault_mut(), &code, folder.to_string_lossy().into_owned()).unwrap();
        sync_now(&mut b, &folder).unwrap();

        let a_id = a.vault().entries[0].id;
        let a_device = a.vault().sync_config.as_ref().unwrap().device_id;
        a.vault_mut().entries[0].notes = "a edit".into();
        a.vault_mut()
            .entry_mut(a_id)
            .unwrap()
            .sync_meta
            .version
            .bump(&a_device);
        a.save().unwrap();
        let b_id = b.vault().entries[0].id;
        let b_device = b.vault().sync_config.as_ref().unwrap().device_id;
        b.vault_mut().entries[0].notes = "b edit".into();
        b.vault_mut()
            .entry_mut(b_id)
            .unwrap()
            .sync_meta
            .version
            .bump(&b_device);
        b.save().unwrap();
        sync_now(&mut b, &folder).unwrap();

        let report = sync_now(&mut a, &folder).unwrap();
        assert_eq!(report.conflicts_created, 1);
        assert_eq!(a.vault().entries.len(), 2);
        sync_now(&mut b, &folder).unwrap();
        assert_eq!(b.vault().entries.len(), 2);

        // Re-syncing creates no additional copies.
        let again = sync_now(&mut a, &folder).unwrap();
        assert_eq!(again.conflicts_created, 0);
        assert_eq!(a.vault().entries.len(), 2);
    }
}
