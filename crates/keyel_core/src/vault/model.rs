//! Vault data model.
//!
//! The model is the decrypted payload of a `vault.keyel` file. It is pure
//! data: no file I/O and no cryptography live here.
//!
//! Payload versioning is independent from the file format version in
//! `format::header`. [`VAULT_SCHEMA_VERSION`] describes this model and is
//! migrated by [`super::migrate`] when a vault is opened.

use std::time::{SystemTime, UNIX_EPOCH};

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use zeroize::Zeroize;

use crate::error::Error;

use super::history::{record_password_change, PasswordHistoryEntry};

/// Current vault payload schema version.
pub const VAULT_SCHEMA_VERSION: u16 = 1;

/// How long a soft-deleted entry stays in the trash.
pub const TRASH_RETENTION_SECS: u64 = 30 * 24 * 60 * 60;

/// Current Unix timestamp in seconds.
pub fn now_unix() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or(0)
}

/// What kind of secret an entry holds.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EntryKind {
    /// Username/password/URL entry.
    Login,
    /// Payment card entry.
    Card,
    /// Free-form secure note.
    Note,
}

/// A folder groups entries. Folders never contain secrets.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Folder {
    /// Stable identifier.
    pub id: Uuid,
    /// Display name.
    pub name: String,
    /// Zero-based position in the sidebar.
    pub order: u32,
}

/// One vault entry, including its secret body.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Entry {
    /// Stable identifier (UUID v7, time ordered).
    pub id: Uuid,
    /// User-visible title. Safe to show in lists.
    pub title: String,
    /// Free-form notes. Treat as secret.
    pub notes: String,
    /// User-defined tags.
    pub tags: Vec<String>,
    /// Folder, if any.
    pub folder_id: Option<Uuid>,
    /// Whether the user marked this entry as a favorite.
    pub favorite: bool,
    /// Creation time (Unix seconds).
    pub created_at: u64,
    /// Last modification time (Unix seconds).
    pub updated_at: u64,
    /// Set when the entry is moved to the trash.
    pub deleted_at: Option<u64>,
    /// Secret payload.
    pub body: EntryBody,
}

impl Entry {
    /// Build a new entry of any kind with a fresh id and timestamps.
    pub fn new(title: impl Into<String>, body: EntryBody) -> Self {
        let now = now_unix();
        Self {
            id: Uuid::now_v7(),
            title: title.into(),
            notes: String::new(),
            tags: Vec::new(),
            folder_id: None,
            favorite: false,
            created_at: now,
            updated_at: now,
            deleted_at: None,
            body,
        }
    }

    /// Convenience constructor for a login entry.
    pub fn login(title: impl Into<String>, login: Login) -> Self {
        Self::new(title, EntryBody::Login(login))
    }

    /// Convenience constructor for a card entry.
    pub fn card(title: impl Into<String>, card: Card) -> Self {
        Self::new(title, EntryBody::Card(card))
    }

    /// Convenience constructor for a secure note.
    pub fn note(title: impl Into<String>, note: Note) -> Self {
        Self::new(title, EntryBody::Note(note))
    }

    /// The kind of this entry.
    pub fn kind(&self) -> EntryKind {
        self.body.kind()
    }

    /// Whether this entry has a TOTP configured.
    pub fn has_totp(&self) -> bool {
        self.body.has_totp()
    }

    /// A list-safe view with no secret fields.
    pub fn summary(&self) -> EntrySummary {
        EntrySummary {
            id: self.id,
            kind: self.kind(),
            title: self.title.clone(),
            subtitle: self.body.subtitle(),
            favorite: self.favorite,
            folder_id: self.folder_id,
            has_totp: self.has_totp(),
            deleted_at: self.deleted_at,
        }
    }

    /// Match a query that has already been normalized by `index::normalize`.
    ///
    /// Only metadata is searched: title, tags, username, URL, cardholder and
    /// brand. Passwords, notes and card numbers are never matched.
    pub(crate) fn matches_normalized(&self, query: &str) -> bool {
        let contains = |value: &str| super::index::normalize(value).contains(query);

        contains(&self.title)
            || self.tags.iter().any(|tag| contains(tag))
            || match &self.body {
                EntryBody::Login(login) => contains(&login.username) || contains(&login.url),
                EntryBody::Card(card) => {
                    contains(&card.cardholder) || card.brand.as_deref().is_some_and(contains)
                }
                EntryBody::Note(_) => false,
            }
    }

