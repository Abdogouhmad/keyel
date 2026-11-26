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
fn backup_only_vault_is_detected_and_openable() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);
    let (session, _recovery) = Session::create(&path, "master", fast_params()).unwrap();
    session.lock();

    // Simulate a main file lost to an interrupted rename. The Rust bridge must
    // still report a vault, otherwise onboarding would overwrite the backup.
    let backup = dir.path().join("vault.keyel.bak");
    fs::rename(&path, &backup).unwrap();
    assert!(!path.exists());
    assert!(keyel_core::vault::has_vault_file(&path));
    let reopened = Session::open(&path, "master").unwrap();
    assert!(reopened.vault().entries.is_empty());
}

#[cfg(unix)]
#[test]
fn created_vault_and_backup_are_private() {
    use std::os::unix::fs::PermissionsExt;

    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);
    let (mut session, _recovery) = Session::create(&path, "master", fast_params()).unwrap();

    let mode = fs::metadata(&path).unwrap().permissions().mode() & 0o777;
    assert_eq!(
        mode, 0o600,
        "vault file must not be readable by other users"
    );

    session.add_entry(sample_login(0));
    session.save().unwrap();

    let backup = dir.path().join("vault.keyel.bak");
    assert!(backup.exists());
    let mode = fs::metadata(&backup).unwrap().permissions().mode() & 0o777;
    assert_eq!(mode, 0o600, "backup must be private too");
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

#[test]
fn change_master_rewraps_the_same_body() {
    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let (mut session, recovery) = Session::create(&path, "old-master", fast_params()).unwrap();
    session.add_entry(Entry::note(
        "kept",
        Note {
            content: "x".into(),
        },
    ));
    session.save().unwrap();
    let before = session.vault().clone();

    session
        .change_master("old-master", "new-master", fast_params())
        .unwrap();
    assert_eq!(session.vault(), &before);
    session.lock();

    assert_eq!(
        Session::open(&path, "old-master").unwrap_err(),
        Error::WrongPassword
    );

    let reopened = Session::open(&path, "new-master").unwrap();
    assert_eq!(reopened.vault(), &before);

    // The recovery slot is untouched by a master-password change.
    let recovered = Session::open_with_recovery(&path, &recovery).unwrap();
    assert_eq!(recovered.vault(), &before);

    // A wrong old password never rewrites the file.
    let mut reopened = Session::open(&path, "new-master").unwrap();
    assert_eq!(
        reopened
            .change_master("wrong", "another", fast_params())
            .unwrap_err(),
        Error::WrongPassword
    );
    reopened.lock();
    assert!(Session::open(&path, "new-master").is_ok());
}

/// Roadmap item 12: a 5,000-entry vault must stay usable.
///
/// This is a regression guard, not a micro-benchmark: the ceilings are loose
/// on purpose so a slow shared CI runner does not flake, but an accidental
/// O(n^2) in save, open, search or filtering would blow through them. The
/// measured timings are printed so a human can spot a trend; run with
/// `cargo test -p keyel_core --test vault_model -- --nocapture` to see them.
#[test]
fn five_thousand_entry_vault_stays_within_budget() {
    use std::time::{Duration, Instant};

    let dir = tempfile::tempdir().unwrap();
    let path = temp_vault_path(&dir);

    let started = Instant::now();
    let (mut session, _recovery) = Session::create(&path, "master", fast_params()).unwrap();
    for index in 0..5_000 {
        session.add_entry(sample_login(index));
    }
    let build = started.elapsed();

    let started = Instant::now();
    session.save().unwrap();
    let save = started.elapsed();

    session.lock();
    let started = Instant::now();
    let reopened = Session::open(&path, "master").unwrap();
    let open = started.elapsed();

    let started = Instant::now();
    let hits = search(reopened.vault(), "entry 4999", &EntryFilter::default());
    let search_time = started.elapsed();

    let started = Instant::now();
    let favorites = search(
        reopened.vault(),
        "",
        &EntryFilter {
            favorite: Some(true),
            ..EntryFilter::default()
        },
    );
    let filter_time = started.elapsed();

    assert_eq!(reopened.vault().entries.len(), 5_000);
    assert_eq!(hits.len(), 1);
    assert_eq!(hits[0].title, "Entry 4999");
    // `sample_login` marks every seventh entry a favorite: 0, 7, ..., 4998.
    assert_eq!(favorites.len(), 715);

    // Generous ceilings: this guards against accidental O(n^2) work rather
    // than pinning a micro-benchmark. Debug builds on a shared runner are
    // several times slower than the numbers printed below.
    assert!(build < Duration::from_secs(15), "build took {build:?}");
    assert!(save < Duration::from_secs(20), "save took {save:?}");
    assert!(open < Duration::from_secs(20), "open took {open:?}");
    assert!(
        search_time < Duration::from_secs(5),
        "search took {search_time:?}"
    );
    assert!(
        filter_time < Duration::from_secs(5),
        "filter took {filter_time:?}"
    );

    println!(
        "5,000-entry vault: build={build:?} save={save:?} open={open:?} \
         search={search_time:?} filter={filter_time:?}"
    );
}

/// Measures the production Argon2id cost on this machine.
///
/// Ignored by default because the default parameters are deliberately slow.
/// The roadmap's "cold unlock under ~1.5 s on a mid-range phone" budget is a
/// device measurement; this gives a desktop reference point and catches a
/// parameter change that would make unlock far too slow. Run with:
///
/// ```text
/// cargo test --release -p keyel_core --test vault_model -- --ignored --nocapture
/// ```
#[test]
#[ignore = "measures production Argon2id; run manually"]
fn production_kdf_cost_is_measured() {
    use std::time::Duration;

    use keyel_core::crypto::kdf::{benchmark, random_salt};

    let params = Argon2Params::default();
    let elapsed = benchmark(&params, &random_salt()).unwrap();
    println!("Argon2id {params:?} took {elapsed:?}");
    assert!(elapsed < Duration::from_secs(5), "KDF took {elapsed:?}");
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
