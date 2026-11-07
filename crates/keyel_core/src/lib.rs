//! Keyel core: pure Rust, no flutter_rust_bridge types live in this crate.
//!
//! Everything the app does — crypto, vault format, generator, TOTP,
//! health — is implemented and unit-tested here, independent of any UI.

pub mod crypto;
pub mod error;
pub mod format;
pub mod generator;
pub mod pass_words;

pub use error::Error;
