//! Entry CRUD and secret reveal, exposed to Dart.

use std::str::FromStr;

use keyel_core::vault::{search, Card, Entry, EntryBody, EntryFilter, EntryKind, Login, Note};
use uuid::Uuid;

use super::error::VaultApiError;
use super::models::{
    map_custom_fields, EntryDetailDto, EntryDraft, EntryKindDto, EntrySummaryDto, FolderDto,
    SecretFieldDto,
};
use super::session::with_session;

pub(crate) fn parse_id(id: &str) -> Result<Uuid, VaultApiError> {
    Uuid::from_str(id).map_err(|_| VaultApiError::InvalidId)
}

/// Search entries and return secret-free summaries.
///
/// Pass `None` for `kind` and `favorite` to skip those filters. Metadata only:
/// passwords, notes and card numbers are never matched.
pub fn list_entries(
    query: String,
    kind: Option<EntryKindDto>,
    favorite: Option<bool>,
    include_deleted: bool,
) -> Result<Vec<EntrySummaryDto>, VaultApiError> {
    with_session(|session| {
        let filter = EntryFilter {
            kind: kind.map(EntryKind::from),
            favorite,
            include_deleted,
            ..EntryFilter::default()
        };
        Ok(search(session.vault(), &query, &filter)
            .into_iter()
            .map(EntrySummaryDto::from)
            .collect())
    })
}

/// Fetch one entry with all secrets masked.
pub fn get_entry(id: String) -> Result<EntryDetailDto, VaultApiError> {
    with_session(|session| {
        let id = parse_id(&id)?;
        let entry = session.vault().entry(id).ok_or(VaultApiError::NotFound)?;
        Ok(EntryDetailDto::from(entry))
    })
}

/// Create a new entry or update an existing one. Returns the entry id.
///
/// Secret inputs left as `None` keep the stored value when updating, so an
/// editor can round-trip a masked detail view without revealing secrets.
pub fn upsert_entry(draft: EntryDraft) -> Result<String, VaultApiError> {
    if draft.title.trim().is_empty() {
        return Err(VaultApiError::InvalidField);
    }

    with_session(|session| {
        let existing = match draft.id.as_deref() {
            Some(id) => Some(
                session
                    .vault()
                    .entry(parse_id(id)?)
                    .cloned()
                    .ok_or(VaultApiError::NotFound)?,
            ),
            None => None,
        };

        let kind = draft.kind;
        let title = draft.title.clone();
        let notes = draft.notes.clone();
        let tags = draft.tags.clone();
        let folder_id = draft.folder_id.as_deref().map(parse_id).transpose()?;
        let favorite = draft.favorite;
        let icon = draft.icon.clone();
        let existing_custom = existing
            .as_ref()
            .map(|entry| entry.custom_fields.as_slice())
            .unwrap_or(&[]);
        let custom_fields = map_custom_fields(draft.custom_fields.clone(), existing_custom);

        let body = match kind {
            EntryKindDto::Login => {
                let previous = match existing.as_ref().map(|entry| &entry.body) {
                    Some(EntryBody::Login(login)) => Some(login),
                    _ => None,
                };
                EntryBody::Login(draft.into_login(previous))
            }
            EntryKindDto::Card => {
                let previous = match existing.as_ref().map(|entry| &entry.body) {
                    Some(EntryBody::Card(card)) => Some(card),
                    _ => None,
                };
                EntryBody::Card(draft.into_card(previous))
            }
            EntryKindDto::Note => {
                let previous = match existing.as_ref().map(|entry| &entry.body) {
                    Some(EntryBody::Note(note)) => Some(note),
                    _ => None,
                };
                EntryBody::Note(draft.into_note(previous))
            }
            EntryKindDto::Passkey => {
                // Passkeys are created/updated through dedicated ceremony flows,
                // not the generic entry editor draft. Preserve existing passkey
                // bodies on metadata updates; reject creating passkeys here.
                match existing.as_ref().map(|entry| entry.body.clone()) {
                    Some(body @ EntryBody::Passkey(_)) => body,
                    _ => return Err(VaultApiError::InvalidField),
                }
            }
        };

        let entry = match existing {
            Some(mut entry) => {
                let id = entry.id;
                entry.title = title;
                entry.notes = notes.unwrap_or(entry.notes);
                entry.tags = tags;
                entry.folder_id = folder_id;
                entry.favorite = favorite;
                entry.icon = icon;
                entry.body = body;
                entry.custom_fields = custom_fields;
                session.vault_mut().update_entry(entry)?;
                id
            }
            None => {
                let mut entry = Entry::new(title, body);
                entry.notes = notes.unwrap_or_default();
                entry.tags = tags;
                entry.folder_id = folder_id;
                entry.favorite = favorite;
                entry.icon = icon;
                entry.custom_fields = custom_fields;
                session.vault_mut().add_entry(entry)
            }
        };

        session.save()?;
        Ok(entry.to_string())
    })
}

