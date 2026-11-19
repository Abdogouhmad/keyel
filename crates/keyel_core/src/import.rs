//! Import entries from third-party password-manager CSV exports.
//!
//! Two formats are supported: **Bitwarden** (`folder,favorite,type,name,notes,
//! fields,reprompt,login_uri,login_username,login_password,login_totp`, and the
//! organization variant with `collections`) and **Chrome**
//! (`name,url,username,password,note`).
//!
//! Parsing is pure: it turns a CSV document into a list of [`Entry`] values
//! plus a list of row-level failures. Applying those entries to a vault — with
//! duplicate detection and a merge/replace choice — is a separate step, so the
//! UI can preview an import before it changes anything.

use std::collections::{HashMap, HashSet};

use uuid::Uuid;

use crate::csv;
use crate::totp;
use crate::vault::{
    CustomField, CustomFieldKind, Entry, EntryBody, EntryKind, Login, Note, TotpConfig, Vault,
};

/// A CSV export format this importer understands.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImportFormat {
    /// Bitwarden individual or organization CSV export.
    Bitwarden,
    /// Google Chrome / Chromium password CSV export.
    Chrome,
}

/// How imported entries combine with the existing vault.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImportMode {
    /// Add entries that are not already present, keeping the current ones.
    Merge,
    /// Replace the vault contents with the imported entries.
    Replace,
}

/// Why one row was not imported (or was imported with a caveat).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportFailure {
    /// 1-based row number in the source file, counting the header as row 1.
    pub row: u32,
    /// Short, non-secret explanation.
    pub reason: String,
}

/// One entry parsed from a file, with the folder it belonged to.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedEntry {
    /// The entry itself.
    pub entry: Entry,
    /// Folder name from the export, if any.
    pub folder: Option<String>,
}

/// A parsed import, before it touches the vault.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedImport {
    /// The detected source format.
    pub format: ImportFormat,
    /// Entries ready to be applied.
    pub entries: Vec<ParsedEntry>,
    /// Rows that could not be imported.
    pub failed: Vec<ImportFailure>,
}

/// Counts produced by an import.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImportReport {
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
    pub failures: Vec<ImportFailure>,
}

impl ImportReport {
    /// Count one entry by kind.
    pub fn record(&mut self, entry: &Entry) {
        match entry.kind() {
            EntryKind::Login => self.logins += 1,
            EntryKind::Card => self.cards += 1,
            EntryKind::Note => self.notes += 1,
            // Passkeys are not representable in the supported CSV formats.
            EntryKind::Passkey => {}
        }
    }
}

/// Errors produced while parsing an import file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ImportError {
    /// The file had no data rows.
    Empty,
    /// The header row did not match a supported export format.
    UnsupportedFormat,
    /// The CSV structure was malformed.
    Malformed,
}

/// Parse a supported CSV export.
pub fn parse(data: &str) -> Result<ParsedImport, ImportError> {
    let raw = csv::parse(data).map_err(|_| ImportError::Malformed)?;

    // Skip rows that are entirely blank (trailing newlines, separators).
    let mut rows = raw
        .into_iter()
        .filter(|row| row.iter().any(|cell| !cell.trim().is_empty()));

    let header = rows.next().ok_or(ImportError::Empty)?;
    let columns = Columns::new(&header);
    let format = columns.detect().ok_or(ImportError::UnsupportedFormat)?;

    let mut parsed = ParsedImport {
        format,
        entries: Vec::new(),
        failed: Vec::new(),
    };

    for (offset, row) in rows.enumerate() {
        // The header is row 1, so the first data row is row 2.
        let row_number = (offset + 2) as u32;
        let result = match format {
            ImportFormat::Bitwarden => columns.bitwarden(&row),
            ImportFormat::Chrome => columns.chrome(&row),
        };
        match result {
            Ok(Some(entry)) => parsed.entries.push(entry),
            Ok(None) => {}
            Err(reason) => parsed.failed.push(ImportFailure {
                row: row_number,
                reason,
            }),
        }
    }

    if parsed.entries.is_empty() && parsed.failed.is_empty() {
        return Err(ImportError::Empty);
    }
    Ok(parsed)
}

