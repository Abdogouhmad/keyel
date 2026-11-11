//! TOTP codes and `otpauth://` parsing exposed to Dart.
//!
//! The shared secret never leaves Rust except through
//! [`crate::api::entries::reveal_field`] and [`parse_otpauth`], which only ever
//! echoes back a secret the caller itself supplied (typed or scanned).

use std::time::{SystemTime, UNIX_EPOCH};

use keyel_core::totp as core;
use keyel_core::vault::{EntryBody, TotpConfig};

use super::entries::parse_id;
use super::error::VaultApiError;
use super::models::{TotpAlgorithmDto, TotpCodeDto, TotpConfigDto};
use super::session::with_session;

/// Compute the current one-time code for an entry's stored TOTP secret.
pub fn current_code(id: String) -> Result<TotpCodeDto, VaultApiError> {
    let now = unix_now();
    with_session(|session| {
        let id = parse_id(&id)?;
        let entry = session.vault().entry(id).ok_or(VaultApiError::NotFound)?;
        let config = match &entry.body {
            EntryBody::Login(login) => login.totp.as_ref().ok_or(VaultApiError::InvalidField)?,
            _ => return Err(VaultApiError::InvalidField),
        };

        let code = core::generate_code(config, now).map_err(|_| VaultApiError::InvalidField)?;
        Ok(TotpCodeDto {
            code,
            seconds_left: core::seconds_left(config, now),
            period: config.period,
        })
    })
}

/// Parse an `otpauth://totp/...` URI, or a bare base32 secret.
///
/// A bare secret (manual entry) is accepted and given the RFC defaults
/// (SHA-1 / 6 digits / 30 seconds). The normalised secret is echoed back so
/// the editor can persist it.
pub fn parse_otpauth(uri: String) -> Result<TotpConfigDto, VaultApiError> {
    let trimmed = uri.trim();
    if trimmed.is_empty() {
        return Err(VaultApiError::InvalidField);
    }

    let config = if trimmed.to_ascii_lowercase().starts_with("otpauth://") {
        core::parse_otpauth(trimmed).map_err(|_| VaultApiError::InvalidField)?
    } else {
        let config = TotpConfig::new(core::normalize_secret(trimmed));
        config.validate().map_err(|_| VaultApiError::InvalidField)?;
        config
    };

    Ok(TotpConfigDto {
        secret: config.secret,
        algorithm: TotpAlgorithmDto::from(config.algorithm),
        digits: config.digits,
        period: config.period,
    })
}

/// Seconds since the Unix epoch, or `0` if the clock is before 1970.
fn unix_now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or(0)
}
