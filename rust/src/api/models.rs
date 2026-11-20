//! DTOs exchanged with Dart.
//!
//! List and detail views deliberately contain **no secrets**. The only bridge
//! function that returns a secret value is
//! [`crate::api::entries::reveal_field`], and only for the requested field.

use keyel_core::autofill::{AutofillMatch, MatchQuality};
use keyel_core::health::{HealthIssue, HealthReport};
use keyel_core::import::{ImportFailure, ImportFormat, ImportMode, ImportReport, ParsedImport};
use keyel_core::sync::{SyncReport as CoreSyncReport, SyncStatus as CoreSyncStatus};
use keyel_core::vault::{
    Card, CustomField, CustomFieldKind, Entry, EntryBody, EntryKind, EntrySummary, Login, Note,
    TotpAlgorithm, TotpConfig,
};
use uuid::Uuid;

/// What kind of secret an entry holds.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EntryKindDto {
    /// Username/password/URL entry.
    Login,
    /// Payment card entry.
    Card,
    /// Free-form secure note.
    Note,
    /// WebAuthn/FIDO2 passkey credential.
    Passkey,
}

impl From<EntryKind> for EntryKindDto {
    fn from(kind: EntryKind) -> Self {
        match kind {
            EntryKind::Login => Self::Login,
            EntryKind::Card => Self::Card,
            EntryKind::Note => Self::Note,
            EntryKind::Passkey => Self::Passkey,
        }
    }
}

impl From<EntryKindDto> for EntryKind {
    fn from(kind: EntryKindDto) -> Self {
        match kind {
            EntryKindDto::Login => Self::Login,
            EntryKindDto::Card => Self::Card,
            EntryKindDto::Note => Self::Note,
            EntryKindDto::Passkey => Self::Passkey,
        }
    }
}

/// TOTP hash algorithm.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TotpAlgorithmDto {
    /// SHA-1.
    Sha1,
    /// SHA-256.
    Sha256,
    /// SHA-512.
    Sha512,
}

impl From<TotpAlgorithm> for TotpAlgorithmDto {
    fn from(algorithm: TotpAlgorithm) -> Self {
        match algorithm {
            TotpAlgorithm::Sha1 => Self::Sha1,
            TotpAlgorithm::Sha256 => Self::Sha256,
            TotpAlgorithm::Sha512 => Self::Sha512,
        }
    }
}

/// A secret that can be requested with `reveal_field`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SecretFieldDto {
    /// The login password.
    LoginPassword,
    /// The login TOTP shared secret.
    LoginTotpSecret,
    /// The card number.
    CardNumber,
    /// The card security code.
    CardCvv,
    /// The secure-note body.
    NoteContent,
    /// The free-form notes stored on the entry itself.
    EntryNotes,
}

/// A secret-free row for lists.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntrySummaryDto {
    /// Stable identifier (UUID v7).
    pub id: String,
    /// Entry kind.
    pub kind: EntryKindDto,
    /// Entry title.
    pub title: String,
    /// Secondary line (username, URL, brand, ...). Never a password.
    pub subtitle: String,
    /// Favorite flag.
    pub favorite: bool,
    /// Folder, if any.
    pub folder_id: Option<String>,
    /// Optional user-chosen icon key, if set.
    pub icon: Option<String>,
    /// Whether the entry has TOTP configured.
    pub has_totp: bool,
    /// Trash marker, if soft-deleted (Unix seconds).
    pub deleted_at: Option<u64>,
}

impl From<EntrySummary> for EntrySummaryDto {
    fn from(summary: EntrySummary) -> Self {
        Self {
            id: summary.id.to_string(),
            kind: summary.kind.into(),
            title: summary.title,
            subtitle: summary.subtitle,
            favorite: summary.favorite,
            folder_id: summary.folder_id.map(|id| id.to_string()),
            icon: summary.icon,
            has_totp: summary.has_totp,
            deleted_at: summary.deleted_at,
        }
    }
}