/// Apply a parsed import to `vault`, returning what changed.
///
/// Duplicate detection compares non-secret fields only: logins by
/// title + username + URL, cards by title + cardholder, notes by title. This
/// mirrors the roadmap rule and never builds a map keyed by a secret.
pub fn apply(vault: &mut Vault, parsed: ParsedImport, mode: ImportMode) -> ImportReport {
    let ParsedImport {
        entries,
        failed,
        format: _,
    } = parsed;

    let mut report = ImportReport {
        failed: failed.len() as u32,
        failures: failed,
        ..ImportReport::default()
    };

    if mode == ImportMode::Replace {
        // Drop the old contents (the `Vault` drop wipes secrets).
        let old = std::mem::take(vault);
        drop(old);

        let mut folder_ids: HashMap<String, Uuid> = HashMap::new();
        for parsed_entry in entries {
            let mut entry = parsed_entry.entry;
            if let Some(name) = parsed_entry.folder {
                let id = match folder_ids.get(&name) {
                    Some(id) => *id,
                    None => {
                        let id = vault.add_folder(name.clone());
                        folder_ids.insert(name, id);
                        report.folders_added += 1;
                        id
                    }
                };
                entry.folder_id = Some(id);
            }
            report.record(&entry);
            vault.add_entry(entry);
            report.added += 1;
        }
        return report;
    }

    // Merge: keep existing folders (by name) and skip equivalent entries.
    let mut folders: HashMap<String, Uuid> = vault
        .folders
        .iter()
        .map(|folder| (folder.name.clone(), folder.id))
        .collect();
    let mut seen: HashSet<String> = vault.entries.iter().map(dedup_key).collect();

    for parsed_entry in entries {
        let mut entry = parsed_entry.entry;
        let key = dedup_key(&entry);
        if seen.contains(&key) {
            report.skipped += 1;
            continue;
        }
        if let Some(name) = parsed_entry.folder {
            let id = match folders.get(&name) {
                Some(id) => *id,
                None => {
                    let id = vault.add_folder(name.clone());
                    folders.insert(name, id);
                    report.folders_added += 1;
                    id
                }
            };
            entry.folder_id = Some(id);
        }
        seen.insert(key);
        report.record(&entry);
        vault.add_entry(entry);
        report.added += 1;
    }

    report
}

/// Serialize the vault as a plaintext, Bitwarden-compatible CSV export.
///
/// The Bitwarden columns model logins and secure notes; cards are written into
/// the note column (with their fields spelled out) so a round trip does not
/// silently drop them. Trashed entries are skipped. **The result is not
/// encrypted** — the caller must warn the user before writing it anywhere.
pub fn export_csv(vault: &Vault) -> String {
    let mut out = String::from(
        "folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp\n",
    );
    for entry in &vault.entries {
        if entry.deleted_at.is_some() {
            continue;
        }

        let folder = entry
            .folder_id
            .and_then(|id| vault.folders.iter().find(|folder| folder.id == id))
            .map(|folder| folder.name.as_str())
            .unwrap_or("");

        let (kind, url, username, password, totp, notes) = match &entry.body {
            EntryBody::Login(login) => (
                "login",
                login.url.clone(),
                login.username.clone(),
                login.password.clone(),
                login
                    .totp
                    .as_ref()
                    .map(|totp| totp.secret.clone())
                    .unwrap_or_default(),
                entry.notes.clone(),
            ),
            EntryBody::Note(note) => (
                "note",
                String::new(),
                String::new(),
                String::new(),
                String::new(),
                join_blocks(&[&entry.notes, &note.content]),
            ),
            EntryBody::Card(card) => {
                let mut blocks: Vec<String> = Vec::new();
                if !entry.notes.trim().is_empty() {
                    blocks.push(entry.notes.clone());
                }
                for (label, value) in [
                    ("Cardholder", card.cardholder.as_str()),
                    ("Number", card.number.as_str()),
                    ("Expiry", card.expiry.as_str()),
                    ("CVV", card.cvv.as_str()),
                    ("Brand", card.brand.as_deref().unwrap_or("")),
                ] {
                    if !value.is_empty() {
                        blocks.push(format!("{label}: {value}"));
                    }
                }
                (
                    "note",
                    String::new(),
                    String::new(),
                    String::new(),
                    String::new(),
                    blocks.join("\n"),
                )
            }
            // Passkeys are not representable in Bitwarden/Chrome CSV exports and
            // must not leak private key material. They are preserved in encrypted
            // backups; skip them in plaintext CSV export.
            EntryBody::Passkey(_) => continue,
        };

        let fields = export_bitwarden_fields(&entry.custom_fields);
        out.push_str(&csv::write_row(&[
            folder,
            if entry.favorite { "1" } else { "0" },
            kind,
            &entry.title,
            &notes,
            &fields,
            "0",
            &url,
            &username,
            &password,
            &totp,
        ]));
        out.push('\n');
    }
    out
}

