//! Vault health analysis.
//!
//! Pure and deterministic: the caller supplies the current Unix time, so the
//! same code is unit-tested here and reused by the bridge without a clock
//! dependency.
//!
//! The report contains only entry ids and non-secret metadata — never a
//! password. Reuse is detected by hashing each password with a random salt
//! that lives for the duration of one [`analyze`] call, so the comparison map
//! is keyed by salted digests rather than by plaintext.

use std::collections::HashMap;

use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::vault::{EntryBody, Vault};

/// A password older than this is flagged as stale (365 days).
pub const OLD_PASSWORD_SECS: u64 = 365 * 24 * 60 * 60;

/// Estimated-entropy threshold below which a password counts as weak.
pub const WEAK_PASSWORD_BITS: f64 = 50.0;

/// Per-entry severity weights used to turn issues into a 0..=100 score.
const WEIGHT_WEAK: f64 = 1.0;
const WEIGHT_REUSED: f64 = 0.5;
const WEIGHT_INSECURE_URL: f64 = 0.4;
const WEIGHT_OLD: f64 = 0.2;
const WEIGHT_NO_TWO_FACTOR: f64 = 0.2;

/// A secret-free reference to an affected entry.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HealthIssue {
    /// Stable entry id.
    pub id: Uuid,
    /// Entry title.
    pub title: String,
    /// Secondary line (username or URL). Never a password.
    pub subtitle: String,
}

/// A set of entries that share the same password.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReuseGroup {
    /// The entries that share the password, in vault order.
    pub entries: Vec<HealthIssue>,
}

/// The result of analyzing a vault.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HealthReport {
    /// Overall health score, `0..=100`.
    pub score: u8,
    /// Number of non-deleted login entries with a password.
    pub total_logins: u32,
    /// Entries whose password is weak.
    pub weak: Vec<HealthIssue>,
    /// Groups of entries that share a password.
    pub reused: Vec<ReuseGroup>,
    /// Entries whose password has not changed in over a year.
    pub old: Vec<HealthIssue>,
    /// Entries without two-factor authentication.
    pub no_two_factor: Vec<HealthIssue>,
    /// Entries whose website uses plain HTTP.
    pub insecure_url: Vec<HealthIssue>,
}

impl Default for HealthReport {
    fn default() -> Self {
        Self {
            score: 100,
            total_logins: 0,
            weak: Vec::new(),
            reused: Vec::new(),
            old: Vec::new(),
            no_two_factor: Vec::new(),
            insecure_url: Vec::new(),
        }
    }
}

/// Analyze a vault and return a secret-free health report.
///
/// Only non-deleted login entries with a non-empty password are considered;
/// cards, notes and trashed entries are ignored.
pub fn analyze(vault: &Vault, now: u64) -> HealthReport {
    // The salt never leaves this call; it keeps the reuse map keyed by
    // digests instead of plaintext.
    let salt: [u8; 16] = rand::random();

    let mut weak = Vec::new();
    let mut old = Vec::new();
    let mut no_two_factor = Vec::new();
    let mut insecure_url = Vec::new();
    let mut groups: HashMap<[u8; 32], Vec<HealthIssue>> = HashMap::new();
    let mut severity: HashMap<Uuid, f64> = HashMap::new();
    let mut total_logins = 0u32;

    for entry in &vault.entries {
        if entry.deleted_at.is_some() {
            continue;
        }
        let EntryBody::Login(login) = &entry.body else {
            continue;
        };
        if login.password.is_empty() {
            continue;
        }
        total_logins += 1;

        let issue = HealthIssue {
            id: entry.id,
            title: entry.title.clone(),
            subtitle: entry.summary().subtitle,
        };

        let mut weight = 0.0;
        if estimate_bits(&login.password) < WEAK_PASSWORD_BITS {
            weak.push(issue.clone());
            weight += WEIGHT_WEAK;
        }
        if now.saturating_sub(entry.updated_at) > OLD_PASSWORD_SECS {
            old.push(issue.clone());
            weight += WEIGHT_OLD;
        }
        if login.totp.is_none() {
            no_two_factor.push(issue.clone());
            weight += WEIGHT_NO_TWO_FACTOR;
        }
        if login.url.trim().to_ascii_lowercase().starts_with("http://") {
            insecure_url.push(issue.clone());
            weight += WEIGHT_INSECURE_URL;
        }

        groups
            .entry(hash_password(&salt, &login.password))
            .or_default()
            .push(issue);
        severity.insert(entry.id, weight);
    }

    // A group of two or more entries means the password is reused.
    let mut group_entries: Vec<Vec<HealthIssue>> = groups
        .into_values()
        .filter(|entries| entries.len() > 1)
        .collect();
    group_entries.sort_by(|a, b| a[0].title.to_lowercase().cmp(&b[0].title.to_lowercase()));

    let mut reused = Vec::with_capacity(group_entries.len());
    for entries in group_entries {
        for issue in &entries {
            if let Some(value) = severity.get_mut(&issue.id) {
                *value += WEIGHT_REUSED;
            }
        }
        reused.push(ReuseGroup { entries });
    }

    let score = if total_logins == 0 {
        100
    } else {
        let total: f64 = severity.values().map(|weight| weight.min(1.0)).sum::<f64>();
        let clean = 1.0 - (total / f64::from(total_logins)).min(1.0);
        (clean * 100.0).round().clamp(0.0, 100.0) as u8
    };

    HealthReport {
        score,
        total_logins,
        weak,
        reused,
        old,
        no_two_factor,
        insecure_url,
    }
}