    /// Overwrite secret fields in place. Called when an entry is dropped or
    /// replaced so old passwords do not linger in freed memory longer than
    /// necessary. This is best-effort: Rust `String`s may have been copied by
    /// callers before that point.
    pub(crate) fn zeroize_secrets(&mut self) {
        self.notes.zeroize();
        match &mut self.body {
            EntryBody::Login(login) => {
                login.password.zeroize();
                for entry in &mut login.password_history {
                    entry.password.zeroize();
                }
                if let Some(totp) = &mut login.totp {
                    totp.secret.zeroize();
                }
            }
            EntryBody::Card(card) => {
                card.number.zeroize();
                card.cvv.zeroize();
            }
            EntryBody::Note(note) => note.content.zeroize(),
        }
    }
}

/// The kind-specific secret payload.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EntryBody {
    /// Login credentials.
    Login(Login),
    /// Payment card.
    Card(Card),
    /// Secure note.
    Note(Note),
}

impl EntryBody {
    /// The kind of this body.
    pub fn kind(&self) -> EntryKind {
        match self {
            Self::Login(_) => EntryKind::Login,
            Self::Card(_) => EntryKind::Card,
            Self::Note(_) => EntryKind::Note,
        }
    }

    /// Whether a TOTP secret is configured.
    pub fn has_totp(&self) -> bool {
        matches!(self, Self::Login(login) if login.totp.is_some())
    }

    /// A non-secret subtitle for list rows.
    fn subtitle(&self) -> String {
        match self {
            Self::Login(login) => {
                if login.username.is_empty() {
                    login.url.clone()
                } else {
                    login.username.clone()
                }
            }
            Self::Card(card) => card
                .brand
                .clone()
                .filter(|brand| !brand.is_empty())
                .unwrap_or_else(|| card.cardholder.clone()),
            Self::Note(_) => "Note".to_string(),
        }
    }
}

/// Login credentials.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Login {
    /// Username or email address.
    pub username: String,
    /// Current password. Secret.
    pub password: String,
    /// Website URL.
    pub url: String,
    /// Optional TOTP configuration.
    pub totp: Option<TotpConfig>,
    /// Previous passwords, newest first. Capped by `history`.
    pub password_history: Vec<PasswordHistoryEntry>,
}

/// Payment card data.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Card {
    /// Name printed on the card.
    pub cardholder: String,
    /// Card number. Secret.
    pub number: String,
    /// Expiry as free text (`MM/YY`).
    pub expiry: String,
    /// Security code. Secret.
    pub cvv: String,
    /// Optional brand name.
    pub brand: Option<String>,
}

/// Free-form secure note.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Note {
    /// Note content. Secret.
    pub content: String,
}

/// TOTP hash algorithm.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TotpAlgorithm {
    /// SHA-1 (the RFC default used by most services).
    #[default]
    Sha1,
    /// SHA-256.
    Sha256,
    /// SHA-512.
    Sha512,
}

/// TOTP secret and parameters.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TotpConfig {
    /// Base32-encoded shared secret. Secret.
    pub secret: String,
    /// Hash algorithm.
    pub algorithm: TotpAlgorithm,
    /// Number of digits.
    pub digits: u8,
    /// Time step in seconds.
    pub period: u32,
}

impl TotpConfig {
    /// Build a standard 6-digit / 30-second SHA-1 configuration.
    pub fn new(secret: impl Into<String>) -> Self {
        Self {
            secret: secret.into(),
            algorithm: TotpAlgorithm::Sha1,
            digits: 6,
            period: 30,
        }
    }
}

/// List-safe entry view. Contains no secrets.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EntrySummary {
    /// Stable identifier.
    pub id: Uuid,
    /// Entry kind.
    pub kind: EntryKind,
    /// Entry title.
    pub title: String,
    /// Secondary line (username, URL, brand, ...). Never a password.
    pub subtitle: String,
    /// Favorite flag.
    pub favorite: bool,
    /// Folder, if any.
    pub folder_id: Option<Uuid>,
    /// Whether the entry has TOTP.
    pub has_totp: bool,
    /// Trash marker, if soft-deleted (Unix seconds).
    pub deleted_at: Option<u64>,
}

/// The decrypted vault payload.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Vault {
    /// Payload schema version.
    pub schema_version: u16,
    /// Folders in display order.
    pub folders: Vec<Folder>,
    /// All entries, including soft-deleted ones.
    pub entries: Vec<Entry>,
}

impl Default for Vault {
    fn default() -> Self {
        Self::new()
    }
}

impl Vault {
    /// Create an empty vault.
    pub fn new() -> Self {
        Self {
            schema_version: VAULT_SCHEMA_VERSION,
            folders: Vec::new(),
            entries: Vec::new(),
        }
    }

