//! Recovery-key generation, encoding and KEK derivation.
//!
//! A recovery key is 256 bits of random data. Because it is already high
//! entropy it does not need a password KDF: HKDF-SHA256 with a random salt
//! and a domain-separation label is enough to turn it into a KEK.

use std::fmt;

use data_encoding::BASE32_NOPAD;
use hkdf::Hkdf;
use sha2::Sha256;
use zeroize::Zeroizing;

use crate::crypto::kdf::SALT_LEN;
use crate::crypto::keys::{Kek, KEK_LEN};
use crate::crypto::random_array;
use crate::error::Error;

/// Recovery-key length in bits.
pub const RECOVERY_KEY_BITS: usize = 256;

/// Recovery-key length in bytes.
pub const RECOVERY_KEY_LEN: usize = RECOVERY_KEY_BITS / 8;

/// Number of characters per display group.
pub const RECOVERY_GROUP_LEN: usize = 4;

/// Domain-separation label for the recovery KEK.
const HKDF_INFO: &[u8] = b"keyel/recovery-kek/v1";

/// A random 256-bit recovery key.
pub struct RecoveryKey(Zeroizing<[u8; RECOVERY_KEY_LEN]>);

impl RecoveryKey {
    /// Generate a fresh recovery key.
    pub fn generate() -> Self {
        Self(Zeroizing::new(random_array()))
    }

    /// Parse a user-entered recovery key.
    ///
    /// Case, spaces, hyphens and `=` padding are ignored. `0`/`O` and `1`/`I`
    /// are treated as the same character to tolerate handwriting and fonts.
    pub fn parse(input: &str) -> Result<Self, Error> {
        let mut cleaned = String::with_capacity(input.len());
        for ch in input.chars() {
            if ch.is_ascii_alphanumeric() {
                cleaned.push(match ch.to_ascii_uppercase() {
                    '0' => 'O',
                    '1' => 'I',
                    other => other,
                });
            }
        }
        let decoded = BASE32_NOPAD
            .decode(cleaned.as_bytes())
            .map_err(|_| Error::InvalidRecoveryKey)?;
        if decoded.len() != RECOVERY_KEY_LEN {
            return Err(Error::InvalidRecoveryKey);
        }
        let mut key = [0u8; RECOVERY_KEY_LEN];
        key.copy_from_slice(&decoded);
        Ok(Self(Zeroizing::new(key)))
    }

    /// Encode for display, grouped with hyphens.
    pub fn encode(&self) -> String {
        let encoded = BASE32_NOPAD.encode(&self.0[..]);
        encoded
            .as_bytes()
            .chunks(RECOVERY_GROUP_LEN)
            .map(|group| std::str::from_utf8(group).expect("base32 is ASCII"))
            .collect::<Vec<_>>()
            .join("-")
    }

    /// Borrow the raw key bytes.
    pub(crate) fn as_bytes(&self) -> &[u8; RECOVERY_KEY_LEN] {
        &self.0
    }
}

impl fmt::Display for RecoveryKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.encode())
    }
}

impl fmt::Debug for RecoveryKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("RecoveryKey([REDACTED])")
    }
}

/// Derive the recovery-slot KEK with HKDF-SHA256.
pub fn derive_recovery_kek(key: &RecoveryKey, salt: &[u8; SALT_LEN]) -> Kek {
    let hkdf = Hkdf::<Sha256>::new(Some(salt), key.as_bytes());
    let mut out = Zeroizing::new([0u8; KEK_LEN]);
    hkdf.expand(HKDF_INFO, &mut out[..])
        .expect("32 bytes is a valid HKDF output length");
    Kek::from_zeroizing(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip() {
        let key = RecoveryKey::generate();
        let encoded = key.encode();
        let parsed = RecoveryKey::parse(&encoded).unwrap();
        assert_eq!(key.as_bytes(), parsed.as_bytes());
    }

    #[test]
    fn parser_normalizes_input() {
        let key = RecoveryKey::generate();
        let encoded = key.encode();
        let messy = format!("  {}  ", encoded.to_ascii_lowercase().replace('-', " "));
        let parsed = RecoveryKey::parse(&messy).unwrap();
        assert_eq!(key.as_bytes(), parsed.as_bytes());
    }

    #[test]
    fn wrong_length_is_rejected() {
        assert_eq!(
            RecoveryKey::parse("AAAA-BBBB").unwrap_err(),
            Error::InvalidRecoveryKey
        );
    }

    #[test]
    fn invalid_alphabet_is_rejected() {
        // Filtering removes punctuation, so use an alphabet character that
        // base32 does not contain (8 is outside A-Z2-7).
        let mut encoded = RecoveryKey::generate().encode();
        encoded.replace_range(0..1, "8");
        assert_eq!(
            RecoveryKey::parse(&encoded).unwrap_err(),
            Error::InvalidRecoveryKey
        );
    }

    #[test]
    fn kek_depends_on_salt() {
        let key = RecoveryKey::generate();
        let a = derive_recovery_kek(&key, &[1u8; SALT_LEN]);
        let b = derive_recovery_kek(&key, &[2u8; SALT_LEN]);
        assert_ne!(a.as_bytes(), b.as_bytes());
    }
}
