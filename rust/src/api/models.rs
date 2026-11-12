//! DTOs exchanged with Dart.
//!
//! List and detail views deliberately contain **no secrets**. The only bridge
//! function that returns a secret value is
//! [`crate::api::entries::reveal_field`], and only for the requested field.

use keyel_core::health::{HealthIssue, HealthReport};
use keyel_core::import::{ImportFailure, ImportFormat, ImportMode, ImportReport, ParsedImport};
use keyel_core::vault::{
    Card, Entry, EntryBody, EntryKind, EntrySummary, Login, Note, TotpAlgorithm, TotpConfig,
};

/// What kind of secret an entry holds.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EntryKindDto {
    /// Username/password/URL entry.
    Login,
    /// Payment card entry.
    Card,
    /// Free-form secure note.
    Note,
}

impl From<EntryKind> for EntryKindDto {
    fn from(kind: EntryKind) -> Self {
        match kind {
            EntryKind::Login => Self::Login,
            EntryKind::Card => Self::Card,
            EntryKind::Note => Self::Note,
        }
    }
}

impl From<EntryKindDto> for EntryKind {
    fn from(kind: EntryKindDto) -> Self {
        match kind {
            EntryKindDto::Login => Self::Login,
            EntryKindDto::Card => Self::Card,
            EntryKindDto::Note => Self::Note,
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
}

impl From<&Entry> for EntryDetailDto {
    fn from(entry: &Entry) -> Self {
        let (login, card, note) = match &entry.body {
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
            ),
            EntryBody::Note(note) => (
                None,
                None,
                Some(NoteDetailDto {
                    has_content: !note.content.is_empty(),
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
            created_at: entry.created_at,
            updated_at: entry.updated_at,
            deleted_at: entry.deleted_at,
            has_notes: !entry.notes.is_empty(),
            login,
            card,
            note,
        }
    }
}

/// Input used to create or update an entry.
///
/// Secret fields are optional: `None` keeps the existing value when `id`
/// points at an entry, and means "empty" for a new entry. This lets an editor
/// save masked fields without ever receiving their plaintext.
#[derive(Debug, Clone, PartialEq, Eq)]
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
#[derive(Debug, Clone, PartialEq, Eq)]
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

/// A live one-time code for an entry.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TotpCodeDto {
    /// The zero-padded numeric code.
    pub code: String,
    /// Seconds until the code rolls over.
    pub seconds_left: u32,
    /// The configured period, for the countdown ring.
    pub period: u32,
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
