//! Opt-in, user-controlled E2EE sync (1.5.0).
//!
//! The transport-independent pieces live here: a versioned/authenticated blob
//! envelope, a one-time pairing code, per-item version vectors, a deterministic
//! merge engine, a folder backend and the high-level session operations.
//! Nothing in this module exposes the sync key to Dart or to a backend.
//!
//! See `docs/sync-1.5.0-design.md` for the full protocol.
//!
//! Security invariants:
//! - `sync_key` is always held in a [`zeroize::Zeroizing`] wrapper in Rust and
//!   is never logged, serialized into a DTO, or written to a backend.
//! - Every blob authenticates its routing metadata (magic, version, sync id,
//!   writer device id, sequence) as associated data.
//! - Parsing fails closed; malformed or tampered bytes never panic and never
//!   partially modify the local vault.

pub mod backend;
pub mod envelope;
pub mod merge;
pub mod pairing;
pub mod payload;
pub mod service;
pub mod version;

pub use backend::{FolderBackend, RemoteFile, SyncBackend};
pub use envelope::{open, seal, SyncBlobHeader, SYNC_FORMAT_VERSION, SYNC_MAGIC};
pub use merge::{merge as merge_vaults, MergeReport};
pub use pairing::PairingCode;
pub use payload::SyncPayload;
pub use service::{disable, enable, join, pairing_code, status, sync_now, SyncReport, SyncStatus};
pub use version::{DeviceId, VectorOrder, VersionVector};
