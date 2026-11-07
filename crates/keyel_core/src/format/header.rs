//! Plaintext (`KYL1`) vault header model.
//!
//! The header contains no secrets: salts, nonces and AEAD-wrapped vault keys
//! only. It is serialized as CBOR and stored length-delimited in the file.
//!
//! Authentication strategy:
//! - each keyslot's wrapped key is authenticated with its own metadata as AAD
//!   (`kind` + KDF parameters), so slots cannot be swapped or edited;
//! - the body is authenticated with the stable `format_version` + `vault_id`
//!   as AAD, so changing a password (which rewrites a keyslot) does not
//!   invalidate the body.

use serde::{Deserialize, Serialize};

use crate::crypto::aead::NONCE_LEN;
use crate::crypto::kdf::{self, SALT_LEN};
use crate::crypto::keys::VAULT_KEY_LEN;
use crate::error::Error;

/// File magic, four ASCII bytes.
pub const MAGIC: [u8; 4] = *b"KYL1";

/// Current vault format version.
pub const FORMAT_VERSION: u16 = 1;

/// Length of the random vault identifier in bytes.
pub const VAULT_ID_LEN: usize = 16;

/// Length of a wrapped vault key: 32 bytes ciphertext + 16-byte tag.
pub const WRAPPED_KEY_LEN: usize = VAULT_KEY_LEN + 16;

/// Maximum accepted CBOR header size in bytes.
pub const MAX_HEADER_LEN: usize = 64 * 1024;

/// Maximum number of keyslots in a header.
pub const MAX_SLOTS: usize = 4;

/// What a keyslot unlocks.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SlotKind {
    /// Master-password slot (Argon2id).
    Master,
    /// Recovery-key slot (HKDF).
    Recovery,
}

/// KDF configuration for one keyslot.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum KdfParams {
    /// Argon2id parameters and salt for the master slot.
    Argon2id {
        /// Memory cost in KiB.
        m_kib: u32,
        /// Time cost.
        t: u32,
        /// Parallelism.
        p: u32,
        /// Random salt.
        salt: [u8; SALT_LEN],
    },
    /// HKDF-SHA256 salt for the recovery slot.
    HkdfSha256 {
        /// Random salt.
        salt: [u8; SALT_LEN],
    },
}

impl KdfParams {
    /// Validate the parameters before using them.
    pub fn validate(&self) -> Result<(), Error> {
        match self {
            Self::Argon2id { m_kib, t, p, .. } => kdf::Argon2Params {
                m_kib: *m_kib,
                t: *t,
                p: *p,
            }
            .validate()
            .map(|_| ()),
            Self::HkdfSha256 { .. } => Ok(()),
        }
    }

    /// Borrow the salt for this slot.
    pub fn salt(&self) -> &[u8; SALT_LEN] {
        match self {
            Self::Argon2id { salt, .. } | Self::HkdfSha256 { salt } => salt,
        }
    }
}

/// One encrypted copy of the vault key.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Keyslot {
    /// What credential this slot accepts.
    pub kind: SlotKind,
    /// KDF configuration.
    pub kdf: KdfParams,
    /// XChaCha20-Poly1305 nonce for the wrapped key.
    pub nonce: [u8; NONCE_LEN],
    /// Wrapped vault key (48 bytes: 32-byte key + 16-byte tag).
    pub wrapped_key: Vec<u8>,
}

impl Keyslot {
    /// Validate a slot read from disk.
    pub fn validate(&self) -> Result<(), Error> {
        if self.wrapped_key.len() != WRAPPED_KEY_LEN {
            return Err(Error::Corrupted);
        }
        self.kdf.validate()
    }

    /// AAD binding this slot to its kind and KDF parameters.
    pub(crate) fn aad(&self) -> Vec<u8> {
        let mut aad = b"KYL1-SLOT".to_vec();
        aad.push(1); // slot AAD version
        aad.push(match self.kind {
            SlotKind::Master => 1,
            SlotKind::Recovery => 2,
        });
        match &self.kdf {
            KdfParams::Argon2id { m_kib, t, p, salt } => {
                aad.push(1);
                aad.extend_from_slice(&m_kib.to_le_bytes());
                aad.extend_from_slice(&t.to_le_bytes());
                aad.extend_from_slice(&p.to_le_bytes());
                aad.extend_from_slice(salt);
            }
            KdfParams::HkdfSha256 { salt } => {
                aad.push(2);
                aad.extend_from_slice(salt);
            }
        }
        aad
    }
}

/// The plaintext header stored at the start of every vault file.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Header {
    /// Format version. Must match the outer file version.
    pub format_version: u16,
    /// Stable random identifier, authenticated as part of the body AAD.
    pub vault_id: [u8; VAULT_ID_LEN],
    /// Master and recovery keyslots.
    pub slots: Vec<Keyslot>,
}

impl Header {
    /// Build a header for the current format version.
    pub fn new(vault_id: [u8; VAULT_ID_LEN], slots: Vec<Keyslot>) -> Self {
        Self {
            format_version: FORMAT_VERSION,
            vault_id,
            slots,
        }
    }

    /// Validate the header read from an untrusted file.
    pub fn validate(&self) -> Result<(), Error> {
        if self.format_version != FORMAT_VERSION {
            return Err(Error::UnsupportedVersion(self.format_version));
        }
        if self.slots.is_empty() || self.slots.len() > MAX_SLOTS {
            return Err(Error::Corrupted);
        }

        let mut has_master = false;
        let mut has_recovery = false;
        for slot in &self.slots {
            slot.validate()?;
            match slot.kind {
                SlotKind::Master => {
                    if has_master {
                        return Err(Error::Corrupted);
                    }
                    has_master = true;
                }
                SlotKind::Recovery => {
                    if has_recovery {
                        return Err(Error::Corrupted);
                    }
                    has_recovery = true;
                }
            }
        }
        if !has_master {
            return Err(Error::Corrupted);
        }
        Ok(())
    }

    /// Find a slot by kind.
    pub fn slot(&self, kind: SlotKind) -> Option<&Keyslot> {
        self.slots.iter().find(|slot| slot.kind == kind)
    }
}