/// Non-secret login fields. Secrets are exposed only as presence flags.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoginDetailDto {
    /// Username or email address.
    pub username: String,
    /// Website URL.
    pub url: String,
    /// Whether a password is stored.
    pub has_password: bool,
    /// Number of previous passwords kept in history.
    pub password_history_count: u32,
    /// TOTP algorithm, if configured.
    pub totp_algorithm: Option<TotpAlgorithmDto>,
    /// TOTP digits, if configured.
    pub totp_digits: Option<u8>,
    /// TOTP period in seconds, if configured.
    pub totp_period: Option<u32>,
}

/// Non-secret card fields. Secrets are exposed only as presence flags.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CardDetailDto {
    /// Name printed on the card.
    pub cardholder: String,
    /// Expiry as free text (`MM/YY`).
    pub expiry: String,
    /// Optional brand name.
    pub brand: Option<String>,
    /// Whether a card number is stored.
    pub has_number: bool,
    /// Whether a security code is stored.
    pub has_cvv: bool,
}

/// Note metadata. The content itself is revealed explicitly.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NoteDetailDto {
    /// Whether the note body is non-empty.
    pub has_content: bool,
}

/// The value kind of a user-defined custom field.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CustomFieldKindDto {
    /// Plain text. Safe to show and searchable as metadata.
    Text,
    /// Secret text. Masked and never indexed.
    Hidden,
    /// A URL. Treated as non-secret metadata.
    Url,
}

impl From<CustomFieldKind> for CustomFieldKindDto {
    fn from(kind: CustomFieldKind) -> Self {
        match kind {
            CustomFieldKind::Text => Self::Text,
            CustomFieldKind::Hidden => Self::Hidden,
            CustomFieldKind::Url => Self::Url,
        }
    }
}

impl From<CustomFieldKindDto> for CustomFieldKind {
    fn from(kind: CustomFieldKindDto) -> Self {
        match kind {
            CustomFieldKindDto::Text => Self::Text,
            CustomFieldKindDto::Hidden => Self::Hidden,
            CustomFieldKindDto::Url => Self::Url,
        }
    }
}

/// A user-defined custom field with secrets masked.
///
/// Hidden field values are never included; request them via
/// `reveal_custom_field`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CustomFieldDetailDto {
    /// Stable identifier.
    pub id: String,
    /// User-visible label.
    pub label: String,
    /// How the value should be interpreted and displayed.
    pub kind: CustomFieldKindDto,
    /// Non-secret value. Always empty for hidden fields.
    pub value: String,
    /// Whether a hidden value is stored (always `false` for non-hidden).
    pub has_hidden_value: bool,
}

impl From<&CustomField> for CustomFieldDetailDto {
    fn from(field: &CustomField) -> Self {
        let secret = field.is_secret();
        Self {
            id: field.id.to_string(),
            label: field.label.clone(),
            kind: field.kind.into(),
            value: if secret {
                String::new()
            } else {
                field.value.clone()
            },
            has_hidden_value: secret && !field.value.is_empty(),
        }
    }
}

/// A user-defined custom field to create or update.
#[derive(Clone, PartialEq, Eq)]
pub struct CustomFieldDraft {
    /// Existing field id to update; `None` creates a new field.
    pub id: Option<String>,
    /// User-visible label.
    pub label: String,
    /// How the value should be interpreted and displayed.
    pub kind: CustomFieldKindDto,
    /// Field value. For hidden fields, `None` keeps the existing secret when
    /// updating a field with the same id.
    pub value: Option<String>,
}

impl std::fmt::Debug for CustomFieldDraft {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("CustomFieldDraft")
            .field("id", &self.id)
            .field("label", &self.label)
            .field("kind", &self.kind)
            .field("value", &self.value.as_ref().map(|_| "[REDACTED]"))
            .finish()
    }
}

