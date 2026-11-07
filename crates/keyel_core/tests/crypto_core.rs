//! End-to-end tests for the crypto core and the `vault.keyel` format.

use keyel_core::crypto::kdf::Argon2Params;
use keyel_core::format::{
    change_master, create, unlock_with_master, unlock_with_recovery, unlock_with_vault_key,
};
use keyel_core::Error;
use proptest::prelude::*;

/// Small parameters keep the test suite fast. Production uses ~64 MiB.
fn fast_params() -> Argon2Params {
    Argon2Params {
        m_kib: 8,
        t: 1,
        p: 1,
    }
}

fn body(bytes: &[u8]) -> &[u8] {
    let header_len = u32::from_le_bytes([bytes[6], bytes[7], bytes[8], bytes[9]]) as usize;
    &bytes[10 + header_len..]
}

#[test]
fn create_and_unlock_with_master() {
    let plaintext = b"vault payload";
    let created = create("correct horse battery staple", plaintext, fast_params()).unwrap();
    let unlocked = unlock_with_master(&created.bytes, "correct horse battery staple").unwrap();
    assert_eq!(&unlocked.plaintext[..], plaintext);
    assert!(!created.recovery_key.is_empty());
}

#[test]
fn create_and_unlock_with_recovery() {
    let plaintext = b"recover me";
    let created = create("master", plaintext, fast_params()).unwrap();
    let unlocked = unlock_with_recovery(&created.bytes, &created.recovery_key).unwrap();
    assert_eq!(&unlocked.plaintext[..], plaintext);
}

#[test]
fn wrong_credentials_fail() {
    let created = create("master", b"payload", fast_params()).unwrap();
    assert_eq!(
        unlock_with_master(&created.bytes, "wrong").unwrap_err(),
        Error::WrongPassword
    );

    let recovery = created.recovery_key.clone();
    let mut wrong_recovery = recovery.into_bytes();
    wrong_recovery[0] = if wrong_recovery[0] == b'A' {
        b'B'
    } else {
        b'A'
    };
    let wrong_recovery = String::from_utf8(wrong_recovery).unwrap();
    assert_eq!(
        unlock_with_recovery(&created.bytes, &wrong_recovery).unwrap_err(),
        Error::WrongPassword
    );
}

#[test]
fn every_single_byte_flip_is_rejected() {
    let created = create("master", b"payload", fast_params()).unwrap();
    for index in 0..created.bytes.len() {
        let mut tampered = created.bytes.clone();
        tampered[index] ^= 0x01;

        // A keyslot is independently authenticated, so tampering with the
        // recovery slot still allows a master unlock (and vice versa). Require
        // that at least one credential path detects every modification.
        let master_ok = unlock_with_master(&tampered, "master").is_ok();
        let recovery_ok = unlock_with_recovery(&tampered, &created.recovery_key).is_ok();
        assert!(
            !(master_ok && recovery_ok),
            "byte {index} was modified but both unlock paths succeeded"
        );
    }
}

#[test]
fn two_creates_never_match() {
    let a = create("master", b"same payload", fast_params()).unwrap();
    let b = create("master", b"same payload", fast_params()).unwrap();
    assert_ne!(a.bytes, b.bytes);
    assert_ne!(a.recovery_key, b.recovery_key);
}

#[test]
fn change_master_leaves_body_untouched() {
    let created = create("old master", b"payload", fast_params()).unwrap();
    let old_body = body(&created.bytes).to_vec();

    let changed = change_master(&created.bytes, "old master", "new master", fast_params()).unwrap();
    assert_eq!(body(&changed), old_body.as_slice());
    assert_ne!(changed, created.bytes);

    assert_eq!(
        unlock_with_master(&changed, "old master").unwrap_err(),
        Error::WrongPassword
    );
    let unlocked = unlock_with_master(&changed, "new master").unwrap();
    assert_eq!(&unlocked.plaintext[..], b"payload");

    // The recovery slot survives a master-password change.
    unlock_with_recovery(&changed, &created.recovery_key).unwrap();
}

#[test]
fn change_master_rejects_wrong_old_password() {
    let created = create("old master", b"payload", fast_params()).unwrap();
    assert_eq!(
        change_master(&created.bytes, "wrong", "new master", fast_params()).unwrap_err(),
        Error::WrongPassword
    );
}

#[test]
fn unlock_with_vault_key_round_trips() {
    let created = create("master", b"payload", fast_params()).unwrap();
    let unlocked = unlock_with_master(&created.bytes, "master").unwrap();
    let again = unlock_with_vault_key(&created.bytes, &unlocked.vault_key).unwrap();
    assert_eq!(&again.plaintext[..], b"payload");
}

#[test]
fn empty_and_garbage_inputs_are_errors() {
    for data in [&[][..], &[0u8; 1][..], b"KYL1".as_slice(), &[0xAA; 256][..]] {
        assert!(unlock_with_master(data, "master").is_err());
        assert!(unlock_with_recovery(data, "AAAA").is_err());
    }
}

#[test]
fn large_payload_round_trips() {
    let plaintext = vec![0x5Au8; 1024 * 1024];
    let created = create("master", &plaintext, fast_params()).unwrap();
    let unlocked = unlock_with_master(&created.bytes, "master").unwrap();
    assert_eq!(&unlocked.plaintext[..], plaintext.as_slice());
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(32))]

    #[test]
    fn arbitrary_plaintext_round_trips(plaintext in prop::collection::vec(any::<u8>(), 0..2048)) {
        let created = create("master", &plaintext, fast_params()).unwrap();
        let unlocked = unlock_with_master(&created.bytes, "master").unwrap();
        prop_assert_eq!(&unlocked.plaintext[..], plaintext.as_slice());
    }

    #[test]
    fn arbitrary_bytes_do_not_panic(data in prop::collection::vec(any::<u8>(), 0..2048)) {
        let _ = unlock_with_master(&data, "master");
        let _ = unlock_with_recovery(&data, "AAAA");
    }
}
