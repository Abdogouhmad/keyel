//! Cryptographic primitives used by the vault format.
//!
//! All randomness comes from the operating system CSPRNG. Keys and derived
//! key material are wrapped in [`zeroize::Zeroizing`] so they are wiped when
//! dropped.

use rand::rngs::OsRng;
use rand::TryRngCore;

pub mod aead;
pub mod kdf;
pub mod keys;
pub mod recovery;

/// Fill `buf` from the OS CSPRNG.
///
/// A failure here means the platform RNG is unavailable. There is no safe
/// fallback in a password manager, so this panics rather than silently using
/// a predictable source. This is the only panic in the core on the happy path.
pub(crate) fn fill_random(buf: &mut [u8]) {
    OsRng
        .try_fill_bytes(buf)
        .expect("the operating system RNG must be available");
}

/// Generate a fixed-size random array.
pub(crate) fn random_array<const N: usize>() -> [u8; N] {
    let mut out = [0u8; N];
    fill_random(&mut out);
    out
}