/// Non-secret passkey metadata. Private key material is never exposed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PasskeyDetailDto {
    /// Relying Party identifier (e.g. `example.com`).
    pub rp_id: String,
    /// Human-readable relying party name.
    pub rp_name: String,
    /// Account/user name.
    pub user_name: String,
    /// Display name for the account/user.
    pub user_display_name: String,
    /// Credential identifier, base64url-encoded for display/copy.
    pub credential_id: String,
    /// COSE algorithm identifier (e.g. -7 ES256, -257 RS256, -8 EdDSA).
    pub algorithm: i32,
    /// Signature counter.
    pub sign_count: u32,
    /// When this credential was created (Unix seconds).
    pub created_at: u64,
    /// When this credential was last used (Unix seconds), if known.
    pub last_used_at: Option<u64>,
    /// Transport hints.
    pub transports: Vec<String>,
    /// Whether the credential is discoverable/resident.
    pub discoverable: bool,
}

/// A single entry with masked secrets.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EntryDetailDto {
    /// Stable identifier.
    pub id: String,
    /// Entry kind.
    pub kind: EntryKindDto,
    /// Entry title.
    pub title: String,
    /// User-defined tags.
    pub tags: Vec<String>,
    /// Folder, if any.
    pub folder_id: Option<String>,
    /// Favorite flag.
    pub favorite: bool,
    /// Optional user-chosen icon key, if set.
    pub icon: Option<String>,
    /// Creation time (Unix seconds).
    pub created_at: u64,
    /// Last modification time (Unix seconds).
    pub updated_at: u64,
    /// Trash marker, if soft-deleted.
    pub deleted_at: Option<u64>,
    /// Whether the entry has free-form notes.
    pub has_notes: bool,
    /// Login fields, when this is a login.
    pub login: Option<LoginDetailDto>,
    /// Card fields, when this is a card.
    pub card: Option<CardDetailDto>,
    /// Note metadata, when this is a note.
    pub note: Option<NoteDetailDto>,
    /// Passkey fields, when this is a passkey.
    pub passkey: Option<PasskeyDetailDto>,
    /// User-defined extra fields, in display order.
    pub custom_fields: Vec<CustomFieldDetailDto>,
}

impl From<&Entry> for EntryDetailDto {
    fn from(entry: &Entry) -> Self {
        let (login, card, note, passkey) = match &entry.body {
            EntryBody::Login(login) => (
                Some(LoginDetailDto {
                    username: login.username.clone(),
                    url: login.url.clone(),
                    has_password: !login.password.is_empty(),
                    password_history_count: login.password_history.len() as u32,
                    totp_algorithm: login.totp.as_ref().map(|totp| totp.algorithm.into()),
                    totp_digits: login.totp.as_ref().map(|totp| totp.digits),
                    totp_period: login.totp.as_ref().map(|totp| totp.period),
                }),
                None,
                None,
                None,
            ),
            EntryBody::Card(card) => (
                None,
                Some(CardDetailDto {
                    cardholder: card.cardholder.clone(),
                    expiry: card.expiry.clone(),
                    brand: card.brand.clone(),
                    has_number: !card.number.is_empty(),
                    has_cvv: !card.cvv.is_empty(),
                }),
                None,
                None,
            ),
            EntryBody::Note(note) => (
                None,
                None,
                Some(NoteDetailDto {
                    has_content: !note.content.is_empty(),
                }),
                None,
            ),
            EntryBody::Passkey(passkey) => (
                None,
                None,
                None,
                Some(PasskeyDetailDto {
                    rp_id: passkey.rp_id.clone(),
                    rp_name: passkey.rp_name.clone(),
                    user_name: passkey.user_name.clone(),
                    user_display_name: passkey.user_display_name.clone(),
                    credential_id: data_encoding::BASE64URL_NOPAD.encode(&passkey.credential_id),
                    algorithm: passkey.algorithm,
                    sign_count: passkey.sign_count,
                    created_at: passkey.created_at,
                    last_used_at: passkey.last_used_at,
                    transports: passkey.transports.clone(),
                    discoverable: passkey.discoverable,
                }),
            ),
        };

        Self {
            id: entry.id.to_string(),
            kind: entry.kind().into(),
            title: entry.title.clone(),
            tags: entry.tags.clone(),
            folder_id: entry.folder_id.map(|id| id.to_string()),
            favorite: entry.favorite,
            icon: entry.icon.clone(),
            created_at: entry.created_at,
            updated_at: entry.updated_at,
            deleted_at: entry.deleted_at,
            has_notes: !entry.notes.is_empty(),
            login,
            card,
            note,
            passkey,
            custom_fields: entry
                .custom_fields
                .iter()
                .map(CustomFieldDetailDto::from)
                .collect(),
        }
    }
}

