//! End-to-end tests for the vault model, search and atomic storage.
//!
//! These tests use tiny Argon2 parameters so the suite stays fast. Production
//! defaults are calibrated separately (phase 0.6).

use std::fs;

use keyel_core::crypto::kdf::Argon2Params;
use keyel_core::vault::{
    search, Card, Entry, EntryBody, EntryFilter, Login, Note, Session, TotpConfig, Vault,
    TRASH_RETENTION_SECS,
};
use keyel_core::Error;
use proptest::prelude::*;

fn fast_params() -> Argon2Params {
    Argon2Params {
        m_kib: 8,
        t: 1,
        p: 1,
    }
}

fn temp_vault_path(dir: &tempfile::TempDir) -> std::path::PathBuf {
    dir.path().join("vault.keyel")
}

fn sample_login(index: usize) -> Entry {
    let mut entry = Entry::login(
        format!("Entry {index:04}"),
        Login {
            username: format!("user{index}@example.com"),
            password: format!("password-{index}"),
            url: format!("https://site{index}.example"),
            totp: if index.is_multiple_of(10) {
                Some(TotpConfig::new("JBSWY3DPEHPK3PXP"))
            } else {
                None
            },
            ..Login::default()
        },
    );
    entry.tags = vec!["bulk".to_string()];
    if index.is_multiple_of(7) {
        entry.favorite = true;
    }
    entry
}

#[test]
fn create_lock_reopen_search_and_compare_1000_entries() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, recovery) = Session::create(&path, "master", fast_params()).unwrap();
    for index in 0..1000 {
        session.add_entry(sample_login(index));
    }
    session.save().unwrap();
    let before = session.vault().clone();
    session.lock();

    let mut reopened = Session::open(&path, "master").unwrap();
    assert_eq!(reopened.vault(), &before);

    let results = search(reopened.vault(), "entry 0500", &EntryFilter::default());
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].title, "Entry 0500");
    assert!(!results[0].subtitle.contains("password-500"));

    let favorites = EntryFilter {
        favorite: Some(true),
        ..EntryFilter::default()
    };
    assert_eq!(search(reopened.vault(), "", &favorites).len(), 143);

    // Mutate, save, reopen again.
    reopened.add_entry(Entry::note(
        "After reopen",
        Note {
            content: "x".into(),
        },
    ));
    reopened.save().unwrap();
    reopened.lock();

    let again = Session::open(&path, "master").unwrap();
    assert_eq!(again.vault().entries.len(), 1001);

    // The recovery key opens the same data.
    let recovered = Session::open_with_recovery(&path, &recovery).unwrap();
    assert_eq!(recovered.vault().entries.len(), 1001);
}

#[test]
fn atomic_save_keeps_a_previous_backup() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, _) = Session::create(&path, "master", fast_params()).unwrap();
    session.add_entry(Entry::note("first", Note::default()));
    session.save().unwrap();

    session.add_entry(Entry::note("second", Note::default()));
    session.save().unwrap();
    assert_eq!(
        Session::open(&path, "master")
            .unwrap()
            .vault()
            .entries
            .len(),
        2
    );

    // Corrupt the main file structurally. The backup has the previous version.
    fs::write(&path, b"this is not a vault").unwrap();
    let recovered = Session::open(&path, "master").unwrap();
    assert_eq!(recovered.vault().entries.len(), 1);
    assert_eq!(recovered.vault().entries[0].title, "first");

    // Saving from the recovered session repairs the main file.
    recovered.save().unwrap();
    assert_eq!(
        Session::open(&path, "master")
            .unwrap()
            .vault()
            .entries
            .len(),
        1
    );
}

#[test]
fn a_leftover_tmp_file_does_not_affect_opening() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, _) = Session::create(&path, "master", fast_params()).unwrap();
    session.add_entry(Entry::note("kept", Note::default()));
    session.save().unwrap();
    session.lock();

    fs::write(
        format!("{}.tmp", path.display()),
        b"half-written crash junk",
    )
    .unwrap();
    let reopened = Session::open(&path, "master").unwrap();
    assert_eq!(reopened.vault().entries.len(), 1);

    // The next save overwrites the stale temp file.
    reopened.save().unwrap();
    let again = Session::open(&path, "master").unwrap();
    assert_eq!(again.vault().entries.len(), 1);
}

