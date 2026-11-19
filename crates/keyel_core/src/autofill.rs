//! Autofill target matching.
//!
//! Given the Android package name and/or web domain of the app asking to fill
//! a form, decide which vault logins are plausible matches and how strong each
//! match is. This is security-critical: a loose match would let a phishing app
//! or look-alike domain harvest a credential, so the rules here are
//! deliberately conservative.
//!
//! Matching is:
//! - **Apps:** exact Android package name. A login opts in by storing the
//!   package as an `androidapp://<package>` URL (the Bitwarden convention) or
//!   by storing the bare package name as its URL.
//! - **Web:** same host, or a subdomain of the other host. A subdomain shares
//!   its registrable domain with its parent, so `login.example.com` matches
//!   `example.com` but `evil-example.com` does not.
//!
//! There is no public-suffix list yet, so we never collapse to an eTLD+1
//! guess; matching across hosts only happens on a label boundary, which can
//! never bridge two different registrable domains. Anything weaker than a
//! host/subdomain or package match is only surfaced through an explicit search
//! and reported as [`MatchQuality::Search`] so the UI can warn.

use crate::vault::index::normalize;
use crate::vault::{EntryBody, EntrySummary, Vault};

/// What is asking to be filled.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MatchTarget {
    /// Android package name of the requesting app, if any.
    pub package: Option<String>,
    /// Web domain reported by the autofill framework, if any.
    pub web_domain: Option<String>,
}

impl MatchTarget {
    /// Whether the target carries any hint at all.
    pub fn is_empty(&self) -> bool {
        self.package
            .as_deref()
            .is_none_or(|value| value.trim().is_empty())
            && self
                .web_domain
                .as_deref()
                .is_none_or(|value| value.trim().is_empty())
    }
}

/// How confidently a login matches the fill target.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MatchQuality {
    /// Same host or same Android package.
    Exact,
    /// Same registrable domain (a subdomain relationship).
    SameSite,
    /// Only a text-search hit; the UI must show a mismatch warning.
    Search,
}

/// A login that could fill the request.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AutofillMatch {
    /// Secret-free summary, ready for a list row.
    pub summary: EntrySummary,
    /// Match strength.
    pub quality: MatchQuality,
}

/// Find logins that can fill `target`, best matches first.
///
/// When `target` is empty, only `query` is used, so the same function powers
/// the picker's "Search vault" box. When `query` is empty, only entries that
/// match the target are returned. Exact matches come first, then same-site
/// matches, then text-search hits.
pub fn find_matches(vault: &Vault, target: &MatchTarget, query: &str) -> Vec<AutofillMatch> {
    let package = target
        .package
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty());
    let domain = target
        .web_domain
        .as_deref()
        .and_then(host_of)
        .map(|host| strip_www(&host));
    let query = normalize(query.trim());

    let mut exact = Vec::new();
    let mut same_site = Vec::new();
    let mut search = Vec::new();

    for entry in &vault.entries {
        if entry.deleted_at.is_some() {
            continue;
        }
        let EntryBody::Login(login) = &entry.body else {
            continue;
        };

        let target_quality = match_quality(&login.url, package, domain.as_deref());
        if let Some(quality) = target_quality {
            push(&mut exact, &mut same_site, &mut search, entry, quality);
            continue;
        }

        if !query.is_empty() && entry_matches_query(entry, &query) {
            push(
                &mut exact,
                &mut same_site,
                &mut search,
                entry,
                MatchQuality::Search,
            );
        }
    }

    exact.extend(same_site);
    exact.extend(search);
    exact
}

fn push(
    exact: &mut Vec<AutofillMatch>,
    same_site: &mut Vec<AutofillMatch>,
    search: &mut Vec<AutofillMatch>,
    entry: &crate::vault::Entry,
    quality: MatchQuality,
) {
    let item = AutofillMatch {
        summary: entry.summary(),
        quality,
    };
    match quality {
        MatchQuality::Exact => exact.push(item),
        MatchQuality::SameSite => same_site.push(item),
        MatchQuality::Search => search.push(item),
    }
}