/// Input used to create or update an entry.
///
/// Secret fields are optional: `None` keeps the existing value when `id`
/// points at an entry, and means "empty" for a new entry. This lets an editor
/// save masked fields without ever receiving their plaintext.
#[derive(Clone, PartialEq, Eq)]
pub struct EntryDraft {
    /// Existing entry to update; `None` creates a new entry.
    pub id: Option<String>,
    /// Entry kind.
    pub kind: EntryKindDto,
    /// User-visible title.
    pub title: String,
    /// Free-form notes. `None` keeps the existing notes on update.
    pub notes: Option<String>,
    /// User-defined tags.
    pub tags: Vec<String>,
    /// Folder, if any.
    pub folder_id: Option<String>,
    /// Favorite flag.
    pub favorite: bool,
    /// Optional user-chosen icon key.
    pub icon: Option<String>,
    /// Login username.
    pub username: String,
    /// Login password. `None` keeps the existing password on update.
    pub password: Option<String>,
    /// Login URL.
    pub url: String,
    /// TOTP shared secret. `None` keeps the existing secret on update.
    pub totp_secret: Option<String>,
    /// TOTP algorithm.
    pub totp_algorithm: TotpAlgorithmDto,
    /// TOTP digits.
    pub totp_digits: u8,
    /// TOTP period in seconds.
    pub totp_period: u32,
    /// Cardholder name.
    pub cardholder: String,
    /// Card number. `None` keeps the existing number on update.
    pub card_number: Option<String>,
    /// Card expiry (`MM/YY`).
    pub card_expiry: String,
    /// Card security code. `None` keeps the existing code on update.
    pub card_cvv: Option<String>,
    /// Optional card brand.
    pub card_brand: Option<String>,
    /// Secure-note body. `None` keeps the existing content on update.
    pub note_content: Option<String>,
    /// User-defined custom fields, in display order.
    pub custom_fields: Vec<CustomFieldDraft>,
}

impl std::fmt::Debug for EntryDraft {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        // Drafts cross the bridge with plaintext values. Debug output must
        // never become a side channel (threat model T3).
        let redacted = |value: &Option<String>| value.as_ref().map(|_| "[REDACTED]");
        f.debug_struct("EntryDraft")
            .field("id", &self.id)
            .field("kind", &self.kind)
            .field("title", &self.title)
            .field("notes", &redacted(&self.notes))
            .field("tags", &self.tags)
            .field("folder_id", &self.folder_id)
            .field("favorite", &self.favorite)
            .field("icon", &self.icon)
            .field("username", &self.username)
            .field("password", &redacted(&self.password))
            .field("url", &self.url)
            .field("totp_secret", &redacted(&self.totp_secret))
            .field("totp_algorithm", &self.totp_algorithm)
            .field("totp_digits", &self.totp_digits)
            .field("totp_period", &self.totp_period)
            .field("cardholder", &self.cardholder)
            .field("card_number", &redacted(&self.card_number))
            .field("card_expiry", &self.card_expiry)
            .field("card_cvv", &redacted(&self.card_cvv))
            .field("card_brand", &self.card_brand)
            .field("note_content", &redacted(&self.note_content))
            .field("custom_fields", &self.custom_fields)
            .finish()
    }
}

