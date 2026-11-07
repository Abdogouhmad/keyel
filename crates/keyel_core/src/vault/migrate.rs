//! Payload schema migration scaffold.
//!
//! The file format has its own version in the header; this module upgrades the
//! decrypted payload. Version 1 is the first payload, so the currently
//! supported migration set is just the identity.

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
    fn v1_migrates_to_v1_without_changes() {
        let mut vault = Vault::new();
        vault.add_entry(Entry::note(
            "a",
            Note {
                content: "b".into(),
            },
        ));
        let before = vault.clone();

        let migrated = migrate(vault, 1).unwrap();
        assert_eq!(migrated, before);
        assert_eq!(migrated.schema_version, VAULT_SCHEMA_VERSION);
    }

    #[test]
    fn unknown_versions_fail_closed() {
        assert_eq!(
            migrate(Vault::new(), 0).unwrap_err(),
            Error::UnsupportedVersion(0)
        );
        assert_eq!(
            migrate(Vault::new(), 2).unwrap_err(),
            Error::UnsupportedVersion(2)
        );
    }
}
