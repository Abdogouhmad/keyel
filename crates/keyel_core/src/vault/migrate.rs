//! Payload schema migration scaffold.
//!
//! The file format has its own version in the header; this module upgrades the
//! decrypted payload. Each supported version maps to the step that lifts it to
//! the next one; [`VAULT_SCHEMA_VERSION`] is the identity.
//!
//! History:
//! - v1 → v2: entries gained an optional `icon`. Old payloads simply lack the
//!   field, so the step is a no-op (the deserializer defaults it to `None`).

use crate::error::Error;

use super::model::{Vault, VAULT_SCHEMA_VERSION};

/// Migrate a payload from `from_version` to [`VAULT_SCHEMA_VERSION`].
///
/// Future versions add one step per arm, each transforming the previous
/// schema in place. Unknown and future versions fail closed.
pub fn migrate(mut vault: Vault, from_version: u16) -> Result<Vault, Error> {
    if from_version > VAULT_SCHEMA_VERSION {
        return Err(Error::UnsupportedVersion(from_version));
    }

    match from_version {
        1 => {
            // v1 → v2: entries gain an optional `icon`. A v1 payload has no
            // icon field, so `#[serde(default)]` already produced `None`;
            // nothing to rewrite.
        }
        VAULT_SCHEMA_VERSION => {}
        other => return Err(Error::UnsupportedVersion(other)),
    }

    vault.schema_version = VAULT_SCHEMA_VERSION;
    Ok(vault)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::model::{Entry, Note};

    #[test]
    fn v2_migrates_to_v2_without_changes() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "a",
            Note {
                content: "b".into(),
            },
        ));
        let before = vault.clone();

        let migrated = migrate(vault, 2).unwrap();
        assert_eq!(migrated, before);
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
    }

    #[test]
    fn v1_migrates_to_v2_and_preserves_entries() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "a",
            Note {
                content: "b".into(),
            },
        ));
        vault.schema_version = 1;

        let migrated = migrate(vault.clone(), 1).unwrap();
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
        assert_eq!(migrated.entries, vault.entries);
        assert!(migrated.entries.iter().all(|entry| entry.icon.is_none()));
    }

    #[test]
    fn unknown_versions_fail_closed() {
        assert_eq!(
            migrate(Vault::new(), 0).unwrap_err(),
            Error::UnsupportedVersion(0)
        );
        assert_eq!(
            migrate(Vault::new(), 3).unwrap_err(),
            Error::UnsupportedVersion(3)
        );
    }
}