/// Resolve custom-field drafts against existing fields, preserving hidden
/// secrets when a draft value is omitted for the same field id.
pub(crate) fn map_custom_fields(
    drafts: Vec<CustomFieldDraft>,
    existing: &[CustomField],
) -> Vec<CustomField> {
    drafts
        .into_iter()
        .map(|draft| {
            let id = draft.id.as_deref().and_then(|id| Uuid::parse_str(id).ok());
            let previous = id.and_then(|id| existing.iter().find(|field| field.id == id));
            let kind: CustomFieldKind = draft.kind.into();
            let value = match draft.value {
                Some(value) => value,
                None if matches!(kind, CustomFieldKind::Hidden) => previous
                    .filter(|field| field.is_secret())
                    .map(|field| field.value.clone())
                    .unwrap_or_default(),
                None => previous
                    .filter(|field| !field.is_secret())
                    .map(|field| field.value.clone())
                    .unwrap_or_default(),
            };
            CustomField {
                id: id.unwrap_or_else(Uuid::now_v7),
                label: draft.label,
                value,
                kind,
            }
        })
        .collect()
}

impl EntryDraft {
    /// Build a login entry from a draft, preserving secrets from `existing`
    /// when their inputs are `None`.
    pub(crate) fn into_login(self, existing: Option<&Login>) -> Login {
        let previous = existing.cloned().unwrap_or_default();
        let password = self.password.unwrap_or(previous.password);
        let totp = match self.totp_secret {
            Some(secret) if !secret.is_empty() => Some(TotpConfig {
                secret,
                algorithm: self.totp_algorithm.into(),
                digits: self.totp_digits.clamp(4, 10),
                period: self.totp_period.max(1),
            }),
            Some(_) => None,
            None => previous.totp,
        };
        Login {
            username: self.username,
            password,
            url: self.url,
            totp,
            password_history: previous.password_history,
        }
    }

    /// Build a card entry, preserving secrets from `existing`.
    pub(crate) fn into_card(self, existing: Option<&Card>) -> Card {
        let previous = existing.cloned().unwrap_or_default();
        Card {
            cardholder: self.cardholder,
            number: self.card_number.unwrap_or(previous.number),
            expiry: self.card_expiry,
            cvv: self.card_cvv.unwrap_or(previous.cvv),
            brand: self.card_brand,
        }
    }

    /// Build a note entry, preserving content from `existing`.
    pub(crate) fn into_note(self, existing: Option<&Note>) -> Note {
        let previous = existing.cloned().unwrap_or_default();
        Note {
            content: self.note_content.unwrap_or(previous.content),
        }
    }
}

impl From<TotpAlgorithmDto> for TotpAlgorithm {
    fn from(algorithm: TotpAlgorithmDto) -> Self {
        match algorithm {
            TotpAlgorithmDto::Sha1 => Self::Sha1,
            TotpAlgorithmDto::Sha256 => Self::Sha256,
            TotpAlgorithmDto::Sha512 => Self::Sha512,
        }
    }
}

/// A folder in the vault.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FolderDto {
    /// Stable identifier.
    pub id: String,
    /// Display name.
    pub name: String,
    /// Zero-based position.
    pub order: u32,
}

/// TOTP parameters parsed from an `otpauth://` URI or a typed secret.
///
/// Unlike the vault DTOs this carries the shared secret, because the caller
/// supplied it (scanned or typed) and needs it back to save the entry.
#[derive(Clone, PartialEq, Eq)]
pub struct TotpConfigDto {
    /// Normalised base32 secret.
    pub secret: String,
    /// Hash algorithm.
    pub algorithm: TotpAlgorithmDto,
    /// Number of digits.
    pub digits: u8,
    /// Time step in seconds.
    pub period: u32,
}

impl std::fmt::Debug for TotpConfigDto {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("TotpConfigDto")
            .field("secret", &"[REDACTED]")
            .field("algorithm", &self.algorithm)
            .field("digits", &self.digits)
            .field("period", &self.period)
            .finish()
    }
}

