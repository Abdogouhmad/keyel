//! Payload schema migration scaffold.
//!
//! The file format has its own version in the header; this module upgrades the
//! decrypted payload. Each supported version maps to the step that lifts it to
//! the next one; [`VAULT_SCHEMA_VERSION`] is the identity.
//!
//! History:
//! - v1 → v2: entries gained an optional `icon`. Old payloads simply lack the
//!   field, so the step is a no-op (the deserializer defaults it to `None`).
//! - v2 → v3: entries gained ordered `custom_fields`. Old payloads simply lack
//!   the field, so the step is a no-op (the deserializer defaults it empty).
//! - v3 → v4: entries gained the `passkey` kind/body. Existing v3 payloads
//!   contain no passkeys, so the step is a no-op.

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

    let mut version = from_version;
    while version < VAULT_SCHEMA_VERSION {
        match version {
            1 => {
                // v1 → v2: entries gain an optional `icon`. A v1 payload has no
                // icon field, so `#[serde(default)]` already produced `None`.
            }
            2 => {
                // v2 → v3: entries gain ordered `custom_fields`. A v2 payload
                // has no field, so `#[serde(default)]` already produced empty.
            }
            3 => {
                // v3 → v4: entries gain the `passkey` kind/body. Existing v3
                // payloads contain no passkeys, so no structural backfill is needed.
            }
            other => return Err(Error::UnsupportedVersion(other)),
        }
        version += 1;
    }

    vault.schema_version = VAULT_SCHEMA_VERSION;
    Ok(vault)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vault::model::{Entry, Note};

    #[test]
    fn current_version_migrates_without_changes() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "a",
            Note {
                content: "b".into(),
            },
        ));
        let before = vault.clone();

        let migrated = migrate(vault, VAULT_SCHEMA_VERSION).unwrap();
        assert_eq!(migrated, before);
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
    }

    #[test]
    fn v1_migrates_to_current_and_preserves_entries() {
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
        assert_eq!(migrated.entries.len(), vault.entries.len());
        assert_eq!(migrated.entries[0].title, "a");
        assert!(migrated.entries[0].icon.is_none());
        assert!(migrated.entries[0].custom_fields.is_empty());
    }

    #[test]
    fn v2_migrates_to_current_and_adds_empty_custom_fields() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "a",
            Note {
                content: "b".into(),
            },
        ));
        vault.schema_version = 2;

        let migrated = migrate(vault.clone(), 2).unwrap();
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
        assert_eq!(migrated.entries.len(), vault.entries.len());
        assert!(migrated.entries[0].custom_fields.is_empty());
    }

    #[test]
    fn v3_migrates_to_current() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "a",
            Note {
                content: "b".into(),
            },
        ));
        vault.schema_version = 3;

        let migrated = migrate(vault.clone(), 3).unwrap();
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
        assert_eq!(migrated.entries.len(), vault.entries.len());
        assert!(migrated.entries[0].custom_fields.is_empty());
    }

    #[test]
    fn unknown_versions_fail_closed() {
        assert_eq!(
            migrate(Vault::new(), 0).unwrap_err(),
            Error::UnsupportedVersion(0)
        );
        assert_eq!(
            migrate(Vault::new(), 99).unwrap_err(),
            Error::UnsupportedVersion(99)
        );
    }
}
