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
use crate::sync::version::VersionVector;

use super::history::{record_password_change, PasswordHistoryEntry};

/// Current vault payload schema version.
///
/// History:
/// - v1: initial payload.
/// - v2: entries gained an optional user-chosen `icon`.
/// - v3: entries gained ordered `custom_fields`.
/// - v4: entries gained the `passkey` kind/body for WebAuthn credentials.
/// - v5: opt-in sync metadata (`sync_config`, per-item `sync_meta`, tombstones).
pub const VAULT_SCHEMA_VERSION: u16 = 5;

/// How long a soft-deleted entry stays in the trash.
pub const TRASH_RETENTION_SECS: u64 = 30 * 24 * 60 * 60;

/// How long a permanent-removal tombstone is retained for sync convergence.
pub const TOMBSTONE_RETENTION_SECS: u64 = 90 * 24 * 60 * 60;

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
    /// A WebAuthn/FIDO2 passkey credential.
    Passkey,
}

/// The value kind of a user-defined custom field.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CustomFieldKind {
    /// Plain text. Safe to show and searchable as metadata.
    Text,
    /// Secret text (PIN, recovery code, answer). Masked and never indexed.
    Hidden,
    /// A URL. Treated as non-secret metadata.
    Url,
}

/// A user-defined extra field stored on an entry.
///
/// `Hidden` values are secrets: they are masked by default, revealed only on
/// demand, and excluded from metadata search and diagnostics.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CustomField {
    /// Stable identifier, used by the UI to address a specific field.
    pub id: Uuid,
    /// User-visible label.
    pub label: String,
    /// Field value. Secret when `kind` is [`CustomFieldKind::Hidden`].
    pub value: String,
    /// How the value should be interpreted and displayed.
    pub kind: CustomFieldKind,
}

/// Which kind of vault item a tombstone refers to.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TombstoneKind {
    /// A folder was permanently removed.
    Folder,
    /// An entry was permanently removed.
    Entry,
}

/// A permanent-removal marker propagated by sync.
///
/// Tombstones prevent a purged item from reappearing when another device still
/// holds a copy. They are retained longer than the 30-day trash window so all
/// devices have time to converge.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Tombstone {
    /// Identifier of the removed item.
    pub id: Uuid,
    /// When the item was soft-deleted, if it was ever trashed.
    #[serde(default)]
    pub deleted_at: Option<u64>,
    /// When the item was permanently removed. A tombstone with a purged time
    /// dominates any live item with a causally earlier version.
    #[serde(default)]
    pub purged_at: Option<u64>,
    /// Change version of the removal.
    #[serde(default)]
    pub version: VersionVector,
    /// Item kind.
    pub kind: TombstoneKind,
}

/// Secret sync configuration stored inside the encrypted vault payload.
///
/// Only present when sync has been enabled. `sync_key` is a shared secret and
/// must never appear in summaries, DTOs, logs, diagnostics or the UI.
#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncConfig {
    /// Whether sync is currently enabled on this device.
    pub enabled: bool,
    /// Non-secret identifier of the sync group.
    pub sync_id: [u8; 16],
    /// Non-secret identifier of this device in the sync group.
    pub device_id: [u8; 16],
    /// Shared secret sync key. Zeroized on drop; never leaves Rust.
    pub sync_key: [u8; 32],
    /// Informational, user-chosen folder/location hint (non-secret).
    #[serde(default)]
    pub folder_hint: String,
    /// Unix seconds of the last successful sync, if any.
    #[serde(default)]
    pub last_sync_at: u64,
    /// Monotonic per-device blob sequence, authenticated in every push.
    #[serde(default)]
    pub sequence: u64,
}

impl std::fmt::Debug for SyncConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SyncConfig")
            .field("enabled", &self.enabled)
            .field("sync_id", &self.sync_id)
            .field("device_id", &self.device_id)
            .field("sync_key", &"[REDACTED]")
            .field("folder_hint", &self.folder_hint)
            .field("last_sync_at", &self.last_sync_at)
            .field("sequence", &self.sequence)
            .finish()
    }
}