    /// Serialize the payload to CBOR.
    pub fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let mut bytes = Vec::new();
        ciborium::into_writer(self, &mut bytes).map_err(|_| Error::Corrupted)?;
        Ok(bytes)
    }

    /// Deserialize a payload from CBOR.
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, Error> {
        ciborium::from_reader(bytes).map_err(|_| Error::Corrupted)
    }

    /// Find an entry by id, including trashed entries.
    pub fn entry(&self, id: Uuid) -> Option<&Entry> {
        self.entries.iter().find(|entry| entry.id == id)
    }

    /// Find a mutable entry by id, including trashed entries.
    pub fn entry_mut(&mut self, id: Uuid) -> Option<&mut Entry> {
        self.entries.iter_mut().find(|entry| entry.id == id)
    }

    /// Add an entry and return its id.
    pub fn add_entry(&mut self, entry: Entry) -> Uuid {
        let id = entry.id;
        self.entries.push(entry);
        id
    }

    /// Replace an entry, preserving `created_at`.
    ///
    /// If a login's password changed, the previous password is pushed to the
    /// history (capped at [`super::history::PASSWORD_HISTORY_CAP`]).
    pub fn update_entry(&mut self, mut entry: Entry) -> Result<(), Error> {
        let index = self
            .entries
            .iter()
            .position(|existing| existing.id == entry.id)
            .ok_or(Error::NotFound)?;

        let created_at = self.entries[index].created_at;
        entry.created_at = created_at;
        entry.updated_at = now_unix();
        let old_password = match &self.entries[index].body {
            EntryBody::Login(login) => Some(login.password.clone()),
            EntryBody::Card(_) | EntryBody::Note(_) => None,
        };

        if let (Some(mut old_password), EntryBody::Login(new_login)) =
            (old_password, &mut entry.body)
        {
            if old_password != new_login.password {
                record_password_change(new_login, old_password, entry.updated_at);
            } else {
                old_password.zeroize();
            }
        }

        let mut replaced = std::mem::replace(&mut self.entries[index], entry);
        replaced.zeroize_secrets();
        Ok(())
    }

    /// Move an entry to the trash. Already-deleted entries keep their original
    /// deletion time.
    pub fn delete_entry(&mut self, id: Uuid) -> Result<(), Error> {
        let entry = self.entry_mut(id).ok_or(Error::NotFound)?;
        if entry.deleted_at.is_none() {
            let now = now_unix();
            entry.deleted_at = Some(now);
            entry.updated_at = now;
        }
        Ok(())
    }

    /// Restore an entry from the trash.
    pub fn restore_entry(&mut self, id: Uuid) -> Result<(), Error> {
        let entry = self.entry_mut(id).ok_or(Error::NotFound)?;
        entry.deleted_at = None;
        entry.updated_at = now_unix();
        Ok(())
    }

    /// Permanently remove an entry.
    pub fn purge_entry(&mut self, id: Uuid) -> Result<(), Error> {
        let index = self
            .entries
            .iter()
            .position(|entry| entry.id == id)
            .ok_or(Error::NotFound)?;
        let mut removed = self.entries.remove(index);
        removed.zeroize_secrets();
        Ok(())
    }

    /// Permanently remove entries that have been in the trash for at least
    /// [`TRASH_RETENTION_SECS`]. Returns how many were purged.
    pub fn purge_expired(&mut self, now: u64) -> usize {
        let before = self.entries.len();
        self.entries.retain_mut(|entry| {
            let expired = match entry.deleted_at {
                None => false,
                Some(deleted_at) => now.saturating_sub(deleted_at) >= TRASH_RETENTION_SECS,
            };
            if expired {
                entry.zeroize_secrets();
            }
            !expired
        });
        before - self.entries.len()
    }

    /// Create a folder at the end of the list.
    pub fn add_folder(&mut self, name: impl Into<String>) -> Uuid {
        let id = Uuid::now_v7();
        let order = self.folders.len() as u32;
        self.folders.push(Folder {
            id,
            name: name.into(),
            order,
        });
        id
    }

    /// Rename a folder.
    pub fn rename_folder(&mut self, id: Uuid, name: impl Into<String>) -> Result<(), Error> {
        let folder = self
            .folders
            .iter_mut()
            .find(|folder| folder.id == id)
            .ok_or(Error::NotFound)?;
        folder.name = name.into();
        Ok(())
    }

    /// Delete a folder. Entries in it move to "No folder".
    pub fn delete_folder(&mut self, id: Uuid) -> Result<(), Error> {
        let before = self.folders.len();
        self.folders.retain(|folder| folder.id != id);
        if self.folders.len() == before {
            return Err(Error::NotFound);
        }
        for entry in &mut self.entries {
            if entry.folder_id == Some(id) {
                entry.folder_id = None;
            }
        }
        Ok(())
    }

    /// Reorder folders. `order` must list every folder id exactly once.
    pub fn reorder_folders(&mut self, order: &[Uuid]) -> Result<(), Error> {
        if order.len() != self.folders.len() {
            return Err(Error::NotFound);
        }
        let unique: std::collections::HashSet<_> = order.iter().collect();
        if unique.len() != order.len()
            || !order
                .iter()
                .all(|id| self.folders.iter().any(|f| f.id == *id))
        {
            return Err(Error::NotFound);
        }
        for (position, id) in order.iter().enumerate() {
            if let Some(folder) = self.folders.iter_mut().find(|folder| folder.id == *id) {
                folder.order = position as u32;
            }
        }
        self.folders.sort_by_key(|folder| folder.order);
        Ok(())
    }
}

