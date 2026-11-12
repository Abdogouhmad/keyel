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
use crate::vault::{Entry, EntryBody, EntryKind, Login, Note, TotpConfig, Vault};

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
        };

        out.push_str(&csv::write_row(&[
            folder,
            if entry.favorite { "1" } else { "0" },
            kind,
            &entry.title,
            &notes,
            "",
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
        {
            return Ok(None);
        }

        let entry = match kind.as_str() {
            "note" => {
                let content = join_blocks(&[notes, fields]);
                let title = fallback_title(name, &["Secure note"]);
                Entry::note(title, Note { content })
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
                entry.notes = join_blocks(&[notes, fields]);
                entry
            }
            // Cards and identities are not representable in the Bitwarden CSV
            // format; keep the payload as a secure note so nothing is lost.
            other => {
                let header = format!("Imported Bitwarden {other} item.");
                let content = join_blocks(&[&header, notes, fields]);
                let title = fallback_title(name, &["Imported item"]);
                Entry::note(title, Note { content })
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
