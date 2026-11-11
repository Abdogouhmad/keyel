//! Vault health analysis exposed to Dart.
//!
//! The report contains only entry ids and non-secret metadata. Passwords are
//! analysed entirely inside `keyel_core` and never cross the bridge.

use std::time::{SystemTime, UNIX_EPOCH};

use keyel_core::health as core;

use super::error::VaultApiError;
use super::models::HealthReportDto;
use super::session::with_session;

/// Analyze the unlocked vault and return a secret-free health report.
pub fn analyze_health() -> Result<HealthReportDto, VaultApiError> {
    let now = unix_now();
    with_session(|session| Ok(HealthReportDto::from(core::analyze(session.vault(), now))))
}

/// Seconds since the Unix epoch, or `0` if the clock is before 1970.
fn unix_now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or(0)
}
