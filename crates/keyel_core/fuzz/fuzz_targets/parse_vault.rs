#![no_main]

use keyel_core::crypto::keys::VaultKey;
use keyel_core::format::unlock_with_vault_key;
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    // Parsing and AEAD opening must never panic on attacker-controlled bytes.
    // A fixed key avoids running Argon2 for every fuzz case (the password KDF
    // is covered by deterministic unit tests, not by the parser fuzzer).
    let key = VaultKey::from_bytes(&[0u8; 32]).expect("32-byte key");
    let _ = unlock_with_vault_key(data, &key);
});