/// Classify a login URL against the app package and web domain targets.
fn match_quality(url: &str, package: Option<&str>, domain: Option<&str>) -> Option<MatchQuality> {
    if let (Some(package), Some(stored)) = (package, package_of(url)) {
        if stored == package {
            return Some(MatchQuality::Exact);
        }
    }

    let domain = domain?;
    let host = strip_www(&host_of(url)?);
    if host == domain {
        return Some(MatchQuality::Exact);
    }
    if is_subdomain(&host, domain) || is_subdomain(domain, &host) {
        return Some(MatchQuality::SameSite);
    }
    None
}

/// The Android package stored in an `androidapp://` URL, if present.
fn package_of(url: &str) -> Option<String> {
    let trimmed = url.trim();
    let rest = trimmed.strip_prefix("androidapp://")?;
    let package = rest.split(['/', '?', '#']).next().unwrap_or("").trim();
    if package.is_empty() {
        None
    } else {
        Some(package.to_ascii_lowercase())
    }
}

/// Whether `haystack` is a strict subdomain of `parent`.
///
/// The comparison is done on a label boundary, so `login.example.com` is a
/// subdomain of `example.com` while `notexample.com` is not.
fn is_subdomain(haystack: &str, parent: &str) -> bool {
    haystack.len() > parent.len()
        && haystack.ends_with(parent)
        && haystack.as_bytes()[haystack.len() - parent.len() - 1] == b'.'
}

/// Extract the lowercased host from a free-form URL, or `None`.
fn host_of(url: &str) -> Option<String> {
    let trimmed = url.trim();
    if trimmed.is_empty() {
        return None;
    }
    let after_scheme = match trimmed.find("://") {
        Some(index) => &trimmed[index + 3..],
        None => trimmed,
    };
    let authority = after_scheme.split(['/', '?', '#']).next().unwrap_or("");
    // Userinfo is everything up to the last `@`.
    let host_port = authority.rsplit('@').next().unwrap_or(authority);
    if host_port.is_empty() {
        return None;
    }
    if let Some(rest) = host_port.strip_prefix('[') {
        // IPv6 literal: keep the bracketed address, drop any port.
        let end = rest.find(']')?;
        return Some(format!("[{}]", &rest[..end]).to_ascii_lowercase());
    }
    let host = host_port
        .split(':')
        .next()
        .unwrap_or("")
        .trim_end_matches('.');
    if host.is_empty() {
        None
    } else {
        Some(host.to_ascii_lowercase())
    }
}

/// Drop a leading `www.` so `www.example.com` and `example.com` are equal.
fn strip_www(host: &str) -> String {
    host.strip_prefix("www.").unwrap_or(host).to_string()
}