/// Estimate a password's entropy in bits from its character pool and length.
///
/// This mirrors the Dart `PasswordStrength.estimate` heuristic. It is a
/// deliberate placeholder until a zxcvbn-style analyser lands.
fn estimate_bits(password: &str) -> f64 {
    let (mut lower, mut upper, mut digit, mut symbol) = (false, false, false, false);
    for ch in password.chars() {
        if ch.is_ascii_lowercase() {
            lower = true;
        } else if ch.is_ascii_uppercase() {
            upper = true;
        } else if ch.is_ascii_digit() {
            digit = true;
        } else {
            symbol = true;
        }
    }

    let mut alphabet = 0u32;
    if lower {
        alphabet += 26;
    }
    if upper {
        alphabet += 26;
    }
    if digit {
        alphabet += 10;
    }
    if symbol {
        alphabet += 33;
    }

    let per_character = f64::from(alphabet.max(1)).log2();
    password.chars().count() as f64 * per_character
}

/// Salted SHA-256 of a password, used only for in-memory comparison.
fn hash_password(salt: &[u8], password: &str) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(salt);
    hasher.update(password.as_bytes());
    hasher.finalize().into()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::{now_unix, Entry, EntryBody, Login, Note, TotpConfig};

    const STRONG: &str = "Tr0ub4dour&3xtra-Long!";

    fn login(password: &str) -> Login {
        Login {
            username: "ada".to_string(),
            password: password.to_string(),
            url: "https://example.com".to_string(),
            ..Login::default()
        }
    }

    /// A strong login with TOTP, used as the "clean" baseline.
    fn clean_entry(title: &str, password: &str) -> Entry {
        let mut entry = Entry::login(title, login(password));
        if let EntryBody::Login(inner) = &mut entry.body {
            inner.totp = Some(TotpConfig::new("JBSWY3DPEHPK3PXP"));
        }
        entry
    }

    #[test]
    fn empty_vault_scores_perfect() {
        let report = analyze(&Vault::new(), 1_000_000);
        assert_eq!(report.score, 100);
        assert_eq!(report.total_logins, 0);
        assert!(report.weak.is_empty());
        assert!(report.reused.is_empty());
        assert!(report.old.is_empty());
        assert!(report.no_two_factor.is_empty());
        assert!(report.insecure_url.is_empty());
    }

    #[test]
    fn strong_unique_entry_is_clean() {
        let mut vault = Vault::new();
        vault.add_entry(clean_entry("Mail", STRONG));
        let report = analyze(&vault, now_unix());
        assert_eq!(report.score, 100);
        assert_eq!(report.total_logins, 1);
        assert!(report.weak.is_empty());
        assert!(report.old.is_empty());
        assert!(report.no_two_factor.is_empty());
        assert!(report.insecure_url.is_empty());
    }

    #[test]
    fn weak_password_is_flagged_and_lowers_score() {
        let mut vault = Vault::new();
        vault.add_entry(clean_entry("Mail", "abc"));
        let report = analyze(&vault, now_unix());
        assert_eq!(report.weak.len(), 1);
        assert_eq!(report.weak[0].title, "Mail");
        assert!(report.score < 100);
    }

    #[test]
    fn reused_passwords_form_one_group() {
        let mut vault = Vault::new();
        vault.add_entry(clean_entry("A", STRONG));
        vault.add_entry(clean_entry("B", STRONG));
        vault.add_entry(clean_entry("C", "Different&Longer-99!"));
        let report = analyze(&vault, now_unix());
        assert_eq!(report.reused.len(), 1);
        assert_eq!(report.reused[0].entries.len(), 2);
    }

    #[test]
    fn distinct_passwords_are_not_reused() {
        let mut vault = Vault::new();
        vault.add_entry(clean_entry("A", STRONG));
        vault.add_entry(clean_entry("B", "Another&Longer-88!"));
        let report = analyze(&vault, now_unix());
        assert!(report.reused.is_empty());
    }

    #[test]
    fn missing_totp_is_flagged() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::login("Mail", login(STRONG)));
        let report = analyze(&vault, now_unix());
        assert_eq!(report.no_two_factor.len(), 1);
    }

    #[test]
    fn http_url_is_flagged() {
        let mut vault = Vault::new();
        let mut entry = clean_entry("Mail", STRONG);
        if let EntryBody::Login(inner) = &mut entry.body {
            inner.url = "http://example.com".to_string();
        }
        vault.add_entry(entry);
        let report = analyze(&vault, now_unix());
        assert_eq!(report.insecure_url.len(), 1);
    }

    #[test]
    fn old_password_is_flagged() {
        let mut vault = Vault::new();
        let mut entry = clean_entry("Mail", STRONG);
        entry.updated_at = 1_000_000;
        vault.add_entry(entry);
        let report = analyze(&vault, 1_000_000 + OLD_PASSWORD_SECS + 1);
        assert_eq!(report.old.len(), 1);
    }

    #[test]
    fn deleted_and_non_login_entries_are_ignored() {
        let mut vault = Vault::new();
        let id = vault.add_entry(Entry::login("Mail", login("abc")));
        vault.delete_entry(id).unwrap();
        vault.add_entry(Entry::note(
            "Note",
            Note {
                content: "secret".to_string(),
            },
        ));
        let report = analyze(&vault, now_unix());
        assert_eq!(report.total_logins, 0);
        assert_eq!(report.score, 100);
        assert!(report.weak.is_empty());
    }

    #[test]
    fn entropy_estimate_grows_with_length_and_pool() {
        assert!(estimate_bits("abc") < estimate_bits("abcabcabc"));
        assert!(estimate_bits("aaaa") < estimate_bits("aA1!"));
        assert!(estimate_bits(STRONG) >= WEAK_PASSWORD_BITS);
    }
}