impl Drop for SyncConfig {
    fn drop(&mut self) {
        self.sync_key.zeroize();
        self.sync_id.zeroize();
        self.device_id.zeroize();
    }
}

impl CustomField {
    /// Build a new custom field with a fresh id.
    pub fn new(label: impl Into<String>, value: impl Into<String>, kind: CustomFieldKind) -> Self {
        Self {
            id: Uuid::now_v7(),
            label: label.into(),
            value: value.into(),
            kind,
        }
    }

    /// Whether this field's value is secret.
    pub fn is_secret(&self) -> bool {
        matches!(self.kind, CustomFieldKind::Hidden)
    }
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
    /// Sync change metadata. Empty/zero for pre-v5 payloads and while sync is off.
    ///
    /// `#[serde(default)]` keeps payloads written before schema v5 readable.
    #[serde(default)]
    pub sync_meta: SyncMeta,
}

/// Per-item sync change metadata.
///
/// Used with a per-device version vector to detect causality and concurrent
/// edits. Absent/empty for items created before schema v5.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncMeta {
    /// Logical edit version per sync device.
    #[serde(default)]
    pub version: VersionVector,
    /// Device that produced the last recorded change, or all-zero for legacy items.
    #[serde(default)]
    pub updated_by: [u8; 16],
}

impl SyncMeta {
    /// Whether no sync edit has been recorded for this item.
    pub fn is_empty(&self) -> bool {
        self.version.is_empty() && self.updated_by == [0u8; 16]
    }
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
    /// Optional user-chosen icon key (a stable slug resolved to a glyph by the
    /// UI). `None` falls back to the default glyph for the entry kind.
    ///
    /// `#[serde(default)]` keeps payloads written before schema v2 readable.
    #[serde(default)]
    pub icon: Option<String>,
    /// User-defined extra fields, in display order.
    ///
    /// `#[serde(default)]` keeps payloads written before schema v3 readable.
    #[serde(default)]
    pub custom_fields: Vec<CustomField>,
    /// Creation time (Unix seconds).
    pub created_at: u64,
    /// Last modification time (Unix seconds).
    pub updated_at: u64,
    /// Set when the entry is moved to the trash.
    pub deleted_at: Option<u64>,
    /// Sync change metadata. Empty/zero for pre-v5 payloads and while sync is off.
    ///
    /// `#[serde(default)]` keeps payloads written before schema v5 readable.
    #[serde(default)]
    pub sync_meta: SyncMeta,
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
            icon: None,
            custom_fields: Vec::new(),
            created_at: now,
            updated_at: now,
            deleted_at: None,
            sync_meta: SyncMeta::default(),
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

    /// Convenience constructor for a passkey entry.
    pub fn passkey(title: impl Into<String>, passkey: Passkey) -> Self {
        Self::new(title, EntryBody::Passkey(passkey))
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
            icon: self.icon.clone(),
            has_totp: self.has_totp(),
            deleted_at: self.deleted_at,
        }
    }

    /// Match a query that has already been normalized by `index::normalize`.
    ///
    /// Only metadata is searched: title, tags, username, URL, cardholder and
    /// brand, plus non-secret custom-field labels and values (`text`/`url`).
    /// Passwords, notes, card numbers and hidden custom-field values are never
    /// matched.
    pub(crate) fn matches_normalized(&self, query: &str) -> bool {
        let contains = |value: &str| super::index::normalize(value).contains(query);

        contains(&self.title)
            || self.tags.iter().any(|tag| contains(tag))
            || self.custom_fields.iter().any(|field| {
                contains(&field.label) || (!field.is_secret() && contains(&field.value))
            })
            || match &self.body {
                EntryBody::Login(login) => contains(&login.username) || contains(&login.url),
                EntryBody::Card(card) => {
                    contains(&card.cardholder) || card.brand.as_deref().is_some_and(contains)
                }
                EntryBody::Note(_) => false,
                EntryBody::Passkey(passkey) => {
                    contains(&passkey.rp_id)
                        || contains(&passkey.rp_name)
                        || contains(&passkey.user_name)
                        || contains(&passkey.user_display_name)
                }
            }
    }

    /// Overwrite secret fields in place. Called when an entry is dropped or
    /// replaced so old passwords do not linger in freed memory longer than
    /// necessary. This is best-effort: Rust `String`s may have been copied by
    /// callers before that point.
    pub(crate) fn zeroize_secrets(&mut self) {
        self.notes.zeroize();
        for field in &mut self.custom_fields {
            if field.is_secret() {
                field.value.zeroize();
            }
        }
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
            EntryBody::Passkey(passkey) => passkey.zeroize_secrets(),
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
    /// WebAuthn/FIDO2 passkey credential.
    Passkey(Passkey),
}

