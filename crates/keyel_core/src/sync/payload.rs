//! Decrypted sync payload: the vault state one device publishes to the group.
//!
//! This type only ever exists inside Rust. It is serialized to CBOR and sealed
//! by [`super::envelope`] before it reaches a backend; Dart never sees it.

use serde::{Deserialize, Serialize};

use crate::error::Error;
use crate::vault::model::{Folder, Tombstone, VAULT_SCHEMA_VERSION};

/// The full, plain vault state shared by one device.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SyncPayload {
    /// Vault payload schema of the writer.
    pub schema_version: u16,
    /// Folders, including their sync metadata.
    #[serde(default)]
    pub folders: Vec<Folder>,
    /// Entries, including secrets and soft-deleted items.
    #[serde(default)]
    pub entries: Vec<crate::vault::model::Entry>,
    /// Permanent-removal markers propagated by sync.
    #[serde(default)]
    pub tombstones: Vec<Tombstone>,
}

impl Drop for SyncPayload {
    fn drop(&mut self) {
        for entry in &mut self.entries {
            entry.zeroize_secrets();
        }
    }
}

impl SyncPayload {
    /// Take a snapshot of the vault's syncable state.
    pub fn from_vault(vault: &crate::vault::Vault) -> Self {
        Self {
            schema_version: VAULT_SCHEMA_VERSION,
            folders: vault.folders.clone(),
            entries: vault.entries.clone(),
            tombstones: vault.tombstones.clone(),
        }
    }

    /// Serialize the plain payload. Callers must wrap the result in a
    /// `Zeroizing` buffer after use because it contains secrets.
    pub fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let mut bytes = Vec::new();
        ciborium::into_writer(self, &mut bytes).map_err(|_| Error::Corrupted)?;
        Ok(bytes)
    }

    /// Parse and validate a decrypted payload.
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, Error> {
        let payload: Self = ciborium::from_reader(bytes).map_err(|_| Error::Corrupted)?;
        if payload.schema_version == 0 || payload.schema_version > VAULT_SCHEMA_VERSION {
            return Err(Error::UnsupportedVersion(payload.schema_version));
        }
        Ok(payload)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::model::{Entry, Note, Vault};
    use zeroize::Zeroizing;

    #[test]
    fn payload_round_trips_entries_and_tombstones() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "secret",
            Note {
                content: "do not share".into(),
            },
        ));
        let payload = SyncPayload::from_vault(&vault);
        let bytes = Zeroizing::new(payload.to_bytes().unwrap());
        let decoded = SyncPayload::from_bytes(&bytes).unwrap();
        assert_eq!(decoded, payload);
    }

    #[test]
    fn future_schema_versions_are_rejected() {
        let mut payload = SyncPayload::from_vault(&Vault::new());
        payload.schema_version = VAULT_SCHEMA_VERSION + 1;
        let bytes = Zeroizing::new(payload.to_bytes().unwrap());
        assert_eq!(
            SyncPayload::from_bytes(&bytes).unwrap_err(),
            Error::UnsupportedVersion(VAULT_SCHEMA_VERSION + 1)
        );
    }
}
