//! Vault key and key-encryption-key (KEK) wrappers.
//!
//! Both types are intentionally opaque outside this crate. Their `Debug`
//! implementations never print key material.

use std::fmt;

use zeroize::Zeroizing;

use crate::crypto::random_array;
use crate::error::Error;

/// Length of a vault key in bytes.
pub const VAULT_KEY_LEN: usize = 32;

/// Length of a key-encryption key in bytes.
pub const KEK_LEN: usize = 32;

/// The random 256-bit key that encrypts the vault body.
pub struct VaultKey(Zeroizing<[u8; VAULT_KEY_LEN]>);

impl VaultKey {
    /// Generate a fresh random vault key.
    pub fn generate() -> Self {
        Self(Zeroizing::new(random_array()))
    }

    /// Parse a 32-byte vault key, for example after unwrapping a keyslot.
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, Error> {
        if bytes.len() != VAULT_KEY_LEN {
            return Err(Error::Corrupted);
        }
        let mut key = [0u8; VAULT_KEY_LEN];
        key.copy_from_slice(bytes);
        Ok(Self(Zeroizing::new(key)))
    }

    /// Borrow the raw key bytes.
    pub(crate) fn as_bytes(&self) -> &[u8; VAULT_KEY_LEN] {
        &self.0
    }
}

impl fmt::Debug for VaultKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("VaultKey([REDACTED])")
    }
}

/// A 256-bit key-encryption key derived from a password or recovery key.
pub struct Kek(Zeroizing<[u8; KEK_LEN]>);

impl Kek {
    pub(crate) fn from_zeroizing(bytes: Zeroizing<[u8; KEK_LEN]>) -> Self {
        Self(bytes)
    }

    /// Borrow the raw KEK bytes.
    pub(crate) fn as_bytes(&self) -> &[u8; KEK_LEN] {
        &self.0
    }
}

impl fmt::Debug for Kek {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("Kek([REDACTED])")
    }
}
