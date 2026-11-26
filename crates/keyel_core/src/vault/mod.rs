//! Vault data model, search and safe storage.
//!
//! Everything in this module operates on the decrypted payload. Encryption
//! lives in [`crate::format`]; no secret ever leaves Rust.

pub mod history;
pub mod index;
pub mod migrate;
pub mod model;
pub mod store;

pub use history::{PasswordHistoryEntry, PASSWORD_HISTORY_CAP};
pub use index::{search, EntryFilter};
pub use migrate::migrate;
pub use model::{
    now_unix, Card, CustomField, CustomFieldKind, Entry, EntryBody, EntryKind, EntrySummary,
    Folder, Login, Note, Passkey, SyncConfig, SyncMeta, Tombstone, TombstoneKind, TotpAlgorithm,
    TotpConfig, Vault, TOMBSTONE_RETENTION_SECS, TRASH_RETENTION_SECS, VAULT_SCHEMA_VERSION,
};
pub use store::{has_vault_file, Session};
