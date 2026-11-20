//! Opt-in breach-check APIs exposed to Dart.
//!
//! Passwords are hashed in Rust. Dart receives only 5-character prefixes to
//! fetch and sends back raw response bodies; the full digests and the mapping
//! from digest to entry live in a bridge-local pending check that is wiped on
//! completion, cancellation, error, and lock. These APIs never return a
//! plaintext password, full digest, or parsed breach result to Dart; the HTTP
//! body is only an opaque transport value that Rust parses locally.

use std::collections::HashMap;
use std::sync::{Mutex, MutexGuard};

use zeroize::Zeroizing;

use crate::api::error::VaultApiError;
use crate::api::models::{
    BreachCheckRequestDto, BreachMatchDto, BreachRangeResponseDto, BreachReportDto,
};
use crate::api::session::with_session;
use keyel_core::breach as core;
use keyel_core::vault::EntryBody;

struct PendingEntry {
    id: String,
    title: String,
    /// Full SHA-1 hex digest. A secret derived from the password.
    digest: Zeroizing<String>,
}

struct PendingCheck {
    token: String,
    /// The exact prefixes Dart was asked to fetch. A response set that does
    /// not cover all of them is rejected instead of becoming an all-clear.
    prefixes: Vec<String>,
    entries: Vec<PendingEntry>,
}

static PENDING: Mutex<Option<PendingCheck>> = Mutex::new(None);

fn pending_slot() -> MutexGuard<'static, Option<PendingCheck>> {
    PENDING
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

/// Wipe any in-flight check. Called on lock and on every failing exit path.
pub(crate) fn clear_pending() {
    let _ = pending_slot().take();
}

/// Prepare a check from the unlocked vault and return only prefixes to fetch.
///
/// Requires an unlocked session. Calling again while a check is pending fails
/// instead of silently replacing the digests.
pub fn begin_breach_check() -> Result<BreachCheckRequestDto, VaultApiError> {
    // Hold the pending slot while hashing so two concurrent begins cannot both
    // pass the "none pending" check and overwrite each other's digests.
    let mut pending = pending_slot();
    if pending.is_some() {
        return Err(VaultApiError::BreachCheckActive);
    }

    let (entries, prefixes) = with_session(|session| {
        let mut entries = Vec::new();
        let mut prefixes = Vec::<String>::new();

        for entry in &session.vault().entries {
            if entry.deleted_at.is_some() {
                continue;
            }
            let EntryBody::Login(login) = &entry.body else {
                continue;
            };
            if login.password.is_empty() {
                continue;
            }

            let digest = core::sha1_hex(&login.password);
            let prefix = core::prefix_of(&digest).ok_or(VaultApiError::Internal)?;
            if !prefixes.contains(&prefix) {
                prefixes.push(prefix);
            }
            entries.push(PendingEntry {
                id: entry.id.to_string(),
                title: entry.title.clone(),
                digest,
            });
        }
        Ok((entries, prefixes))
    })?;

    let checked_count = entries.len() as u32;
    let token = core::new_token();
    *pending = Some(PendingCheck {
        token: token.clone(),
        prefixes: prefixes.clone(),
        entries,
    });

    Ok(BreachCheckRequestDto {
        token,
        prefixes,
        checked_count,
    })
}

/// Map a complete, unique set of requested prefixes to their response bodies.
fn bodies_for<'a>(
    prefixes: &[String],
    responses: &'a [BreachRangeResponseDto],
) -> Result<HashMap<&'a str, &'a str>, VaultApiError> {
    if responses.len() != prefixes.len() {
        return Err(VaultApiError::BreachInvalidResponse);
    }
    let mut bodies = HashMap::with_capacity(responses.len());
    for response in responses {
        let known = prefixes.iter().any(|prefix| prefix == &response.prefix);
        if !known
            || bodies
                .insert(response.prefix.as_str(), response.body.as_str())
                .is_some()
        {
            return Err(VaultApiError::BreachInvalidResponse);
        }
    }
    Ok(bodies)
}

/// Compare fetched range responses against the pending digests in Rust.
///
/// Takes (and therefore wipes) the pending check on every path. A token that
/// does not match the current check fails with `BreachInvalidToken`.
pub fn finish_breach_check(
    token: String,
    responses: Vec<BreachRangeResponseDto>,
) -> Result<BreachReportDto, VaultApiError> {
    let token = Zeroizing::new(token);
    let pending = pending_slot()
        .take()
        .ok_or(VaultApiError::BreachInvalidToken)?;
    if pending.token.as_str() != token.as_str() {
        return Err(VaultApiError::BreachInvalidToken);
    }

    // Require exactly one response for each requested prefix. A partial set
    // must never be reported as "no exposed passwords found".
    let bodies = bodies_for(&pending.prefixes, &responses)?;

    let mut matches = Vec::new();
    for entry in &pending.entries {
        let Some((prefix, suffix)) = core::split_digest(entry.digest.as_str()) else {
            return Err(VaultApiError::Internal);
        };
        let Some(body) = bodies.get(prefix) else {
            return Err(VaultApiError::Internal);
        };
        if !core::is_well_formed_body(body) {
            return Err(VaultApiError::BreachInvalidResponse);
        }
        match core::count_for_suffix(body, suffix) {
            Ok(Some(count)) => matches.push(BreachMatchDto {
                entry_id: entry.id.clone(),
                entry_title: entry.title.clone(),
                count,
            }),
            Ok(None) => {}
            Err(_) => return Err(VaultApiError::BreachInvalidResponse),
        }
    }

    Ok(BreachReportDto {
        matches,
        checked_count: pending.entries.len() as u32,
        queried_prefixes: pending.prefixes.len() as u32,
    })
}

/// Discard an in-flight check without producing a result.
#[flutter_rust_bridge::frb(sync)]
pub fn cancel_breach_check() {
    clear_pending();
}

#[cfg(test)]
mod tests {
    use super::*;

    fn response(prefix: &str) -> BreachRangeResponseDto {
        BreachRangeResponseDto {
            prefix: prefix.to_string(),
            body: "SUFFIX:1".to_string(),
        }
    }

    #[test]
    fn responses_must_cover_each_requested_prefix_once() {
        let prefixes = vec!["5BAA6".to_string(), "ABCDE".to_string()];
        let full = vec![response("5BAA6"), response("ABCDE")];
        let bodies = bodies_for(&prefixes, &full).expect("complete response set");
        assert_eq!(bodies.len(), 2);

        assert_eq!(
            bodies_for(&prefixes, &full[..1]),
            Err(VaultApiError::BreachInvalidResponse)
        );
        assert_eq!(
            bodies_for(&prefixes, &[response("5BAA6"), response("5BAA6")]),
            Err(VaultApiError::BreachInvalidResponse)
        );
        assert_eq!(
            bodies_for(&prefixes, &[response("5BAA6"), response("FFFFF")]),
            Err(VaultApiError::BreachInvalidResponse)
        );
    }
}