/// A non-secret identity for duplicate detection.
fn dedup_key(entry: &Entry) -> String {
    let title = entry.title.trim().to_ascii_lowercase();
    match &entry.body {
        EntryBody::Login(login) => format!(
            "login|{title}|{}|{}",
            login.username.trim().to_ascii_lowercase(),
            login.url.trim().to_ascii_lowercase()
        ),
        EntryBody::Card(card) => {
            format!(
                "card|{title}|{}",
                card.cardholder.trim().to_ascii_lowercase()
            )
        }
        EntryBody::Note(_) => format!("note|{title}"),
        EntryBody::Passkey(passkey) => format!(
            "passkey|{title}|{}|{}",
            passkey.rp_id.trim().to_ascii_lowercase(),
            data_encoding::BASE64URL_NOPAD.encode(&passkey.credential_id)
        ),
    }
}

/// Parse a TOTP seed that may be a bare base32 secret or an `otpauth://` URI.
fn parse_totp(raw: &str) -> Option<TotpConfig> {
    let raw = raw.trim();
    if raw.is_empty() {
        return None;
    }
    if raw.to_ascii_lowercase().starts_with("otpauth://") {
        totp::parse_otpauth(raw).ok()
    } else {
        let config = TotpConfig::new(totp::normalize_secret(raw));
        config.validate().ok().map(|()| config)
    }
}

/// Case-insensitive column lookup over the header row.
struct Columns {
    names: Vec<String>,
}

impl Columns {
    fn new(header: &[String]) -> Self {
        Self {
            names: header
                .iter()
                .map(|name| name.trim().to_ascii_lowercase())
                .collect(),
        }
    }

    fn index(&self, name: &str) -> Option<usize> {
        self.names.iter().position(|candidate| candidate == name)
    }