/// Move an entry to the trash.
pub fn delete_entry(id: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        session.vault_mut().delete_entry(parse_id(&id)?)?;
        session.save()?;
        Ok(())
    })
}

/// Restore an entry from the trash.
pub fn restore_entry(id: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        session.vault_mut().restore_entry(parse_id(&id)?)?;
        session.save()?;
        Ok(())
    })
}

/// Permanently remove an entry.
pub fn purge_entry(id: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        session.vault_mut().purge_entry(parse_id(&id)?)?;
        session.save()?;
        Ok(())
    })
}

/// List folders. Folders never contain secrets.
pub fn list_folders() -> Result<Vec<FolderDto>, VaultApiError> {
    with_session(|session| {
        Ok(session
            .vault()
            .folders
            .iter()
            .map(|folder| FolderDto {
                id: folder.id.to_string(),
                name: folder.name.clone(),
                order: folder.order,
            })
            .collect())
    })
}

/// Create a folder and return its id.
pub fn add_folder(name: String) -> Result<String, VaultApiError> {
    let name = name.trim();
    if name.is_empty() {
        return Err(VaultApiError::InvalidField);
    }
    with_session(|session| {
        let id = session.vault_mut().add_folder(name);
        session.save()?;
        Ok(id.to_string())
    })
}

/// Rename an existing folder.
pub fn rename_folder(id: String, name: String) -> Result<(), VaultApiError> {
    let name = name.trim();
    if name.is_empty() {
        return Err(VaultApiError::InvalidField);
    }
    with_session(|session| {
        session.vault_mut().rename_folder(parse_id(&id)?, name)?;
        session.save()?;
        Ok(())
    })
}

/// Delete a folder. Its entries move to "No folder".
pub fn delete_folder(id: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        session.vault_mut().delete_folder(parse_id(&id)?)?;
        session.save()?;
        Ok(())
    })
}

/// Move several entries to a folder, or to "No folder" with `None`.
pub fn move_entries(ids: Vec<String>, folder_id: Option<String>) -> Result<(), VaultApiError> {
    let folder = folder_id.as_deref().map(parse_id).transpose()?;
    with_session(|session| {
        let parsed: Vec<Uuid> = ids
            .iter()
            .map(|id| parse_id(id))
            .collect::<Result<_, _>>()?;
        for id in parsed {
            let entry = session
                .vault_mut()
                .entry_mut(id)
                .ok_or(VaultApiError::NotFound)?;
            entry.folder_id = folder;
        }
        session.save()?;
        Ok(())
    })
}

/// Return one plaintext secret field.
///
/// This is the only bridge path for fixed entry secrets. Callers should reveal
/// on demand and avoid caching the result.
pub fn reveal_field(id: String, field: SecretFieldDto) -> Result<String, VaultApiError> {
    with_session(|session| {
        let id = parse_id(&id)?;
        let entry = session.vault().entry(id).ok_or(VaultApiError::NotFound)?;

        let value = match field {
            SecretFieldDto::LoginPassword => match &entry.body {
                EntryBody::Login(Login { password, .. }) => password.as_str(),
                _ => return Err(VaultApiError::InvalidField),
            },
            SecretFieldDto::LoginTotpSecret => match &entry.body {
                EntryBody::Login(login) => login
                    .totp
                    .as_ref()
                    .map(|totp| totp.secret.as_str())
                    .ok_or(VaultApiError::InvalidField)?,
                _ => return Err(VaultApiError::InvalidField),
            },
            SecretFieldDto::CardNumber => match &entry.body {
                EntryBody::Card(Card { number, .. }) => number.as_str(),
                _ => return Err(VaultApiError::InvalidField),
            },
            SecretFieldDto::CardCvv => match &entry.body {
                EntryBody::Card(Card { cvv, .. }) => cvv.as_str(),
                _ => return Err(VaultApiError::InvalidField),
            },
            SecretFieldDto::NoteContent => match &entry.body {
                EntryBody::Note(Note { content }) => content.as_str(),
                _ => return Err(VaultApiError::InvalidField),
            },
            SecretFieldDto::EntryNotes => entry.notes.as_str(),
        };

        Ok(value.to_owned())
    })
}

/// Return the plaintext value of a hidden custom field.
///
/// Only hidden custom fields can be revealed through this path. Non-secret
/// custom-field values are already present in the entry detail.
pub fn reveal_custom_field(id: String, field_id: String) -> Result<String, VaultApiError> {
    with_session(|session| {
        let id = parse_id(&id)?;
        let field_id = parse_id(&field_id)?;
        let entry = session.vault().entry(id).ok_or(VaultApiError::NotFound)?;
        let field = entry
            .custom_fields
            .iter()
            .find(|field| field.id == field_id)
            .ok_or(VaultApiError::NotFound)?;
        if !field.is_secret() {
            return Err(VaultApiError::InvalidField);
        }
        Ok(field.value.clone())
    })
}