/// A live one-time code for an entry.
#[derive(Clone, PartialEq, Eq)]
pub struct TotpCodeDto {
    /// The zero-padded numeric code.
    pub code: String,
    /// Seconds until the code rolls over.
    pub seconds_left: u32,
    /// The configured period, for the countdown ring.
    pub period: u32,
}

impl std::fmt::Debug for TotpCodeDto {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("TotpCodeDto")
            .field("code", &"[REDACTED]")
            .field("seconds_left", &self.seconds_left)
            .field("period", &self.period)
            .finish()
    }
}

/// A secret-free reference to an affected entry in a health report.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HealthIssueDto {
    /// Stable entry id.
    pub id: String,
    /// Entry title.
    pub title: String,
    /// Secondary line (username or URL). Never a password.
    pub subtitle: String,
}

impl From<HealthIssue> for HealthIssueDto {
    fn from(issue: HealthIssue) -> Self {
        Self {
            id: issue.id.to_string(),
            title: issue.title,
            subtitle: issue.subtitle,
        }
    }
}

/// Entries that share one password.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReuseGroupDto {
    /// The entries in this group.
    pub entries: Vec<HealthIssueDto>,
}

/// A secret-free vault health report.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HealthReportDto {
    /// Overall health score, `0..=100`.
    pub score: u8,
    /// Number of login entries considered.
    pub total_logins: u32,
    /// Entries whose password is weak.
    pub weak: Vec<HealthIssueDto>,
    /// Groups of entries that share a password.
    pub reused: Vec<ReuseGroupDto>,
    /// Entries whose password is over a year old.
    pub old: Vec<HealthIssueDto>,
    /// Entries without two-factor authentication.
    pub no_two_factor: Vec<HealthIssueDto>,
    /// Entries whose website uses plain HTTP.
    pub insecure_url: Vec<HealthIssueDto>,
}

impl From<HealthReport> for HealthReportDto {
    fn from(report: HealthReport) -> Self {
        Self {
            score: report.score,
            total_logins: report.total_logins,
            weak: report.weak.into_iter().map(HealthIssueDto::from).collect(),
            reused: report
                .reused
                .into_iter()
                .map(|group| ReuseGroupDto {
                    entries: group
                        .entries
                        .into_iter()
                        .map(HealthIssueDto::from)
                        .collect(),
                })
                .collect(),
            old: report.old.into_iter().map(HealthIssueDto::from).collect(),
            no_two_factor: report
                .no_two_factor
                .into_iter()
                .map(HealthIssueDto::from)
                .collect(),
            insecure_url: report
                .insecure_url
                .into_iter()
                .map(HealthIssueDto::from)
                .collect(),
        }
    }
}

/// A third-party CSV export format the importer understands.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImportFormatDto {
    /// Bitwarden individual or organization CSV export.
    Bitwarden,
    /// Google Chrome / Chromium password CSV export.
    Chrome,
}

impl From<ImportFormat> for ImportFormatDto {
    fn from(format: ImportFormat) -> Self {
        match format {
            ImportFormat::Bitwarden => Self::Bitwarden,
            ImportFormat::Chrome => Self::Chrome,
        }
    }
}

/// How imported data combines with the live vault.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImportModeDto {
    /// Add what is missing and keep the existing vault.
    Merge,
    /// Replace the vault contents with the imported data.
    Replace,
}

impl From<ImportModeDto> for ImportMode {
    fn from(mode: ImportModeDto) -> Self {
        match mode {
            ImportModeDto::Merge => Self::Merge,
            ImportModeDto::Replace => Self::Replace,
        }
    }
}

/// One row that could not be imported, with a non-secret reason.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportFailureDto {
    /// 1-based row number in the source file, counting the header as row 1.
    pub row: u32,
    /// Short explanation. Never contains secret material.
    pub reason: String,
}

impl From<ImportFailure> for ImportFailureDto {
    fn from(failure: ImportFailure) -> Self {
        Self {
            row: failure.row,
            reason: failure.reason,
        }
    }
}