    fn cell<'a>(&self, row: &'a [String], name: &str) -> &'a str {
        self.index(name)
            .and_then(|index| row.get(index))
            .map_or("", String::as_str)
    }

    /// Detect the export format from the header row.
    fn detect(&self) -> Option<ImportFormat> {
        if self.index("login_uri").is_some()
            || (self.index("type").is_some() && self.index("login_password").is_some())
        {
            Some(ImportFormat::Bitwarden)
        } else if self.index("url").is_some()
            && self.index("username").is_some()
            && self.index("password").is_some()
        {
            Some(ImportFormat::Chrome)
        } else {
            None
        }
    }

    fn bitwarden(&self, row: &[String]) -> Result<Option<ParsedEntry>, String> {
        let kind = self.cell(row, "type").trim().to_ascii_lowercase();
        let name = self.cell(row, "name").trim();
        let notes = self.cell(row, "notes");
        let fields = self.cell(row, "fields");
        let folder = self.bitwarden_folder(row);

        let url = self.cell(row, "login_uri").trim();
        let username = self.cell(row, "login_username");
        let password = self.cell(row, "login_password");
        let totp_raw = self.cell(row, "login_totp").trim();

        if name.is_empty()
            && username.is_empty()
            && password.is_empty()
            && url.is_empty()
            && notes.is_empty()
            && fields.trim().is_empty()
        {
            return Ok(None);
        }

        let (custom_fields, parsed_fields) = parse_bitwarden_fields(fields);
        let extra_notes = match parsed_fields {
            // Structured JSON fields parsed: custom fields captured, no legacy text to append.
            Some(_) => String::new(),
            // Unrecognized/legacy fields text: preserve it in notes as before.
            None => fields.to_string(),
        };

        let entry = match kind.as_str() {
            "note" => {
                let content = join_blocks(&[notes, &extra_notes]);
                let title = fallback_title(name, &["Secure note"]);
                let mut entry = Entry::note(title, Note { content });
                entry.custom_fields = custom_fields;
                entry
            }
            "" | "login" => {
                let title = fallback_title(name, &[url, username, "Imported login"]);
                let login = Login {
                    username: username.to_string(),
                    password: password.to_string(),
                    url: url.to_string(),
                    totp: parse_totp(totp_raw),
                    password_history: Vec::new(),
                };
                let mut entry = Entry::login(title, login);
                entry.notes = join_blocks(&[notes, &extra_notes]);
                entry.custom_fields = custom_fields;
                entry
            }
            // Cards and identities are not representable in the Bitwarden CSV
            // format; keep the payload as a secure note so nothing is lost.
            other => {
                let header = format!("Imported Bitwarden {other} item.");
                // Preserve structured custom fields when parsed; otherwise keep raw fields.
                let content = join_blocks(&[&header, notes, &extra_notes]);
                let title = fallback_title(name, &["Imported item"]);
                let mut entry = Entry::note(title, Note { content });
                entry.custom_fields = custom_fields;
                entry
            }
        };

        Ok(Some(ParsedEntry { entry, folder }))
    }

    fn chrome(&self, row: &[String]) -> Result<Option<ParsedEntry>, String> {
        let name = self.cell(row, "name").trim();
        let url = self.cell(row, "url").trim();
        let username = self.cell(row, "username");
        let password = self.cell(row, "password");
        let note = self.cell(row, "note");

        if name.is_empty() && url.is_empty() && username.is_empty() && password.is_empty() {
            return Ok(None);
        }

        let title = fallback_title(name, &[url, username, "Imported login"]);
        let login = Login {
            username: username.to_string(),
            password: password.to_string(),
            url: url.to_string(),
            totp: None,
            password_history: Vec::new(),
        };
        let mut entry = Entry::login(title, login);
        entry.notes = note.to_string();
        Ok(Some(ParsedEntry {
            entry,
            folder: None,
        }))
    }

    /// Resolve the folder column, tolerating the organization `collections`
    /// header and nested (`Parent/Child`) or comma-separated collection lists.
    fn bitwarden_folder(&self, row: &[String]) -> Option<String> {
        let folder = self.cell(row, "folder").trim();
        let collections = self.cell(row, "collections").trim();
        let raw = if folder.is_empty() {
            collections
        } else {
            folder
        };
        let top = raw
            .split(',')
            .next()
            .unwrap_or("")
            .split('/')
            .next()
            .unwrap_or("")
            .trim();
        if top.is_empty() {
            None
        } else {
            Some(top.to_string())
        }
    }
}

/// First non-empty candidate, or the final fallback.
fn fallback_title<'a>(name: &'a str, candidates: &[&'a str]) -> String {
    if !name.is_empty() {
        return name.to_string();
    }
    for candidate in candidates {
        if !candidate.is_empty() {
            return (*candidate).to_string();
        }
    }
    String::new()
}

/// Join non-empty blocks with newlines.
fn join_blocks(blocks: &[&str]) -> String {
    let mut out = String::new();
    for block in blocks {
        let block = block.trim_end_matches(['\r', '\n']);
        if block.trim().is_empty() {
            continue;
        }
        if !out.is_empty() {
            out.push('\n');
        }
        out.push_str(block);
    }
    out
}