/// Whether an entry matches an already-normalized text query.
fn entry_matches_query(entry: &crate::vault::Entry, query: &str) -> bool {
    let contains = |value: &str| normalize(value).contains(query);
    contains(&entry.title)
        || entry.tags.iter().any(|tag| contains(tag))
        || match &entry.body {
            EntryBody::Login(login) => contains(&login.username) || contains(&login.url),
            EntryBody::Card(_) | EntryBody::Note(_) | EntryBody::Passkey(_) => false,
        }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::{Entry, Login, Vault};

    fn login(title: &str, username: &str, url: &str) -> Entry {
        Entry::login(
            title,
            Login {
                username: username.to_string(),
                password: "correct horse battery staple".to_string(),
                url: url.to_string(),
                ..Login::default()
            },
        )
    }

    fn vault_with(entries: Vec<Entry>) -> Vault {
        let mut vault = Vault::new();
        for entry in entries {
            vault.add_entry(entry);
        }
        vault
    }

    #[test]
    fn host_extraction_handles_real_urls() {
        assert_eq!(
            host_of("https://example.com/login"),
            Some("example.com".into())
        );
        assert_eq!(host_of("example.com"), Some("example.com".into()));
        assert_eq!(
            host_of("http://user:pw@Example.COM:8443/x"),
            Some("example.com".into())
        );
        assert_eq!(host_of("https://example.com./"), Some("example.com".into()));
        assert_eq!(
            host_of("androidapp://com.example.app"),
            Some("com.example.app".into())
        );
        assert_eq!(
            host_of("https://[2001:db8::1]:443/"),
            Some("[2001:db8::1]".into())
        );
        assert_eq!(host_of("   "), None);
        assert_eq!(host_of(""), None);
    }

    #[test]
    fn exact_host_match_ignores_www_and_case() {
        let vault = vault_with(vec![login("Mail", "ada", "https://www.Example.com/login")]);
        let target = MatchTarget {
            package: None,
            web_domain: Some("example.com".into()),
        };
        let matches = find_matches(&vault, &target, "");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].quality, MatchQuality::Exact);
        assert_eq!(matches[0].summary.title, "Mail");
    }

    #[test]
    fn subdomains_share_a_site_but_not_a_host() {
        let vault = vault_with(vec![login("Mail", "ada", "https://login.example.com")]);
        let target = MatchTarget {
            package: None,
            web_domain: Some("example.com".into()),
        };
        let matches = find_matches(&vault, &target, "");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].quality, MatchQuality::SameSite);
    }

    #[test]
    fn lookalike_domains_do_not_match() {
        let vault = vault_with(vec![
            login("PayPal", "ada", "https://paypal.com"),
            login("Evil", "ada", "https://evil-paypal.com"),
            login("Other", "ada", "https://paypal.com.evil.net"),
        ]);
        let target = MatchTarget {
            package: None,
            web_domain: Some("paypal.com".into()),
        };
        let matches = find_matches(&vault, &target, "");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].summary.title, "PayPal");
    }

    #[test]
    fn different_registrable_domains_are_never_same_site() {
        let vault = vault_with(vec![login("Bank", "ada", "https://example.co.uk")]);
        let target = MatchTarget {
            package: None,
            web_domain: Some("evil.co.uk".into()),
        };
        assert!(find_matches(&vault, &target, "").is_empty());
    }

    #[test]
    fn app_package_matches_androidapp_url() {
        let vault = vault_with(vec![
            login("App", "ada", "androidapp://com.example.app"),
            login("Other", "ada", "androidapp://com.other.app"),
        ]);
        let target = MatchTarget {
            package: Some("com.example.app".into()),
            web_domain: None,
        };
        let matches = find_matches(&vault, &target, "");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].quality, MatchQuality::Exact);
        assert_eq!(matches[0].summary.title, "App");
    }

    #[test]
    fn app_package_never_matches_a_web_host() {
        let vault = vault_with(vec![login("Site", "ada", "https://com.example.app")]);
        let target = MatchTarget {
            package: Some("com.example.app".into()),
            web_domain: None,
        };
        assert!(find_matches(&vault, &target, "").is_empty());
    }

    #[test]
    fn query_surfaces_search_hits_after_matches() {
        let vault = vault_with(vec![
            login("Target", "ada", "https://example.com"),
            login("Unrelated", "bob", "https://unrelated.test"),
        ]);
        let target = MatchTarget {
            package: None,
            web_domain: Some("example.com".into()),
        };
        let matches = find_matches(&vault, &target, "unrelated");
        assert_eq!(matches.len(), 2);
        assert_eq!(matches[0].summary.title, "Target");
        assert_eq!(matches[0].quality, MatchQuality::Exact);
        assert_eq!(matches[1].summary.title, "Unrelated");
        assert_eq!(matches[1].quality, MatchQuality::Search);
    }

    #[test]
    fn empty_target_returns_only_query_hits() {
        let vault = vault_with(vec![
            login("Mail", "ada", "https://example.com"),
            login("Bank", "bob", "https://bank.test"),
        ]);
        assert!(find_matches(&vault, &MatchTarget::default(), "").is_empty());
        let matches = find_matches(&vault, &MatchTarget::default(), "bank");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].summary.title, "Bank");
        assert_eq!(matches[0].quality, MatchQuality::Search);
    }

    #[test]
    fn trashed_and_non_login_entries_are_ignored() {
        let mut trashed = login("Gone", "ada", "https://example.com");
        trashed.deleted_at = Some(1);
        let vault = vault_with(vec![
            trashed,
            Entry::note("Note", crate::vault::Note::default()),
        ]);
        let target = MatchTarget {
            package: None,
            web_domain: Some("example.com".into()),
        };
        assert!(find_matches(&vault, &target, "note").is_empty());
    }

    #[test]
    fn no_target_and_no_query_returns_nothing() {
        let vault = vault_with(vec![login("Mail", "ada", "https://example.com")]);
        assert!(find_matches(&vault, &MatchTarget::default(), "").is_empty());
    }

    #[test]
    fn finds_passkeys_by_rp_id() {
        use crate::vault::Passkey;
        let mut vault = Vault::new();
        let a = vault.add_entry(Entry::passkey(
            "Example A",
            Passkey {
                rp_id: "example.com".into(),
                user_name: "ada".into(),
                ..Passkey::default()
            },
        ));
        let _b = vault.add_entry(Entry::passkey(
            "Other",
            Passkey {
                rp_id: "other.test".into(),
                user_name: "bob".into(),
                ..Passkey::default()
            },
        ));
        let mut trashed = Entry::passkey(
            "Trashed",
            Passkey {
                rp_id: "example.com".into(),
                user_name: "old".into(),
                ..Passkey::default()
            },
        );
        trashed.deleted_at = Some(1);
        vault.add_entry(trashed);

        let matches = find_passkeys_for_rp(&vault, "EXAMPLE.com");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].id, a);
        assert_eq!(matches[0].kind, crate::vault::EntryKind::Passkey);
        assert!(find_passkeys_for_rp(&vault, "").is_empty());
        assert!(find_passkeys_for_rp(&vault, "missing.test").is_empty());
    }

    #[test]
    fn records_passkey_use_updates_counter_and_time() {
        use crate::vault::Passkey;
        let mut vault = Vault::new();
        let id = vault.add_entry(Entry::passkey(
            "Example",
            Passkey {
                rp_id: "example.com".into(),
                user_name: "ada".into(),
                sign_count: 1,
                ..Passkey::default()
            },
        ));
        assert!(record_passkey_use(&mut vault, id, 2, 1_700_000_200));
        let entry = vault.entry(id).unwrap();
        assert_eq!(entry.updated_at, 1_700_000_200);
        let EntryBody::Passkey(pk) = &entry.body else {
            panic!("passkey");
        };
        assert_eq!(pk.sign_count, 2);
        assert_eq!(pk.last_used_at, Some(1_700_000_200));

        assert!(!record_passkey_use(&mut vault, uuid::Uuid::now_v7(), 3, 4));
        let login_id = vault.add_entry(login("Mail", "ada", "https://example.com"));
        assert!(!record_passkey_use(&mut vault, login_id, 3, 4));
    }
}

