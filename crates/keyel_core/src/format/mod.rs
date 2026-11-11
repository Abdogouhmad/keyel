//! The on-disk `vault.keyel` format.

pub mod codec;
pub mod header;

pub use codec::{
    change_master, change_master_with_vault_key, create, seal, unlock_with_master,
    unlock_with_recovery, unlock_with_vault_key, CreatedVault, UnlockedVault,
};
pub use header::{
    Header, KdfParams, Keyslot, SlotKind, FORMAT_VERSION, MAGIC, MAX_HEADER_LEN, MAX_SLOTS,
    VAULT_ID_LEN, WRAPPED_KEY_LEN,
};
