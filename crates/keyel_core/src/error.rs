//! Error type shared by the pure Rust core.
//!
//! The variants are deliberately coarse. In particular, an unlock failure
//! must not tell an attacker whether the password was wrong, the keyslot was
//! tampered with, or the body failed authentication.

use thiserror::Error;

/// Errors returned by `keyel_core`.
#[derive(Debug, Error, Clone, PartialEq, Eq)]
pub enum Error {
    /// The password/recovery key was wrong, or the encrypted payload was
    /// tampered with. Both cases look identical to the caller on purpose.
    #[error("wrong password or corrupted vault")]
    WrongPassword,

    /// The file structure is invalid (magic, lengths, CBOR, keyslots, ...).
    #[error("corrupted vault")]
    Corrupted,

    /// The file uses a format version this build does not understand.
    #[error("unsupported vault format version {0}")]
    UnsupportedVersion(u16),

    /// Argon2 parameters are outside the accepted bounds.
    #[error("invalid KDF parameters")]
    InvalidKdfParams,

    /// A recovery key is malformed (wrong alphabet, length or checksum).
    #[error("invalid recovery key")]
    InvalidRecoveryKey,

    /// An internal cryptographic operation failed.
    #[error("cryptographic operation failed")]
    Crypto,

    /// The requested entry, folder or session was not found.
    #[error("not found")]
    NotFound,

    /// Reading or writing the vault file failed. The message is for
    /// diagnostics and must never contain secret material.
    #[error("storage error: {0}")]
    Storage(String),
}
