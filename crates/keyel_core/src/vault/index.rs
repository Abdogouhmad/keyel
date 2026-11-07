//! In-memory search and filtering over vault entries.
//!
//! The index is intentionally simple: vaults are small enough that a linear
//! scan over metadata is fast and avoids a second source of truth that could
//! drift from the encrypted payload.

use unicode_normalization::char::is_combining_mark;
use unicode_normalization::UnicodeNormalization;
use uuid::Uuid;

use super::model::{EntryKind, EntrySummary, Vault};

/// Normalize text for case- and accent-insensitive matching.
///
/// The input is decomposed (NFD), combining marks are removed, and the result
/// is lowercased. `"Café"` and `"cafe"` therefore match each other.
pub fn normalize(input: &str) -> String {
    input
        .nfd()
        .filter(|ch| !is_combining_mark(*ch))
        .flat_map(char::to_lowercase)
        .collect()
}

/// Optional filters for a search.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct EntryFilter {
    /// Only entries of this kind.
    pub kind: Option<EntryKind>,
    /// Only entries in this folder.
    pub folder_id: Option<Uuid>,
    /// Only favorites (`true`) or only non-favorites (`false`).
    pub favorite: Option<bool>,
    /// Only entries with (`true`) or without (`false`) TOTP.
    pub has_totp: Option<bool>,
    /// Include entries currently in the trash.
    pub include_deleted: bool,
}

/// Search entry metadata and return secret-free summaries.
///
/// Matching is case- and accent-insensitive. An empty query returns every
/// entry allowed by `filter`. Results are sorted by title, then id.
pub fn search(vault: &Vault, query: &str, filter: &EntryFilter) -> Vec<EntrySummary> {
    let query = normalize(query.trim());

    let mut results: Vec<(String, EntrySummary)> = vault
        .entries
        .iter()
        .filter(|entry| {
            if !filter.include_deleted && entry.deleted_at.is_some() {
                return false;
            }
            if filter.kind.is_some_and(|kind| entry.kind() != kind) {
                return false;
            }
            if filter
                .folder_id
                .is_some_and(|folder| entry.folder_id != Some(folder))
            {
                return false;
            }
            if filter
                .favorite
                .is_some_and(|favorite| entry.favorite != favorite)
            {
                return false;
            }
            if filter
                .has_totp
                .is_some_and(|has_totp| entry.has_totp() != has_totp)
            {
                return false;
            }
            query.is_empty() || entry.matches_normalized(&query)
        })
        .map(|entry| (normalize(&entry.title), entry.summary()))
        .collect();

    results.sort_by(|(left_title, left), (right_title, right)| {
        left_title
            .cmp(right_title)
            .then_with(|| left.id.cmp(&right.id))
    });
    results.into_iter().map(|(_, summary)| summary).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::model::{Entry, Login, Note, TotpConfig};

    fn vault() -> Vault {
        let mut vault = Vault::new();
        vault.add_entry(Entry::login(
            "Café account",
            Login {
                username: "ada@example.com".into(),
                url: "https://cafe.example".into(),
                ..Login::default()
            },
        ));
        let mut bank = Entry::login(
            "Bank",
            Login {
                username: "ada".into(),
                url: "https://bank.example".into(),
                totp: Some(TotpConfig::new("JBSWY3DPEHPK3PXP")),
                ..Login::default()
            },
        );
        bank.favorite = true;
        vault.add_entry(bank);
        let mut note = Entry::note(
            "Wifi",
            Note {
                content: "secret".into(),
            },
        );
        note.tags = vec!["Home".into()];
        vault.add_entry(note);
        vault
    }

    #[test]
    fn search_is_accent_and_case_insensitive() {
        let vault = vault();
        let results = search(&vault, "cafe", &EntryFilter::default());
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].title, "Café account");

        let results = search(&vault, "CAFÉ", &EntryFilter::default());
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn search_matches_username_url_and_tags() {
        let vault = vault();
        assert_eq!(
            search(&vault, "ada@example", &EntryFilter::default()).len(),
            1
        );
        assert_eq!(
            search(&vault, "bank.example", &EntryFilter::default()).len(),
            1
        );
        assert_eq!(search(&vault, "home", &EntryFilter::default()).len(), 1);
    }

    #[test]
    fn search_never_matches_notes_or_passwords() {
        let vault = vault();
        assert!(search(&vault, "secret", &EntryFilter::default()).is_empty());
    }

    #[test]
    fn filters_by_kind_favorite_and_totp() {
        let vault = vault();
        let favorites = EntryFilter {
            favorite: Some(true),
            ..EntryFilter::default()
        };
        assert_eq!(search(&vault, "", &favorites).len(), 1);

        let with_totp = EntryFilter {
            has_totp: Some(true),
            ..EntryFilter::default()
        };
        assert_eq!(search(&vault, "", &with_totp).len(), 1);

        let notes = EntryFilter {
            kind: Some(EntryKind::Note),
            ..EntryFilter::default()
        };
        assert_eq!(search(&vault, "", &notes).len(), 1);
    }

    #[test]
    fn deleted_entries_are_hidden_unless_requested() {
        let mut vault = vault();
        let id = vault.entries[0].id;
        vault.delete_entry(id).unwrap();
        assert_eq!(search(&vault, "", &EntryFilter::default()).len(), 2);

        let all = EntryFilter {
            include_deleted: true,
            ..EntryFilter::default()
        };
        assert_eq!(search(&vault, "", &all).len(), 3);
    }

    #[test]
    fn empty_query_returns_sorted_titles() {
        let vault = vault();
        let titles: Vec<_> = search(&vault, "", &EntryFilter::default())
            .into_iter()
            .map(|summary| summary.title)
            .collect();
        assert_eq!(titles, ["Bank", "Café account", "Wifi"]);
    }
}
