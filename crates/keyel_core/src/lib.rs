//! Keyel core: pure Rust, no flutter_rust_bridge types live in this crate.
//!
//! Everything the app does — crypto, vault format, generator, TOTP,
//! health — is implemented and unit-tested here, independent of any UI.

pub mod autofill;
pub mod backup;
pub mod crypto;
pub mod csv;
pub mod error;
pub mod format;
pub mod generator;
pub mod health;
pub mod import;
pub mod pass_words;
pub mod passkey;
pub mod totp;
pub mod vault;

pub use error::Error;