/// Encode custom fields into Bitwarden's JSON `fields` column.
///
/// `type`: 0 = text, 1 = hidden, 2 = boolean (not used), 3 = linked (not used).
/// URL custom fields are exported as text fields so the value round-trips.
fn export_bitwarden_fields(fields: &[CustomField]) -> String {
    if fields.is_empty() {
        return String::new();
    }
    let mut out = String::from("[");
    for (i, field) in fields.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        let kind = match field.kind {
            CustomFieldKind::Hidden => 1,
            CustomFieldKind::Text | CustomFieldKind::Url => 0,
        };
        out.push_str(&format!(
            "{{\"name\":{},\"value\":{},\"type\":{},\"linkedId\":null}}",
            json_string(&field.label),
            json_string(&field.value),
            kind
        ));
    }
    out.push(']');
    out
}

/// Parse Bitwarden-style custom fields from the CSV `fields` column.
///
/// Returns `(custom_fields, fallback_note)` where `fallback_note` is `Some`
/// when fields were parsed structurally (possibly empty) and the caller should
/// not also append the raw field string to notes; `None` means parsing did not
/// recognize the format and the raw string should be preserved as text.
fn parse_bitwarden_fields(raw: &str) -> (Vec<CustomField>, Option<String>) {
    let raw = raw.trim();
    if raw.is_empty() {
        return (Vec::new(), Some(String::new()));
    }

    // Bitwarden CSV uses a JSON array in the `fields` column.
    if raw.starts_with('[') {
        if let Some(fields) = parse_fields_json_array(raw) {
            return (fields, Some(String::new()));
        }
    }

    // Not a recognized Bitwarden fields payload: preserve as text (legacy behavior).
    (Vec::new(), None)
}

fn parse_fields_json_array(raw: &str) -> Option<Vec<CustomField>> {
    let mut s = raw.trim();
    if !s.starts_with('[') || !s.ends_with(']') {
        return None;
    }
    s = &s[1..s.len() - 1];
    let mut fields = Vec::new();
    let mut rest = s.trim_start();
    while !rest.is_empty() {
        if rest.starts_with(',') {
            rest = rest[1..].trim_start();
            continue;
        }
        if !rest.starts_with('{') {
            return None;
        }
        let (obj, next) = extract_json_object(rest)?;
        if let Some(field) = parse_field_object(obj) {
            fields.push(field);
        }
        rest = next.trim_start();
    }
    Some(fields)
}

fn extract_json_object(s: &str) -> Option<(&str, &str)> {
    let bytes = s.as_bytes();
    let mut depth = 0i32;
    let mut in_str = false;
    let mut escape = false;
    for (i, &b) in bytes.iter().enumerate() {
        if in_str {
            if escape {
                escape = false;
            } else if b == b'\\' {
                escape = true;
            } else if b == b'"' {
                in_str = false;
            }
            continue;
        }
        match b {
            b'"' => in_str = true,
            b'{' => depth += 1,
            b'}' => {
                depth -= 1;
                if depth == 0 {
                    return Some((&s[..=i], &s[i + 1..]));
                }
            }
            _ => {}
        }
    }
    None
}

fn parse_field_object(obj: &str) -> Option<CustomField> {
    let name = json_get_string(obj, "name").unwrap_or_default();
    let value = json_get_string(obj, "value").unwrap_or_default();
    let typ = json_get_number(obj, "type").unwrap_or(0);
    if name.trim().is_empty() && value.is_empty() {
        return None;
    }
    let kind = match typ {
        1 => CustomFieldKind::Hidden,
        _ => {
            if looks_like_url(&value) {
                CustomFieldKind::Url
            } else {
                CustomFieldKind::Text
            }
        }
    };
    Some(CustomField::new(name, value, kind))
}

fn looks_like_url(value: &str) -> bool {
    let v = value.trim().to_ascii_lowercase();
    v.starts_with("https://") || v.starts_with("http://")
}

