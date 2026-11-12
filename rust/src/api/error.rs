//! Errors surfaced to Dart.
//!
//! The variants stay coarse on purpose: an unlock failure must not reveal
//! whether the password was wrong, a keyslot was tampered with, or the body
//! failed authentication.
//!
//! Every variant is a unit variant so FRB maps the enum to a plain Dart enum
//! instead of a `freezed` union. Diagnostic detail is deliberately dropped:
//! the UI only needs an actionable category.

use keyel_core::import::ImportError;
use keyel_core::Error;

/// Errors returned by the vault bridge.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VaultApiError {
    /// No vault path has been configured with [`crate::api::session::init`].
    NotInitialized,
    /// The configured vault path is empty or invalid.
    InvalidPath,
    /// The configured path does not point to an existing vault file.
    VaultMissing,
    /// A vault already exists at the configured path.
    VaultExists,
    /// An operation needs an unlocked session.
    Locked,
    /// The password, recovery key or encrypted payload did not authenticate.
    WrongPassword,
    /// The vault file or payload is structurally invalid.
    Corrupted,
    /// The file uses an unsupported format version.
    UnsupportedVersion,
    /// Argon2 parameters are outside the accepted bounds.
    InvalidKdfParams,
    /// The recovery key is malformed.
    InvalidRecoveryKey,
    /// The requested entry or folder does not exist.
    NotFound,
    /// An id from Dart is not a valid UUID.
    InvalidId,
    /// A requested secret field does not exist on this entry.
    InvalidField,
    /// Reading or writing the vault file failed.
    Storage,
    /// An import file has no data rows.
    EmptyImport,
    /// An import file's header is not a supported export format.
    UnsupportedFormat,
    /// An import file is not valid CSV.
    MalformedImport,
    /// An unexpected internal failure.
    Internal,
}

impl From<Error> for VaultApiError {
    fn from(error: Error) -> Self {
        match error {
            Error::WrongPassword => Self::WrongPassword,
            Error::Corrupted => Self::Corrupted,
            Error::UnsupportedVersion(_) => Self::UnsupportedVersion,
            Error::InvalidKdfParams => Self::InvalidKdfParams,
            Error::InvalidRecoveryKey => Self::InvalidRecoveryKey,
            Error::NotFound => Self::NotFound,
            Error::Storage(_) => Self::Storage,
            Error::Crypto => Self::Internal,
        }
    }
}

impl From<ImportError> for VaultApiError {
    fn from(error: ImportError) -> Self {
        match error {
            ImportError::Empty => Self::EmptyImport,
            ImportError::UnsupportedFormat => Self::UnsupportedFormat,
            ImportError::Malformed => Self::MalformedImport,
        }
    }
}