/// Return non-secret summaries of passkey entries matching a relying party ID.
///
/// Matching is exact on the RP ID (case-insensitive host normalization) so the
/// caller can present candidates for a WebAuthn get/create ceremony. No secret
/// key material is included in the returned summaries.
pub fn find_passkeys_for_rp(vault: &Vault, rp_id: &str) -> Vec<EntrySummary> {
    let rp_id = rp_id.trim().to_ascii_lowercase();
    if rp_id.is_empty() {
        return Vec::new();
    }
    vault
        .entries
        .iter()
        .filter(|entry| entry.deleted_at.is_none())
        .filter_map(|entry| match &entry.body {
            EntryBody::Passkey(passkey) if passkey.rp_id.trim().to_ascii_lowercase() == rp_id => {
                Some(entry.summary())
            }
            _ => None,
        })
        .collect()
}

/// Record that a passkey was used for an assertion: update sign count and last-used time.
///
/// `sign_count` should be the new counter value reported/maintained by the caller.
/// Returns `true` if the entry was found and updated.
pub fn record_passkey_use(vault: &mut Vault, id: uuid::Uuid, sign_count: u32, at: u64) -> bool {
    let Some(entry) = vault.entry_mut(id) else {
        return false;
    };
    let EntryBody::Passkey(passkey) = &mut entry.body else {
        return false;
    };
    passkey.sign_count = sign_count;
    passkey.last_used_at = Some(at);
    entry.updated_at = at;
    true
}