#[test]
fn trash_lifecycle_survives_save_and_reopen() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, _) = Session::create(&path, "master", fast_params()).unwrap();
    let id = session.add_entry(Entry::note("trash me", Note::default()));
    session.save().unwrap();
    session.lock();

    let mut reopened = Session::open(&path, "master").unwrap();
    reopened.vault_mut().delete_entry(id).unwrap();
    reopened.save().unwrap();
    reopened.lock();

    let mut reopened = Session::open(&path, "master").unwrap();
    assert!(reopened.vault().entry(id).unwrap().deleted_at.is_some());
    reopened.vault_mut().restore_entry(id).unwrap();
    reopened.save().unwrap();
    reopened.lock();

    assert!(Session::open(&path, "master")
        .unwrap()
        .vault()
        .entry(id)
        .unwrap()
        .deleted_at
        .is_none());
}

#[test]
fn expired_trash_is_purged_on_unlock() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, _) = Session::create(&path, "master", fast_params()).unwrap();
    let id = session.add_entry(Entry::note("old", Note::default()));
    session.save().unwrap();
    session.lock();

    let mut reopened = Session::open(&path, "master").unwrap();
    reopened.vault_mut().delete_entry(id).unwrap();
    reopened.vault_mut().entry_mut(id).unwrap().deleted_at =
        Some(keyel_core::vault::now_unix() - TRASH_RETENTION_SECS - 1);
    reopened.save().unwrap();
    reopened.lock();

    let reopened = Session::open(&path, "master").unwrap();
    assert!(reopened.vault().entry(id).is_none());
}

#[test]
fn folders_and_password_history_round_trip() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, _) = Session::create(&path, "master", fast_params()).unwrap();
    let folder = session.vault_mut().add_folder("Work");
    let mut entry = sample_login(1);
    entry.folder_id = Some(folder);
    let id = session.add_entry(entry.clone());
    session.save().unwrap();
    session.lock();

    let mut reopened = Session::open(&path, "master").unwrap();
    let mut changed = reopened.vault().entry(id).unwrap().clone();
    changed.body = EntryBody::Login(Login {
        password: "new-password".into(),
        ..match &entry.body {
            EntryBody::Login(login) => login.clone(),
            _ => unreachable!(),
        }
    });
    reopened.vault_mut().update_entry(changed).unwrap();
    reopened.save().unwrap();
    reopened.lock();

    let reopened = Session::open(&path, "master").unwrap();
    let stored = reopened.vault().entry(id).unwrap();
    let EntryBody::Login(login) = &stored.body else {
        panic!("expected login");
    };
    assert_eq!(login.password, "new-password");
    assert_eq!(login.password_history[0].password, "password-1");
    assert_eq!(stored.folder_id, Some(folder));
}

#[test]
fn wrong_password_and_missing_file_are_errors() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (session, _) = Session::create(&path, "master", fast_params()).unwrap();
    session.lock();
    assert_eq!(
        Session::open(&path, "wrong").unwrap_err(),
        Error::WrongPassword
    );

    let missing = dir.path().join("nope.keyel");
    assert!(matches!(
        Session::open(&missing, "master"),
        Err(Error::Storage(_))
    ));
}

#[test]
fn card_and_note_entries_round_trip() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, _) = Session::create(&path, "master", fast_params()).unwrap();
    session.add_entry(Entry::card(
        "Visa",
        Card {
            cardholder: "Ada Lovelace".into(),
            number: "4111111111111111".into(),
            expiry: "12/30".into(),
            cvv: "123".into(),
            brand: Some("Visa".into()),
        },
    ));
    session.add_entry(Entry::note(
        "Recovery codes",
        Note {
            content: "abc".into(),
        },
    ));
    session.save().unwrap();
    let before = session.vault().clone();
    session.lock();

    let reopened = Session::open(&path, "master").unwrap();
    assert_eq!(reopened.vault(), &before);
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(48))]

    #[test]
    fn payload_serialization_is_lossless(
        title in ".{0,40}",
        username in ".{0,40}",
        password in ".{0,40}",
        notes in ".{0,80}",
        tags in prop::collection::vec(".{0,20}", 0..5),
    ) {
        let mut vault = Vault::new();
        let mut entry = Entry::login(
            title,
            Login {
                username,
                password,
                url: "https://example.com".into(),
                ..Login::default()
            },
        );
        entry.notes = notes;
        entry.tags = tags;
        vault.add_entry(entry);

        let decoded = Vault::from_bytes(&vault.to_bytes().unwrap()).unwrap();
        prop_assert_eq!(vault, decoded);
    }
}