impl EntryBody {
    /// The kind of this body.
    pub fn kind(&self) -> EntryKind {
        match self {
            Self::Login(_) => EntryKind::Login,
            Self::Card(_) => EntryKind::Card,
            Self::Note(_) => EntryKind::Note,
            Self::Passkey(_) => EntryKind::Passkey,
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
            Self::Passkey(passkey) => {
                if !passkey.user_name.is_empty() {
                    passkey.user_name.clone()
                } else if !passkey.user_display_name.is_empty() {
                    passkey.user_display_name.clone()
                } else if !passkey.rp_name.is_empty() {
                    passkey.rp_name.clone()
                } else {
                    passkey.rp_id.clone()
                }
            }
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

/// A WebAuthn/FIDO2 passkey credential.
///
/// Private key material is secret: it is zeroized in memory and never exposed in
/// summaries, search, diagnostics, or normal detail/reveal DTOs. Ceremonies that
/// use the key must operate inside Rust/session boundaries.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Passkey {
    /// Relying Party identifier (e.g. `example.com`).
    pub rp_id: String,
    /// Human-readable relying party name.
    pub rp_name: String,
    /// Credential identifier bytes.
    #[serde(default)]
    pub credential_id: Vec<u8>,
    /// User handle bytes provided by the relying party.
    #[serde(default)]
    pub user_handle: Vec<u8>,
    /// Account/user name.
    pub user_name: String,
    /// Display name for the account/user.
    pub user_display_name: String,
    /// COSE public key bytes.
    #[serde(default)]
    pub public_key: Vec<u8>,
    /// Private key material. Secret.
    #[serde(default)]
    pub private_key: Vec<u8>,
    /// COSE algorithm identifier (e.g. -7 ES256, -257 RS256, -8 EdDSA).
    #[serde(default)]
    pub algorithm: i32,
    /// Signature counter.
    #[serde(default)]
    pub sign_count: u32,
    /// When this credential was created (Unix seconds).
    #[serde(default)]
    pub created_at: u64,
    /// When this credential was last used (Unix seconds), if known.
    #[serde(default)]
    pub last_used_at: Option<u64>,
    /// Transport hints (e.g. `internal`, `usb`, `nfc`, `ble`, `hybrid`).
    #[serde(default)]
    pub transports: Vec<String>,
    /// Whether the credential is discoverable/resident.
    #[serde(default)]
    pub discoverable: bool,
}

impl Passkey {
    /// Overwrite secret material in place.
    pub(crate) fn zeroize_secrets(&mut self) {
        self.private_key.zeroize();
        self.user_handle.zeroize();
        // Credential id is not a cryptographic secret but is sensitive metadata;
        // keep it intact for identity. Public key is public.
    }
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
    /// Optional user-chosen icon key, if set.
    pub icon: Option<String>,
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
    /// Secret sync configuration, if sync is enabled on this device.
    ///
    /// `#[serde(default)]` keeps payloads written before schema v5 readable.
    #[serde(default)]
    pub sync_config: Option<SyncConfig>,
    /// Permanent-removal tombstones propagated by sync.
    ///
    /// `#[serde(default)]` keeps payloads written before schema v5 readable.
    #[serde(default)]
    pub tombstones: Vec<Tombstone>,
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
            sync_config: None,
            tombstones: Vec::new(),
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
    pub fn add_entry(&mut self, mut entry: Entry) -> Uuid {
        if let Some(device_id) = self.sync_device_id() {
            entry.sync_meta.version.bump(&device_id);
            entry.sync_meta.updated_by = device_id;
        }
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

        let device_id = self.sync_device_id();
        let created_at = self.entries[index].created_at;
        let mut sync_meta = self.entries[index].sync_meta.clone();
        entry.created_at = created_at;
        entry.updated_at = now_unix();
        let old_password = match &self.entries[index].body {
            EntryBody::Login(login) => Some(login.password.clone()),
            EntryBody::Card(_) | EntryBody::Note(_) | EntryBody::Passkey(_) => None,
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

        if let Some(device_id) = device_id {
            sync_meta.version.bump(&device_id);
            sync_meta.updated_by = device_id;
        }
        entry.sync_meta = sync_meta;

        let mut replaced = std::mem::replace(&mut self.entries[index], entry);
        replaced.zeroize_secrets();
        Ok(())
    }

    /// Move an entry to the trash. Already-deleted entries keep their original
    /// deletion time.
    pub fn delete_entry(&mut self, id: Uuid) -> Result<(), Error> {
        let device_id = self.sync_device_id();
        let entry = self.entry_mut(id).ok_or(Error::NotFound)?;
        if entry.deleted_at.is_none() {
            let now = now_unix();
            entry.deleted_at = Some(now);
            entry.updated_at = now;
            if let Some(device_id) = device_id {
                entry.sync_meta.version.bump(&device_id);
                entry.sync_meta.updated_by = device_id;
            }
        }
        Ok(())
    }

    /// Restore an entry from the trash.
    pub fn restore_entry(&mut self, id: Uuid) -> Result<(), Error> {
        let device_id = self.sync_device_id();
        let entry = self.entry_mut(id).ok_or(Error::NotFound)?;
        entry.deleted_at = None;
        entry.updated_at = now_unix();
        if let Some(device_id) = device_id {
            entry.sync_meta.version.bump(&device_id);
            entry.sync_meta.updated_by = device_id;
        }
        Ok(())
    }

    /// Permanently remove an entry.
    pub fn purge_entry(&mut self, id: Uuid) -> Result<(), Error> {
        let device_id = self.sync_device_id();
        let index = self
            .entries
            .iter()
            .position(|entry| entry.id == id)
            .ok_or(Error::NotFound)?;
        let mut removed = self.entries.remove(index);
        if let Some(device_id) = device_id {
            let mut version = removed.sync_meta.version.clone();
            version.bump(&device_id);
            self.tombstones.push(Tombstone {
                id: removed.id,
                deleted_at: removed.deleted_at,
                purged_at: Some(now_unix()),
                version,
                kind: TombstoneKind::Entry,
            });
        }
        removed.zeroize_secrets();
        Ok(())
    }

    /// Permanently remove entries that have been in the trash for at least
    /// [`TRASH_RETENTION_SECS`]. Returns how many were purged.
    pub fn purge_expired(&mut self, now: u64) -> usize {
        let device_id = self.sync_device_id();
        let mut purged = 0usize;
        let mut retained = Vec::with_capacity(self.entries.len());
        for mut entry in std::mem::take(&mut self.entries) {
            let expired = match entry.deleted_at {
                None => false,
                Some(deleted_at) => now.saturating_sub(deleted_at) >= TRASH_RETENTION_SECS,
            };
            if expired {
                purged += 1;
                if let Some(device_id) = device_id {
                    let mut version = entry.sync_meta.version.clone();
                    version.bump(&device_id);
                    self.tombstones.push(Tombstone {
                        id: entry.id,
                        deleted_at: entry.deleted_at,
                        purged_at: Some(now),
                        version,
                        kind: TombstoneKind::Entry,
                    });
                }
                entry.zeroize_secrets();
            } else {
                retained.push(entry);
            }
        }
        self.entries = retained;
        self.tombstones
            .retain(|tombstone| match tombstone.purged_at {
                Some(purged_at) => now.saturating_sub(purged_at) < TOMBSTONE_RETENTION_SECS,
                None => true,
            });
        purged
    }

    /// Device id used for recording sync versions, if sync is enabled.
    pub(crate) fn sync_device_id(&self) -> Option<[u8; 16]> {
        self.sync_config
            .as_ref()
            .filter(|config| config.enabled)
            .map(|config| config.device_id)
    }

    /// Create a folder at the end of the list.
    pub fn add_folder(&mut self, name: impl Into<String>) -> Uuid {
        let id = Uuid::now_v7();
        let order = self.folders.len() as u32;
        let mut folder = Folder {
            id,
            name: name.into(),
            order,
            sync_meta: SyncMeta::default(),
        };
        if let Some(device_id) = self.sync_device_id() {
            folder.sync_meta.version.bump(&device_id);
            folder.sync_meta.updated_by = device_id;
        }
        self.folders.push(folder);
        id
    }

    /// Rename a folder.
    pub fn rename_folder(&mut self, id: Uuid, name: impl Into<String>) -> Result<(), Error> {
        let device_id = self.sync_device_id();
        let folder = self
            .folders
            .iter_mut()
            .find(|folder| folder.id == id)
            .ok_or(Error::NotFound)?;
        folder.name = name.into();
        if let Some(device_id) = device_id {
            folder.sync_meta.version.bump(&device_id);
            folder.sync_meta.updated_by = device_id;
        }
        Ok(())
    }

    /// Delete a folder. Entries in it move to "No folder".
    pub fn delete_folder(&mut self, id: Uuid) -> Result<(), Error> {
        let device_id = self.sync_device_id();
        let index = self
            .folders
            .iter()
            .position(|folder| folder.id == id)
            .ok_or(Error::NotFound)?;
        let removed = self.folders.remove(index);
        let now = now_unix();
        if let Some(device_id) = device_id {
            let mut version = removed.sync_meta.version.clone();
            version.bump(&device_id);
            self.tombstones.push(Tombstone {
                id: removed.id,
                deleted_at: None,
                purged_at: Some(now),
                version,
                kind: TombstoneKind::Folder,
            });
        }
        for entry in &mut self.entries {
            if entry.folder_id == Some(id) {
                entry.folder_id = None;
                if let Some(device_id) = device_id {
                    entry.updated_at = now;
                    entry.sync_meta.version.bump(&device_id);
                    entry.sync_meta.updated_by = device_id;
                }
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
        let device_id = self.sync_device_id();
        for (position, id) in order.iter().enumerate() {
            if let Some(folder) = self.folders.iter_mut().find(|folder| folder.id == *id) {
                folder.order = position as u32;
            }
        }
        self.folders.sort_by_key(|folder| folder.order);
        if let Some(device_id) = device_id {
            for folder in &mut self.folders {
                folder.sync_meta.version.bump(&device_id);
                folder.sync_meta.updated_by = device_id;
            }
        }
        Ok(())
    }
}

impl Drop for Vault {
    fn drop(&mut self) {
        for entry in &mut self.entries {
            entry.zeroize_secrets();
        }
        if let Some(sync_config) = &mut self.sync_config {
            sync_config.sync_key.zeroize();
            sync_config.sync_id.zeroize();
            sync_config.device_id.zeroize();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::history::PasswordHistoryEntry;

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
        entry.custom_fields = vec![
            CustomField::new("PIN", "1234", CustomFieldKind::Hidden),
            CustomField::new("Profile", "https://example.com/u/ada", CustomFieldKind::Url),
            CustomField::new("Note", "vip", CustomFieldKind::Text),
        ];
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
    fn v4_payload_defaults_sync_fields() {
        // Simulate a schema v4 payload: CBOR written without v5-only fields.
        // Deserialization must supply defaults and migration must lift to v5.
        let value = ciborium::Value::Map(vec![
            (
                ciborium::Value::Text("schema_version".into()),
                ciborium::Value::Integer(4u64.into()),
            ),
            (
                ciborium::Value::Text("folders".into()),
                ciborium::Value::Array(vec![ciborium::Value::Map(vec![
                    (
                        ciborium::Value::Text("id".into()),
                        ciborium::Value::Bytes(Uuid::now_v7().as_bytes().to_vec()),
                    ),
                    (
                        ciborium::Value::Text("name".into()),
                        ciborium::Value::Text("Work".into()),
                    ),
                    (
                        ciborium::Value::Text("order".into()),
                        ciborium::Value::Integer(0u64.into()),
                    ),
                ])]),
            ),
            (
                ciborium::Value::Text("entries".into()),
                ciborium::Value::Array(vec![]),
            ),
        ]);
        let mut bytes = Vec::new();
        ciborium::into_writer(&value, &mut bytes).unwrap();
        let decoded = Vault::from_bytes(&bytes).unwrap();
        assert_eq!(decoded.schema_version, 4);
        assert!(decoded.sync_config.is_none());
        assert!(decoded.tombstones.is_empty());
        assert!(decoded.folders[0].sync_meta.is_empty());

        let migrated = crate::vault::migrate::migrate(decoded, 4).unwrap();
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
        assert!(migrated.sync_config.is_none());
        assert!(migrated.tombstones.is_empty());
    }

    #[test]
    fn sync_config_round_trips_and_debug_is_redacted() {
        let mut vault = Vault::new();
        vault.sync_config = Some(SyncConfig {
            enabled: true,
            sync_id: [1u8; 16],
            device_id: [2u8; 16],
            sync_key: [3u8; 32],
            folder_hint: "/tmp/sync".into(),
            last_sync_at: 123,
            sequence: 7,
        });
        let bytes = vault.to_bytes().unwrap();
        let decoded = Vault::from_bytes(&bytes).unwrap();
        assert_eq!(decoded.sync_config, vault.sync_config);

        let debug = format!("{:?}", decoded.sync_config.as_ref().unwrap());
        assert!(debug.contains("[REDACTED]"));
        assert!(!debug.contains("33333333"));
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

    #[test]
    fn zeroize_secrets_clears_every_secret_field() {
        let mut entry = Entry::login(
            "Mail",
            Login {
                password: "hunter2".into(),
                totp: Some(TotpConfig::new("JBSWY3DPEHPK3PXP")),
                password_history: vec![PasswordHistoryEntry {
                    password: "old".into(),
                    changed_at: 0,
                }],
                ..login("hunter2")
            },
        );
        entry.notes = "recovery codes".into();
        entry.custom_fields = vec![
            CustomField::new("PIN", "1234", CustomFieldKind::Hidden),
            CustomField::new("Public", "visible", CustomFieldKind::Text),
            CustomField::new("Site", "https://x.example", CustomFieldKind::Url),
        ];
        entry.zeroize_secrets();
        assert!(entry.notes.is_empty());
        let EntryBody::Login(login) = &entry.body else {
            panic!("expected login");
        };
        assert!(login.password.is_empty());
        assert!(login.password_history.iter().all(|h| h.password.is_empty()));
        assert!(login.totp.as_ref().unwrap().secret.is_empty());
        assert!(
            entry.custom_fields[0].value.is_empty(),
            "hidden custom field must be wiped"
        );
        assert_eq!(entry.custom_fields[1].value, "visible");
        assert_eq!(entry.custom_fields[2].value, "https://x.example");

        let mut card = Entry::card(
            "Visa",
            Card {
                number: "4111111111111111".into(),
                cvv: "123".into(),
                ..Card::default()
            },
        );
        card.zeroize_secrets();
        let EntryBody::Card(card) = &card.body else {
            panic!("expected card");
        };
        assert!(card.number.is_empty());
        assert!(card.cvv.is_empty());

        let mut note = Entry::note(
            "Note",
            Note {
                content: "top secret".into(),
            },
        );
        note.zeroize_secrets();
        let EntryBody::Note(note) = &note.body else {
            panic!("expected note");
        };
        assert!(note.content.is_empty());
    }

    #[test]
    fn passkey_entry_round_trips_and_zeroizes_secrets() {
        let mut vault = Vault::new();
        let passkey = Passkey {
            rp_id: "example.com".into(),
            rp_name: "Example".into(),
            credential_id: vec![1, 2, 3, 4],
            user_handle: vec![9, 8, 7],
            user_name: "ada".into(),
            user_display_name: "Ada Lovelace".into(),
            public_key: vec![5, 6, 7],
            private_key: vec![0xAA, 0xBB, 0xCC],
            algorithm: -7,
            sign_count: 3,
            created_at: 1_700_000_000,
            last_used_at: Some(1_700_000_100),
            transports: vec!["internal".into(), "hybrid".into()],
            discoverable: true,
        };
        let entry = Entry::passkey("Example login", passkey.clone());
        assert_eq!(entry.kind(), EntryKind::Passkey);
        assert!(!entry.has_totp());
        let summary = entry.summary();
        assert_eq!(summary.subtitle, "ada");

        let id = vault.add_entry(entry);
        let bytes = vault.to_bytes().unwrap();
        let decoded = Vault::from_bytes(&bytes).unwrap();
        assert_eq!(decoded.schema_version, VAULT_SCHEMA_VERSION);
        let stored = decoded.entry(id).unwrap();
        let EntryBody::Passkey(stored_pk) = &stored.body else {
            panic!("expected passkey body");
        };
        assert_eq!(stored_pk, &passkey);

        // Search matches non-secret RP/user metadata.
        assert!(stored.matches_normalized(&crate::vault::index::normalize("example.com")));
        assert!(stored.matches_normalized(&crate::vault::index::normalize("Example login")));
        assert!(stored.matches_normalized(&crate::vault::index::normalize("ada")));
        assert!(stored.matches_normalized(&crate::vault::index::normalize("lovelace")));
        // Must not match secret key material.
        assert!(!stored.matches_normalized(&crate::vault::index::normalize("aabbcc")));

        let mut wiped = stored.clone();
        wiped.zeroize_secrets();
        let EntryBody::Passkey(wiped_pk) = &wiped.body else {
            panic!("expected passkey body");
        };
        assert!(
            wiped_pk.private_key.is_empty(),
            "private key must be zeroized"
        );
        assert!(
            wiped_pk.user_handle.is_empty(),
            "user handle must be zeroized"
        );
        assert_eq!(wiped_pk.credential_id, vec![1, 2, 3, 4]);
        assert_eq!(wiped_pk.public_key, vec![5, 6, 7]);
        assert_eq!(wiped_pk.rp_id, "example.com");
    }

    #[test]
    fn passkey_subtitle_falls_back_safely() {
        let mk = |user_name: &str, display: &str, rp_name: &str, rp_id: &str| {
            Entry::passkey(
                "t",
                Passkey {
                    rp_id: rp_id.into(),
                    rp_name: rp_name.into(),
                    user_name: user_name.into(),
                    user_display_name: display.into(),
                    ..Passkey::default()
                },
            )
            .summary()
            .subtitle
        };
        assert_eq!(mk("ada", "Ada", "Example", "example.com"), "ada");
        assert_eq!(mk("", "Ada", "Example", "example.com"), "Ada");
        assert_eq!(mk("", "", "Example", "example.com"), "Example");
        assert_eq!(mk("", "", "", "example.com"), "example.com");
    }

    #[test]
    fn updating_passkey_does_not_record_password_history() {
        let mut vault = Vault::new();
        let entry = Entry::passkey(
            "Example",
            Passkey {
                rp_id: "example.com".into(),
                user_name: "ada".into(),
                ..Passkey::default()
            },
        );
        let id = vault.add_entry(entry.clone());
        let mut updated = entry;
        updated.title = "Renamed".into();
        if let EntryBody::Passkey(pk) = &mut updated.body {
            pk.sign_count = 5;
        }
        vault.update_entry(updated).unwrap();
        let stored = vault.entry(id).unwrap();
        assert_eq!(stored.title, "Renamed");
        let EntryBody::Passkey(pk) = &stored.body else {
            panic!("passkey");
        };
        assert_eq!(pk.sign_count, 5);
    }

    fn sync_enabled_vault() -> (Vault, [u8; 16]) {
        let mut vault = Vault::new();
        let device = [7u8; 16];
        vault.sync_config = Some(SyncConfig {
            enabled: true,
            sync_id: [1u8; 16],
            device_id: device,
            sync_key: [3u8; 32],
            folder_hint: "hint".into(),
            last_sync_at: 0,
            sequence: 0,
        });
        (vault, device)
    }

    #[test]
    fn sync_bumps_version_on_local_mutations() {
        let (mut vault, device) = sync_enabled_vault();
        let entry = Entry::note(
            "n",
            Note {
                content: "x".into(),
            },
        );
        let id = vault.add_entry(entry.clone());
        assert_eq!(vault.entry(id).unwrap().sync_meta.version.get(&device), 1);
        assert_eq!(vault.entry(id).unwrap().sync_meta.updated_by, device);

        let mut updated = vault.entry(id).unwrap().clone();
        updated.title = "n2".into();
        vault.update_entry(updated).unwrap();
        assert_eq!(vault.entry(id).unwrap().sync_meta.version.get(&device), 2);

        vault.delete_entry(id).unwrap();
        assert_eq!(vault.entry(id).unwrap().sync_meta.version.get(&device), 3);
        vault.restore_entry(id).unwrap();
        assert_eq!(vault.entry(id).unwrap().sync_meta.version.get(&device), 4);

        let folder = vault.add_folder("Work");
        assert_eq!(vault.folders[0].sync_meta.version.get(&device), 1);
        vault.rename_folder(folder, "Office").unwrap();
        assert_eq!(vault.folders[0].sync_meta.version.get(&device), 2);
    }

    #[test]
    fn sync_purge_and_folder_delete_emit_tombstones() {
        let (mut vault, device) = sync_enabled_vault();
        let id = vault.add_entry(Entry::note("n", Note::default()));
        vault.purge_entry(id).unwrap();
        assert!(vault.entry(id).is_none());
        assert_eq!(vault.tombstones.len(), 1);
        assert_eq!(vault.tombstones[0].id, id);
        assert_eq!(vault.tombstones[0].kind, TombstoneKind::Entry);
        assert!(vault.tombstones[0].purged_at.is_some());
        assert_eq!(vault.tombstones[0].version.get(&device), 2); // add + purge

        let folder = vault.add_folder("F");
        let mut e = Entry::note("in", Note::default());
        e.folder_id = Some(folder);
        let eid = vault.add_entry(e);
        let folder_ver = vault.folders[0].sync_meta.version.clone();
        vault.delete_folder(folder).unwrap();
        assert!(vault.folders.is_empty());
        assert_eq!(vault.entry(eid).unwrap().folder_id, None);
        assert!(vault.entry(eid).unwrap().sync_meta.version.get(&device) >= 2);
        let folder_tombstone = vault
            .tombstones
            .iter()
            .find(|t| t.id == folder)
            .expect("folder tombstone");
        assert_eq!(folder_tombstone.kind, TombstoneKind::Folder);
        assert!(folder_tombstone.version.dominates(&folder_ver));
    }

    #[test]
    fn sync_purge_expired_prunes_old_tombstones() {
        let (mut vault, device) = sync_enabled_vault();
        let id = vault.add_entry(Entry::note("n", Note::default()));
        vault.delete_entry(id).unwrap();
        let now = now_unix();
        vault.entry_mut(id).unwrap().deleted_at = Some(now - TRASH_RETENTION_SECS - 1);
        assert_eq!(vault.purge_expired(now), 1);
        assert_eq!(vault.tombstones.len(), 1);
        assert_eq!(vault.tombstones[0].kind, TombstoneKind::Entry);

        // Old tombstones are dropped after retention.
        vault.tombstones[0].purged_at = Some(now - TOMBSTONE_RETENTION_SECS - 1);
        assert_eq!(vault.purge_expired(now), 0);
        assert!(vault.tombstones.is_empty());
        let _ = device;
    }
}