fn json_get_string(obj: &str, key: &str) -> Option<String> {
    let needle = format!("\"{}\"", key);
    let mut i = 0;
    let bytes = obj.as_bytes();
    while i + needle.len() <= bytes.len() {
        if obj[i..].starts_with(&needle) {
            // find colon
            let mut j = i + needle.len();
            while j < bytes.len() && bytes[j].is_ascii_whitespace() {
                j += 1;
            }
            if j >= bytes.len() || bytes[j] != b':' {
                i += 1;
                continue;
            }
            j += 1;
            while j < bytes.len() && bytes[j].is_ascii_whitespace() {
                j += 1;
            }
            if j >= bytes.len() {
                return None;
            }
            if bytes[j] == b'"' {
                return parse_json_string(&obj[j..]).map(|(v, _)| v);
            } else if obj[j..].starts_with("null") {
                return Some(String::new());
            } else {
                return None;
            }
        }
        i += 1;
    }
    None
}

fn json_get_number(obj: &str, key: &str) -> Option<i64> {
    let needle = format!("\"{}\"", key);
    let mut i = 0;
    let bytes = obj.as_bytes();
    while i + needle.len() <= bytes.len() {
        if obj[i..].starts_with(&needle) {
            let mut j = i + needle.len();
            while j < bytes.len() && bytes[j].is_ascii_whitespace() {
                j += 1;
            }
            if j >= bytes.len() || bytes[j] != b':' {
                i += 1;
                continue;
            }
            j += 1;
            while j < bytes.len() && bytes[j].is_ascii_whitespace() {
                j += 1;
            }
            let start = j;
            if j < bytes.len() && (bytes[j] == b'-' || bytes[j].is_ascii_digit()) {
                j += 1;
                while j < bytes.len() && bytes[j].is_ascii_digit() {
                    j += 1;
                }
                return obj[start..j].parse::<i64>().ok();
            }
            return None;
        }
        i += 1;
    }
    None
}

fn parse_json_string(s: &str) -> Option<(String, &str)> {
    let bytes = s.as_bytes();
    if bytes.first().copied()? != b'"' {
        return None;
    }
    let mut out = String::new();
    let mut i = 1;
    while i < bytes.len() {
        match bytes[i] {
            b'"' => return Some((out, &s[i + 1..])),
            b'\\' => {
                i += 1;
                let esc = *bytes.get(i)?;
                let ch = match esc {
                    b'"' => '"',
                    b'\\' => '\\',
                    b'/' => '/',
                    b'b' => '\u{0008}',
                    b'f' => '\u{000C}',
                    b'n' => '\n',
                    b'r' => '\r',
                    b't' => '\t',
                    b'u' => {
                        let hex = s.get(i + 1..i + 5)?;
                        let code = u16::from_str_radix(hex, 16).ok()?;
                        i += 4;
                        char::from_u32(u32::from(code)).unwrap_or('\u{FFFD}')
                    }
                    _ => return None,
                };
                out.push(ch);
            }
            b if b < 0x20 => return None,
            _ => {
                let ch = s[i..].chars().next()?;
                out.push(ch);
                i += ch.len_utf8();
                continue;
            }
        }
        i += 1;
    }
    None
}