/// What an import file contains, shown before the user commits to it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportPreviewDto {
    /// The detected source format.
    pub format: ImportFormatDto,
    /// Number of entries that will be imported.
    pub total: u32,
    /// Login entries.
    pub logins: u32,
    /// Card entries.
    pub cards: u32,
    /// Secure notes.
    pub notes: u32,
    /// Rows that could not be parsed.
    pub failures: Vec<ImportFailureDto>,
}

impl From<ParsedImport> for ImportPreviewDto {
    fn from(parsed: ParsedImport) -> Self {
        let mut preview = Self {
            format: parsed.format.into(),
            total: parsed.entries.len() as u32,
            logins: 0,
            cards: 0,
            notes: 0,
            failures: parsed.failed.into_iter().map(Into::into).collect(),
        };
        for parsed_entry in &parsed.entries {
            match parsed_entry.entry.kind() {
                EntryKind::Login => preview.logins += 1,
                EntryKind::Card => preview.cards += 1,
                EntryKind::Note => preview.notes += 1,
                // Passkeys are not produced by CSV imports; keep counts stable.
                EntryKind::Passkey => {}
            }
        }
        preview
    }
}

/// Counts produced by an applied import or restore.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportReportDto {
    /// Entries added to the vault.
    pub added: u32,
    /// Entries skipped because an equivalent one already exists.
    pub skipped: u32,
    /// Rows that could not be imported.
    pub failed: u32,
    /// Imported login count.
    pub logins: u32,
    /// Imported card count.
    pub cards: u32,
    /// Imported note count.
    pub notes: u32,
    /// Folders created for imported entries.
    pub folders_added: u32,
    /// Row-level failures, for display.
    pub failures: Vec<ImportFailureDto>,
}

impl From<ImportReport> for ImportReportDto {
    fn from(report: ImportReport) -> Self {
        Self {
            added: report.added,
            skipped: report.skipped,
            failed: report.failed,
            logins: report.logins,
            cards: report.cards,
            notes: report.notes,
            folders_added: report.folders_added,
            failures: report.failures.into_iter().map(Into::into).collect(),
        }
    }
}

/// How confidently a login matches the autofill request.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AutofillQualityDto {
    /// Same host or same Android package.
    Exact,
    /// Same registrable domain (a subdomain relationship).
    SameSite,
    /// Only a text-search hit; the UI must warn about a possible mismatch.
    Search,
}

impl From<MatchQuality> for AutofillQualityDto {
    fn from(quality: MatchQuality) -> Self {
        match quality {
            MatchQuality::Exact => Self::Exact,
            MatchQuality::SameSite => Self::SameSite,
            MatchQuality::Search => Self::Search,
        }
    }
}

/// A login suggested for autofill, with no secrets attached.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AutofillMatchDto {
    /// Secret-free summary for the picker row.
    pub summary: EntrySummaryDto,
    /// Match strength, used to decide whether to warn the user.
    pub quality: AutofillQualityDto,
}

impl From<AutofillMatch> for AutofillMatchDto {
    fn from(item: AutofillMatch) -> Self {
        Self {
            summary: item.summary.into(),
            quality: item.quality.into(),
        }
    }
}

/// Non-secret sync state for the settings UI. The sync key is never included.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncStatusDto {
    pub enabled: bool,
    /// Hex sync group id, if enabled.
    pub sync_id: Option<String>,
    /// Hex device id, if enabled.
    pub device_id: Option<String>,
    /// Informational folder hint supplied by the user.
    pub folder_hint: String,
    /// Unix seconds of the last successful sync.
    pub last_sync_at: u64,
    /// Monotonic blob sequence of the local device.
    pub sequence: u64,
}

impl From<CoreSyncStatus> for SyncStatusDto {
    fn from(status: CoreSyncStatus) -> Self {
        Self {
            enabled: status.enabled,
            sync_id: status.sync_id,
            device_id: status.device_id,
            folder_hint: status.folder_hint,
            last_sync_at: status.last_sync_at,
            sequence: status.sequence,
        }
    }
}