impl Drop for Vault {
    fn drop(&mut self) {
        for entry in &mut self.entries {
            entry.zeroize_secrets();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn login(password: &str) -> Login {
        Login {
            username: "ada".to_string(),
            password: password.to_string(),
            url: "https://example.com".to_string(),
            ..Login::default()
        }
    }

    #[test]
    fn serialize_round_trip_is_lossless() {
        let mut vault = Vault::new();
        let folder = vault.add_folder("Work");
        let mut entry = Entry::login("Mail", login("hunter2"));
        entry.folder_id = Some(folder);
        entry.tags = vec!["email".into(), "work".into()];
        entry.body = EntryBody::Login(Login {
            totp: Some(TotpConfig::new("JBSWY3DPEHPK3PXP")),
            ..login("hunter2")
        });
        vault.add_entry(entry);
        vault.add_entry(Entry::note(
            "Recovery",
            Note {
                content: "codes".into(),
            },
        ));

        let bytes = vault.to_bytes().unwrap();
        let decoded = Vault::from_bytes(&bytes).unwrap();
        assert_eq!(vault, decoded);
    }

    #[test]
    fn update_records_password_history_and_keeps_created_at() {
        let mut vault = Vault::new();
        let entry = Entry::login("Mail", login("old"));
        let id = vault.add_entry(entry.clone());
        let created_at = entry.created_at;

        let mut updated = entry;
        updated.body = EntryBody::Login(login("new"));
        vault.update_entry(updated).unwrap();

        let stored = vault.entry(id).unwrap();
        assert_eq!(stored.created_at, created_at);
        let EntryBody::Login(stored_login) = &stored.body else {
            panic!("expected login");
        };
        assert_eq!(stored_login.password, "new");
        assert_eq!(stored_login.password_history.len(), 1);
        assert_eq!(stored_login.password_history[0].password, "old");
    }

    #[test]
    fn history_is_capped_at_ten() {
        let mut vault = Vault::new();
        let entry = Entry::login("Mail", login("p0"));
        let id = vault.add_entry(entry);

        for index in 1..=15 {
            let mut updated = vault.entry(id).unwrap().clone();
            let EntryBody::Login(updated_login) = &mut updated.body else {
                panic!("expected login");
            };
            updated_login.password = format!("p{index}");
            vault.update_entry(updated).unwrap();
        }

        let EntryBody::Login(stored) = &vault.entry(id).unwrap().body else {
            panic!("expected login");
        };
        assert_eq!(
            stored.password_history.len(),
            super::super::history::PASSWORD_HISTORY_CAP
        );
        assert_eq!(stored.password_history[0].password, "p14");
        assert_eq!(stored.password_history[9].password, "p5");
    }

    #[test]
    fn trash_lifecycle_and_expiry() {
        let mut vault = Vault::new();
        let id = vault.add_entry(Entry::note("n", Note::default()));
        vault.delete_entry(id).unwrap();
        assert!(vault.entry(id).unwrap().deleted_at.is_some());

        vault.restore_entry(id).unwrap();
        assert!(vault.entry(id).unwrap().deleted_at.is_none());

        vault.delete_entry(id).unwrap();
        let now = now_unix();
        vault.entry_mut(id).unwrap().deleted_at = Some(now - TRASH_RETENTION_SECS - 1);
        assert_eq!(vault.purge_expired(now), 1);
        assert!(vault.entry(id).is_none());
    }

    #[test]
    fn deleting_a_folder_moves_entries_to_no_folder() {
        let mut vault = Vault::new();
        let folder = vault.add_folder("Old");
        let mut entry = Entry::note("n", Note::default());
        entry.folder_id = Some(folder);
        let id = vault.add_entry(entry);

        vault.delete_folder(folder).unwrap();
        assert_eq!(vault.entry(id).unwrap().folder_id, None);
        assert!(vault.folders.is_empty());
    }

    #[test]
    fn folders_can_be_reordered() {
        let mut vault = Vault::new();
        let a = vault.add_folder("A");
        let b = vault.add_folder("B");
        vault.reorder_folders(&[b, a]).unwrap();
        assert_eq!(vault.folders[0].id, b);
        assert_eq!(vault.folders[1].id, a);
    }
}