fn json_string(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 2);
    out.push('"');
    for ch in s.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            '\u{0008}' => out.push_str("\\b"),
            '\u{000C}' => out.push_str("\\f"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    const CHROME: &str = "name,url,username,password,note\n\
        Example,https://example.com,ada@example.com,s3cret,\n\
        Bank,https://bank.example,ada,hunter2,Main account\n";

    const BITWARDEN: &str = "folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp\n\
        Social,1,login,Twitter,,,0,twitter.com,me@example.com,password123,\n\
        ,,login,My Bank,Bank PIN is 1234,\"PIN: 1234\",,https://www.wellsfargo.com/home.jhtml,john.smith,password123456,\n\
        ,,note,My Note,\"This is a secure note.\",,,,,\n";

    #[test]
    fn detects_and_parses_chrome() {
        let parsed = parse(CHROME).unwrap();
        assert_eq!(parsed.format, ImportFormat::Chrome);
        assert_eq!(parsed.entries.len(), 2);
        let first = &parsed.entries[0].entry;
        assert_eq!(first.title, "Example");
        let EntryBody::Login(login) = &first.body else {
            panic!("expected login");
        };
        assert_eq!(login.username, "ada@example.com");
        assert_eq!(login.password, "s3cret");
        assert_eq!(login.url, "https://example.com");
        assert_eq!(parsed.entries[1].entry.notes, "Main account");
    }

    #[test]
    fn detects_and_parses_bitwarden() {
        let parsed = parse(BITWARDEN).unwrap();
        assert_eq!(parsed.format, ImportFormat::Bitwarden);
        assert_eq!(parsed.entries.len(), 3);

        let twitter = &parsed.entries[0];
        assert_eq!(twitter.folder.as_deref(), Some("Social"));
        let EntryBody::Login(login) = &twitter.entry.body else {
            panic!("expected login");
        };
        assert_eq!(login.username, "me@example.com");
        assert_eq!(login.password, "password123");

        let bank = &parsed.entries[1];
        assert_eq!(bank.entry.notes, "Bank PIN is 1234\nPIN: 1234");

        let note = &parsed.entries[2].entry;
        let EntryBody::Note(content) = &note.body else {
            panic!("expected note");
        };
        assert_eq!(content.content, "This is a secure note.");
    }

    #[test]
    fn parses_bitwarden_totp_seed() {
        let data = "folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp\n\
            ,,login,EVGA,,,,https://www.evga.com/support/login.asp,hello@bitwarden.com,fakepassword,JBSWY3DPEHPK3PXP\n";
        let parsed = parse(data).unwrap();
        let EntryBody::Login(login) = &parsed.entries[0].entry.body else {
            panic!("expected login");
        };
        assert!(login.totp.is_some());
    }

    #[test]
    fn organization_collections_become_folders() {
        let data = "collections,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp\n\
            \"Parent/Child\",login,Item,,,,https://example.com,ada,pw,\n";
        let parsed = parse(data).unwrap();
        assert_eq!(parsed.entries[0].folder.as_deref(), Some("Parent"));
    }

    #[test]
    fn chrome_handles_a_utf8_bom_and_quoted_commas() {
        let data =
            "\u{feff}name,url,username,password,note\n\"My, Site\",https://x.example,ada,pw,\n";
        let parsed = parse(data).unwrap();
        assert_eq!(parsed.entries[0].entry.title, "My, Site");
    }

    #[test]
    fn blank_rows_are_ignored() {
        let data = "name,url,username,password\n\n,\nExample,https://x.example,ada,pw\n";
        let parsed = parse(data).unwrap();
        assert_eq!(parsed.entries.len(), 1);
    }

    #[test]
    fn unsupported_header_is_rejected() {
        assert_eq!(
            parse("foo,bar\n1,2\n").unwrap_err(),
            ImportError::UnsupportedFormat
        );
    }

    #[test]
    fn empty_input_is_rejected() {
        assert_eq!(parse("").unwrap_err(), ImportError::Empty);
    }

    #[test]
    fn malformed_csv_is_rejected() {
        assert_eq!(
            parse("name,url,username,password\n\"oops").unwrap_err(),
            ImportError::Malformed
        );
    }

    fn parsed_chrome() -> ParsedImport {
        parse(CHROME).unwrap()
    }

    #[test]
    fn merge_adds_then_skips_duplicates() {
        let mut vault = Vault::new();
        let report = apply(&mut vault, parsed_chrome(), ImportMode::Merge);
        assert_eq!(report.added, 2);
        assert_eq!(report.skipped, 0);
        assert_eq!(report.logins, 2);

        // Re-importing the same file is a no-op.
        let report = apply(&mut vault, parsed_chrome(), ImportMode::Merge);
        assert_eq!(report.added, 0);
        assert_eq!(report.skipped, 2);
        assert_eq!(vault.entries.len(), 2);
    }

    #[test]
    fn merge_keeps_existing_entries() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::login("Keep", Login::default()));
        let report = apply(&mut vault, parsed_chrome(), ImportMode::Merge);
        assert_eq!(report.added, 2);
        assert_eq!(vault.entries.len(), 3);
    }

    #[test]
    fn replace_discards_existing_entries() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::login("Old", Login::default()));
        let report = apply(&mut vault, parsed_chrome(), ImportMode::Replace);
        assert_eq!(report.added, 2);
        assert_eq!(vault.entries.len(), 2);
        assert!(vault.entries.iter().all(|entry| entry.title != "Old"));
    }

    #[test]
    fn replace_creates_folders_and_assigns_entries() {
        let mut vault = Vault::new();
        let parsed = parse(BITWARDEN).unwrap();
        let report = apply(&mut vault, parsed, ImportMode::Replace);
        assert_eq!(report.folders_added, 1);
        let folder = vault.folders.iter().find(|f| f.name == "Social").unwrap();
        assert_eq!(vault.entries[0].folder_id, Some(folder.id));
    }

    #[test]
    fn exported_csv_round_trips_through_the_importer() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::login(
            "My, Site",
            Login {
                username: "ada".into(),
                password: "p\"w\nx".into(),
                url: "https://x.example".into(),
                ..Login::default()
            },
        ));
        vault.add_entry(Entry::note(
            "Recovery",
            Note {
                content: "one\ntwo".into(),
            },
        ));

        let csv = export_csv(&vault);
        let parsed = parse(&csv).unwrap();
        assert_eq!(parsed.entries.len(), 2);
        let EntryBody::Login(login) = &parsed.entries[0].entry.body else {
            panic!("expected login");
        };
        assert_eq!(login.password, "p\"w\nx");
        let EntryBody::Note(note) = &parsed.entries[1].entry.body else {
            panic!("expected note");
        };
        assert_eq!(note.content, "one\ntwo");
    }

    #[test]
    fn bitwarden_custom_fields_round_trip_through_csv_export() {
        let mut vault = Vault::new();
        let mut entry = Entry::login(
            "Service",
            Login {
                username: "ada".into(),
                password: "pw".into(),
                url: "https://svc.example".into(),
                ..Login::default()
            },
        );
        entry.custom_fields = vec![
            CustomField::new("Department", "Engineering", CustomFieldKind::Text),
            CustomField::new("PIN", "1234", CustomFieldKind::Hidden),
            CustomField::new("Portal", "https://portal.example", CustomFieldKind::Url),
        ];
        vault.add_entry(entry);

        let csv = export_csv(&vault);
        let parsed = parse(&csv).unwrap();
        assert_eq!(parsed.entries.len(), 1);
        let imported = &parsed.entries[0].entry;
        assert_eq!(imported.custom_fields.len(), 3);
        assert_eq!(imported.custom_fields[0].label, "Department");
        assert_eq!(imported.custom_fields[0].value, "Engineering");
        assert_eq!(imported.custom_fields[0].kind, CustomFieldKind::Text);
        assert_eq!(imported.custom_fields[1].label, "PIN");
        assert_eq!(imported.custom_fields[1].value, "1234");
        assert_eq!(imported.custom_fields[1].kind, CustomFieldKind::Hidden);
        assert_eq!(imported.custom_fields[2].label, "Portal");
        assert_eq!(imported.custom_fields[2].value, "https://portal.example");
        // URL exported as Bitwarden text field (type 0) is re-detected as URL on import.
        assert_eq!(imported.custom_fields[2].kind, CustomFieldKind::Url);
    }

    #[test]
    fn imports_a_thousand_row_export() {
        let mut data = String::from("name,url,username,password,note\n");
        for index in 0..1000 {
            data.push_str(&format!(
                "Site {index},https://site{index}.example,user{index},pw{index},\n"
            ));
        }

        let parsed = parse(&data).unwrap();
        assert_eq!(parsed.entries.len(), 1000);
        assert!(parsed.failed.is_empty());

        let mut vault = Vault::new();
        let report = apply(&mut vault, parsed, ImportMode::Merge);
        assert_eq!(report.added, 1000);
        assert_eq!(report.logins, 1000);
        assert_eq!(vault.entries.len(), 1000);

        // A second import of the same file adds nothing.
        let report = apply(&mut vault, parse(&data).unwrap(), ImportMode::Merge);
        assert_eq!(report.added, 0);
        assert_eq!(report.skipped, 1000);
        assert_eq!(vault.entries.len(), 1000);
    }
}