/// Non-secret outcome of one manual sync.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncReportDto {
    pub pulled_files: u32,
    pub pushed_file: bool,
    pub entries_added: u32,
    pub entries_updated: u32,
    pub folders_added: u32,
    pub folders_updated: u32,
    pub conflicts_created: u32,
    pub tombstones_applied: u32,
    /// Non-secret problems encountered during the sync.
    pub errors: Vec<String>,
}

impl From<CoreSyncReport> for SyncReportDto {
    fn from(report: CoreSyncReport) -> Self {
        Self {
            pulled_files: report.pulled_files as u32,
            pushed_file: report.pushed_file,
            entries_added: report.entries_added as u32,
            entries_updated: report.entries_updated as u32,
            folders_added: report.folders_added as u32,
            folders_updated: report.folders_updated as u32,
            conflicts_created: report.conflicts_created as u32,
            tombstones_applied: report.tombstones_applied as u32,
            errors: report.errors,
        }
    }
}

/// First phase of a breach check: what Dart is allowed to send over the wire.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BreachCheckRequestDto {
    /// Opaque token correlating the fetch phase with the compare phase.
    pub token: String,
    /// Deduplicated 5-character uppercase hex prefixes to query.
    pub prefixes: Vec<String>,
    /// Number of active login passwords examined in Rust.
    pub checked_count: u32,
}

/// One HIBP range response, keyed by the prefix that was requested.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BreachRangeResponseDto {
    /// The 5-character prefix used for this request.
    pub prefix: String,
    /// Raw response body. Dart never hashes or interprets it.
    pub body: String,
}

/// A single entry whose password appeared in a breach corpus.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BreachMatchDto {
    /// Stable entry id.
    pub entry_id: String,
    /// Entry title (non-secret metadata).
    pub entry_title: String,
    /// Number of occurrences reported by HIBP.
    pub count: u32,
}

/// Secret-free outcome of one breach check.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BreachReportDto {
    /// Entries with a breached password.
    pub matches: Vec<BreachMatchDto>,
    /// Number of active login passwords examined in Rust.
    pub checked_count: u32,
    /// Number of distinct prefixes queried.
    pub queried_prefixes: u32,
}

#[cfg(test)]
mod tests {
    use super::*;

    const SENTINEL: &str = "SENTINEL-SUPER-SECRET-12345";

    #[test]
    fn secret_drafts_never_print_secrets_in_debug() {
        let field = CustomFieldDraft {
            id: None,
            label: "CVV".into(),
            kind: CustomFieldKindDto::Hidden,
            value: Some(SENTINEL.into()),
        };
        let totp = TotpConfigDto {
            secret: SENTINEL.into(),
            algorithm: TotpAlgorithmDto::Sha1,
            digits: 6,
            period: 30,
        };
        let code = TotpCodeDto {
            code: SENTINEL.into(),
            seconds_left: 10,
            period: 30,
        };
        let draft = EntryDraft {
            id: None,
            kind: EntryKindDto::Login,
            title: "Bank".into(),
            notes: Some(SENTINEL.into()),
            tags: Vec::new(),
            folder_id: None,
            favorite: false,
            icon: None,
            username: "ada".into(),
            password: Some(SENTINEL.into()),
            url: "https://example.com".into(),
            totp_secret: Some(SENTINEL.into()),
            totp_algorithm: TotpAlgorithmDto::Sha1,
            totp_digits: 6,
            totp_period: 30,
            cardholder: String::new(),
            card_number: Some(SENTINEL.into()),
            card_expiry: String::new(),
            card_cvv: Some(SENTINEL.into()),
            card_brand: None,
            note_content: Some(SENTINEL.into()),
            custom_fields: vec![field],
        };

        for debug in [
            format!("{:?}", draft.custom_fields[0]),
            format!("{totp:?}"),
            format!("{code:?}"),
            format!("{draft:?}"),
        ] {
            assert!(!debug.contains(SENTINEL), "secret leaked: {debug}");
            assert!(debug.contains("[REDACTED]"), "missing marker: {debug}");
        }
    }
}
