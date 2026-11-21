//! Autofill target matching exposed to Dart.
//!
//! The picker runs in a separate Flutter entrypoint launched by the Android
//! autofill service. It asks Rust which logins match the requesting package or
//! web domain; the response carries only secret-free summaries. The chosen
//! entry's password is fetched separately through `reveal_field`.

use keyel_core::autofill::{find_matches, MatchTarget};

use super::error::VaultApiError;
use super::models::AutofillMatchDto;
use super::session::with_session;

/// Find logins that can fill the requesting app or site, best matches first.
///
/// Pass the Android `package` name and/or the `web_domain` reported by the
/// autofill framework. `query` filters by text (title, username, URL) and is
/// also what the picker's "Search vault" box sends. An empty target with an
/// empty query returns nothing.
pub fn find_autofill_matches(
    package: Option<String>,
    web_domain: Option<String>,
    query: String,
    require_verified: bool,
) -> Result<Vec<AutofillMatchDto>, VaultApiError> {
    with_session(|session| {
        let target = MatchTarget {
            package,
            web_domain,
            require_verified,
        };
        Ok(find_matches(session.vault(), &target, &query)
            .into_iter()
            .map(AutofillMatchDto::from)
            .collect())
    })
}
