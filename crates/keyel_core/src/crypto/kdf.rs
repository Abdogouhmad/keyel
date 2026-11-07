//! Argon2id password-based key derivation.
//!
//! The vault key is wrapped by a KEK derived from the master password. Argon2
//! parameters live in the file header so the app can tune them per device
//! without invalidating existing vaults.

use std::time::{Duration, Instant};

use argon2::{Algorithm, Argon2, Params, Version};
use zeroize::Zeroizing;

use crate::crypto::keys::{Kek, KEK_LEN};
use crate::crypto::random_array;
use crate::error::Error;

/// Argon2 salt length in bytes.
pub const SALT_LEN: usize = 16;

/// Smallest memory cost accepted by the format, in KiB.
pub const MIN_M_KIB: u32 = 8;

/// Largest memory cost accepted from an untrusted header, in KiB.
///
/// This bounds the work an attacker can force by tampering with the header.
pub const MAX_M_KIB: u32 = 256 * 1024;

/// Largest time cost accepted from an untrusted header.
pub const MAX_T: u32 = 16;

/// Largest parallelism accepted from an untrusted header.
pub const MAX_P: u32 = 16;

/// Argon2id cost parameters.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Argon2Params {
    /// Memory cost in KiB.
    pub m_kib: u32,
    /// Time cost (iterations).
    pub t: u32,
    /// Parallelism.
    pub p: u32,
}

impl Default for Argon2Params {
    /// The starting point from the project plan: 64 MiB, 3 passes, 1 lane.
    /// Phase 0.6 will benchmark and store device-tuned values instead.
    fn default() -> Self {
        Self {
            m_kib: 64 * 1024,
            t: 3,
            p: 1,
        }
    }
}

impl Argon2Params {
    /// Validate the bounds accepted by this format version.
    pub fn validate(self) -> Result<Self, Error> {
        if self.m_kib < MIN_M_KIB
            || self.m_kib > MAX_M_KIB
            || self.t == 0
            || self.t > MAX_T
            || self.p == 0
            || self.p > MAX_P
        {
            return Err(Error::InvalidKdfParams);
        }
        // Argon2 requires m_cost >= 8 * p_cost.
        Params::new(self.m_kib, self.t, self.p, Some(KEK_LEN))
            .map_err(|_| Error::InvalidKdfParams)?;
        Ok(self)
    }
}

/// Derive a 256-bit KEK from a master password and salt.
pub fn derive_kek(
    master: &str,
    salt: &[u8; SALT_LEN],
    params: &Argon2Params,
) -> Result<Kek, Error> {
    params.validate()?;
    let params = Params::new(params.m_kib, params.t, params.p, Some(KEK_LEN))
        .map_err(|_| Error::InvalidKdfParams)?;
    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);
    let mut out = Zeroizing::new([0u8; KEK_LEN]);
    argon2
        .hash_password_into(master.as_bytes(), salt, &mut out[..])
        .map_err(|_| Error::Crypto)?;
    Ok(Kek::from_zeroizing(out))
}

/// Generate a fresh random Argon2 salt.
pub fn random_salt() -> [u8; SALT_LEN] {
    random_array()
}

/// Measure one derivation with the given parameters.
pub fn benchmark(params: &Argon2Params, salt: &[u8; SALT_LEN]) -> Result<Duration, Error> {
    let start = Instant::now();
    let _ = derive_kek("keyel calibration password", salt, params)?;
    Ok(start.elapsed())
}

/// Choose the strongest memory cost that stays at or below `target`.
///
/// The search starts at [`MIN_M_KIB`] and doubles the memory cost while it
/// still fits. `max_m_kib` is clamped to the format bounds. Callers should
/// invoke this once during setup on the real device and store the result in
/// the header (phase 0.6), not on every unlock.
pub fn calibrate(target: Duration, max_m_kib: u32) -> Argon2Params {
    let max_m_kib = max_m_kib.clamp(MIN_M_KIB, MAX_M_KIB);
    let salt = [0u8; SALT_LEN];
    let mut best = Argon2Params {
        m_kib: MIN_M_KIB,
        ..Argon2Params::default()
    };
    let mut m_kib = MIN_M_KIB;

    loop {
        let candidate = Argon2Params {
            m_kib,
            ..Argon2Params::default()
        };
        match benchmark(&candidate, &salt) {
            Ok(elapsed) => {
                best = candidate;
                if elapsed >= target {
                    break;
                }
            }
            Err(_) => break,
        }
        let Some(next) = m_kib.checked_mul(2) else {
            break;
        };
        if next > max_m_kib {
            break;
        }
        m_kib = next;
    }

    best
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fast_params() -> Argon2Params {
        Argon2Params {
            m_kib: 8,
            t: 1,
            p: 1,
        }
    }

    #[test]
    fn derivation_is_deterministic() {
        let salt = [1u8; SALT_LEN];
        let a = derive_kek("correct horse", &salt, &fast_params()).unwrap();
        let b = derive_kek("correct horse", &salt, &fast_params()).unwrap();
        assert_eq!(a.as_bytes(), b.as_bytes());
    }

    #[test]
    fn salt_and_password_change_the_key() {
        let salt = [1u8; SALT_LEN];
        let other_salt = [2u8; SALT_LEN];
        let a = derive_kek("one", &salt, &fast_params()).unwrap();
        let b = derive_kek("two", &salt, &fast_params()).unwrap();
        let c = derive_kek("one", &other_salt, &fast_params()).unwrap();
        assert_ne!(a.as_bytes(), b.as_bytes());
        assert_ne!(a.as_bytes(), c.as_bytes());
    }

    #[test]
    fn invalid_parameters_are_rejected() {
        for params in [
            Argon2Params {
                m_kib: 0,
                t: 1,
                p: 1,
            },
            Argon2Params {
                m_kib: 8,
                t: 0,
                p: 1,
            },
            Argon2Params {
                m_kib: 8,
                t: 1,
                p: 0,
            },
            Argon2Params {
                m_kib: MAX_M_KIB + 1,
                t: 1,
                p: 1,
            },
            Argon2Params {
                m_kib: 8,
                t: 17,
                p: 1,
            },
            Argon2Params {
                m_kib: 8,
                t: 1,
                p: 17,
            },
        ] {
            assert_eq!(params.validate().unwrap_err(), Error::InvalidKdfParams);
        }
    }

    #[test]
    fn calibrate_stays_within_bounds() {
        let params = calibrate(Duration::from_millis(1), 1024);
        assert!(params.m_kib >= MIN_M_KIB);
        assert!(params.m_kib <= 1024);
        params.validate().unwrap();
    }
}
