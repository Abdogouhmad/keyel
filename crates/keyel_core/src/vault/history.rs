//! Password history.
//!
//! History is capped so a vault cannot grow without bound and so an old
//! password does not linger forever. Newest entries come first.

use serde::{Deserialize, Serialize};

use super::model::Login;

/// Maximum number of previous passwords kept per login.
pub const PASSWORD_HISTORY_CAP: usize = 10;

/// One previous password and when it was replaced.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PasswordHistoryEntry {
    /// The password that was in use before the change.
    pub password: String,
    /// Unix timestamp of the change.
    pub changed_at: u64,
}

/// Push `old_password` onto the login's history, newest first.
///
/// Callers are responsible for only invoking this when the password actually
/// changed. Older entries beyond the cap are dropped.
pub fn record_password_change(login: &mut Login, old_password: String, at: u64) {
    login.password_history.insert(
        0,
        PasswordHistoryEntry {
            password: old_password,
            changed_at: at,
        },
    );
    login.password_history.truncate(PASSWORD_HISTORY_CAP);
}
