//! Public-API integration tests for the 1.5.0 sync stack.

use std::fs;

use keyel_core::crypto::kdf::Argon2Params;
use keyel_core::sync::{self, FolderBackend, PairingCode, SyncBackend, SyncPayload, VersionVector};
use keyel_core::vault::{Entry, Note, Session, Vault, VAULT_SCHEMA_VERSION};

fn fast_params() -> Argon2Params {
    Argon2Params {
        m_kib: 8,
        t: 1,
        p: 1,
    }
}

fn session(path: &std::path::Path) -> Session {
    Session::create(path, "master", fast_params()).unwrap().0
}

#[test]
fn pairing_code_round_trips_and_rejects_typos() {
    let code = PairingCode::generate();
    let encoded = code.encode();
    let decoded = PairingCode::parse(&encoded).unwrap();
    assert_eq!(decoded.sync_id, code.sync_id);
    assert_eq!(&decoded.sync_key[..], &code.sync_key[..]);

    let mut chars: Vec<char> = encoded.chars().collect();
    let last = chars.len() - 1;
    chars[last] = if chars[last] == 'A' { 'B' } else { 'A' };
    assert!(PairingCode::parse(&chars.into_iter().collect::<String>()).is_err());
}

#[test]
fn blob_envelope_fails_closed_on_tampering() {
    let key = [9u8; 32];
    let sync_id = [1u8; 16];
    let device = [2u8; 16];
    let blob = sync::seal(&key, &sync_id, &device, 3, b"secret payload").unwrap();
    let (header, plaintext) = sync::open(&key, &blob).unwrap();
    assert_eq!(header.sync_id, sync_id);
    assert_eq!(header.device_id, device);
    assert_eq!(header.sequence, 3);
    assert_eq!(&plaintext[..], b"secret payload");

    let mut bad = blob.clone();
    let last = bad.len() - 1;
    bad[last] ^= 1;
    assert!(sync::open(&key, &bad).is_err());
    assert!(sync::open(&[8u8; 32], &blob).is_err());
    assert!(sync::open(&key, &blob[..20]).is_err());
}

#[test]
fn merge_is_idempotent_for_concurrent_edits() {
    let a = [1u8; 16];
    let b = [2u8; 16];
    let mut base = Entry::note(
        "item",
        Note {
            content: "base".into(),
        },
    );
    base.sync_meta.version.bump(&a);

    let mut local = base.clone();
    local.notes = "a".into();
    local.sync_meta.version.bump(&a);
    let mut remote = base;
    remote.notes = "b".into();
    remote.sync_meta.version.bump(&b);

    let mut vault = Vault::new();
    vault.add_entry(local);
    let remote_state = SyncPayload {
        schema_version: VAULT_SCHEMA_VERSION,
        folders: Vec::new(),
        entries: vec![remote.clone()],
        tombstones: Vec::new(),
    };

    let (merged, report) =
        sync::merge_vaults(&vault, std::slice::from_ref(&remote_state), &a).unwrap();
    assert_eq!(report.conflicts_created, 1);
    assert_eq!(merged.entries.len(), 2);
    let (again, second) = sync::merge_vaults(&merged, &[remote_state], &a).unwrap();
    assert_eq!(second.conflicts_created, 0);
    assert_eq!(again, merged);
}

#[test]
fn folder_backend_writes_one_file_per_device() {
    let dir = tempfile::tempdir().unwrap();
    let backend = FolderBackend::new(dir.path());
    let sync_id = [3u8; 16];
    let first = [4u8; 16];
    let second = [5u8; 16];

    backend.write(&sync_id, &first, b"a").unwrap();
    backend.write(&sync_id, &second, b"b").unwrap();
    let files = backend.list(&sync_id).unwrap();
    assert_eq!(files.len(), 2);
    assert_eq!(backend.read(&files[0]).unwrap(), b"a");
    assert_eq!(backend.read(&files[1]).unwrap(), b"b");
    assert_eq!(
        files[1].path.extension().and_then(|value| value.to_str()),
        Some("kys")
    );
}

#[test]
fn two_offline_devices_converge_with_a_conflict_copy() {
    let dir = tempfile::tempdir().unwrap();
    let folder = dir.path().join("sync");
    let mut a = session(&dir.path().join("a.keyel"));
    let code = sync::enable(a.vault_mut(), folder.to_string_lossy().into_owned()).unwrap();

    let mut b = session(&dir.path().join("b.keyel"));
    sync::join(b.vault_mut(), &code, folder.to_string_lossy().into_owned()).unwrap();

    let id = a.vault_mut().add_entry(Entry::note(
        "shared",
        Note {
            content: "base".into(),
        },
    ));
    sync::sync_now(&mut a, &folder).unwrap();
    sync::sync_now(&mut b, &folder).unwrap();

    let a_device = a.vault().sync_config.as_ref().unwrap().device_id;
    let b_device = b.vault().sync_config.as_ref().unwrap().device_id;
    a.vault_mut().entry_mut(id).unwrap().notes = "A".into();
    a.vault_mut()
        .entry_mut(id)
        .unwrap()
        .sync_meta
        .version
        .bump(&a_device);
    b.vault_mut().entry_mut(id).unwrap().notes = "B".into();
    b.vault_mut()
        .entry_mut(id)
        .unwrap()
        .sync_meta
        .version
        .bump(&b_device);

    sync::sync_now(&mut a, &folder).unwrap();
    sync::sync_now(&mut b, &folder).unwrap();
    sync::sync_now(&mut a, &folder).unwrap();

    assert_eq!(a.vault().entries.len(), 2);
    assert_eq!(b.vault().entries.len(), 2);
    assert!(a.vault().entries.iter().any(|entry| entry.notes == "A"));
    assert!(b.vault().entries.iter().any(|entry| entry.notes == "B"));
}

#[test]
fn corrupt_remote_blob_leaves_local_vault_untouched() {
    let dir = tempfile::tempdir().unwrap();
    let folder = dir.path().join("sync");
    let mut device = session(&dir.path().join("device.keyel"));
    sync::enable(device.vault_mut(), folder.to_string_lossy().into_owned()).unwrap();
    device.vault_mut().add_entry(Entry::note(
        "keep",
        Note {
            content: "me".into(),
        },
    ));
    sync::sync_now(&mut device, &folder).unwrap();
    let before = device.vault().clone();

    let sync_id = device.vault().sync_config.as_ref().unwrap().sync_id;
    let files = FolderBackend::new(&folder).list(&sync_id).unwrap();
    let mut bytes = FolderBackend::new(&folder).read(&files[0]).unwrap();
    bytes.truncate(70);
    fs::write(&files[0].path, bytes).unwrap();

    assert!(sync::sync_now(&mut device, &folder).is_err());
    assert_eq!(device.vault(), &before);
}

#[test]
fn version_vectors_compare_causality_not_time() {
    let a = [1u8; 16];
    let b = [2u8; 16];
    let mut left = VersionVector::new();
    left.bump(&a);
    let mut right = VersionVector::new();
    right.bump(&b);
    assert_eq!(left.compare(&right), sync::VectorOrder::Concurrent);
    let joined = left.join(&right);
    assert!(joined.dominates(&left));
    assert!(joined.dominates(&right));
}
