//! `vault.keyel` file encoding and decoding.
//!
//! Layout:
//!
//! ```text
//! magic "KYL1" (4) | format_version u16 LE (2) | header_len u32 LE (4)
//! header (CBOR, exactly header_len bytes)
//! body_nonce (24) | body_ciphertext + tag (rest)
//! ```
//!
//! The body AAD is `magic || format_version || vault_id`. It deliberately
//! excludes the keyslots so changing the master password can rewrap a keyslot
//! without rewriting the encrypted vault body.

use std::fmt;

use zeroize::Zeroizing;

use crate::crypto::aead::{self, NONCE_LEN, TAG_LEN};
use crate::crypto::kdf::{derive_kek, Argon2Params, SALT_LEN};
use crate::crypto::keys::{Kek, VaultKey};
use crate::crypto::random_array;
use crate::crypto::recovery::{derive_recovery_kek, RecoveryKey};
use crate::error::Error;

use super::header::{
    Header, KdfParams, Keyslot, SlotKind, FORMAT_VERSION, MAGIC, MAX_HEADER_LEN, VAULT_ID_LEN,
    WRAPPED_KEY_LEN,
};

const PREFIX_LEN: usize = MAGIC.len() + 2 + 4;

/// Result of creating a new vault file.
#[derive(Debug)]
pub struct CreatedVault {
    /// Encrypted file bytes ready to be written to `vault.keyel`.
    pub bytes: Vec<u8>,
    /// Human-readable recovery key. Show it once, then discard it.
    pub recovery_key: String,
}

/// A successfully decrypted vault.
///
/// `plaintext` is the opaque vault payload (CBOR in phase 0.3+). It is wiped
/// on drop. The `Debug` implementation intentionally omits it.
pub struct UnlockedVault {
    /// The authenticated header.
    pub header: Header,
    /// The vault key, kept in Rust for later saves.
    pub vault_key: VaultKey,
    /// The decrypted vault payload.
    pub plaintext: Zeroizing<Vec<u8>>,
}

impl fmt::Debug for UnlockedVault {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("UnlockedVault")
            .field("header", &self.header)
            .field("vault_key", &self.vault_key)
            .field(
                "plaintext",
                &format_args!("[REDACTED {} bytes]", self.plaintext.len()),
            )
            .finish()
    }
}

/// Create a new vault with a master-password slot and a recovery slot.
pub fn create(master: &str, plaintext: &[u8], params: Argon2Params) -> Result<CreatedVault, Error> {
    params.validate()?;

    let vault_key = VaultKey::generate();
    let vault_id: [u8; VAULT_ID_LEN] = random_array();

    let master_salt: [u8; SALT_LEN] = random_array();
    let master_kdf = KdfParams::Argon2id {
        m_kib: params.m_kib,
        t: params.t,
        p: params.p,
        salt: master_salt,
    };
    let master_kek = derive_kek(master, &master_salt, &params)?;
    let master_slot = wrap_slot(SlotKind::Master, master_kdf, &master_kek, &vault_key)?;

    let recovery = RecoveryKey::generate();
    let recovery_salt: [u8; SALT_LEN] = random_array();
    let recovery_kdf = KdfParams::HkdfSha256 {
        salt: recovery_salt,
    };
    let recovery_kek = derive_recovery_kek(&recovery, &recovery_salt);
    let recovery_slot = wrap_slot(SlotKind::Recovery, recovery_kdf, &recovery_kek, &vault_key)?;

    let header = Header::new(vault_id, vec![master_slot, recovery_slot]);
    let bytes = seal(&header, plaintext, &vault_key)?;
    Ok(CreatedVault {
        bytes,
        recovery_key: recovery.to_string(),
    })
}

/// Encrypt a payload with an already-unlocked vault key.
pub fn seal(header: &Header, plaintext: &[u8], vault_key: &VaultKey) -> Result<Vec<u8>, Error> {
    header.validate()?;

    let header_bytes = encode_header(header)?;
    let header_len = u32::try_from(header_bytes.len()).map_err(|_| Error::Corrupted)?;

    let aad = body_aad(&header.vault_id);
    let (nonce, ciphertext) = aead::seal(vault_key.as_bytes(), plaintext, &aad)?;

    let mut out =
        Vec::with_capacity(PREFIX_LEN + header_bytes.len() + NONCE_LEN + ciphertext.len());
    out.extend_from_slice(&MAGIC);
    out.extend_from_slice(&FORMAT_VERSION.to_le_bytes());
    out.extend_from_slice(&header_len.to_le_bytes());
    out.extend_from_slice(&header_bytes);
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}

/// Unlock with the master password.
pub fn unlock_with_master(bytes: &[u8], master: &str) -> Result<UnlockedVault, Error> {
    let parsed = parse_file(bytes)?;
    let slot = parsed
        .header
        .slot(SlotKind::Master)
        .ok_or(Error::Corrupted)?;
    let params = argon2_params(slot)?;
    let kek = derive_kek(master, slot.kdf.salt(), &params)?;
    let vault_key = unwrap_slot(slot, &kek)?;
    let plaintext = open_body(&parsed.header, parsed.body, &vault_key)?;
    Ok(UnlockedVault {
        header: parsed.header,
        vault_key,
        plaintext,
    })
}

/// Unlock with the recovery key.
pub fn unlock_with_recovery(bytes: &[u8], recovery: &str) -> Result<UnlockedVault, Error> {
    let recovery = RecoveryKey::parse(recovery)?;
    let parsed = parse_file(bytes)?;
    let slot = parsed
        .header
        .slot(SlotKind::Recovery)
        .ok_or(Error::Corrupted)?;
    let salt = match &slot.kdf {
        KdfParams::HkdfSha256 { salt } => salt,
        KdfParams::Argon2id { .. } => return Err(Error::Corrupted),
    };
    let kek = derive_recovery_kek(&recovery, salt);
    let vault_key = unwrap_slot(slot, &kek)?;
    let plaintext = open_body(&parsed.header, parsed.body, &vault_key)?;
    Ok(UnlockedVault {
        header: parsed.header,
        vault_key,
        plaintext,
    })
}

/// Decrypt a file with an already-unwrapped vault key.
pub fn unlock_with_vault_key(bytes: &[u8], vault_key: &VaultKey) -> Result<UnlockedVault, Error> {
    let parsed = parse_file(bytes)?;
    let plaintext = open_body(&parsed.header, parsed.body, vault_key)?;
    Ok(UnlockedVault {
        header: parsed.header,
        vault_key: VaultKey::from_bytes(vault_key.as_bytes())?,
        plaintext,
    })
}

/// Re-wrap the vault key with a new master password.
///
/// Only the master keyslot changes. The encrypted body is copied byte for
/// byte, which keeps large vaults cheap to re-key and lets callers verify the
/// roadmap guarantee that "change master leaves the body untouched".
pub fn change_master(
    bytes: &[u8],
    old_master: &str,
    new_master: &str,
    params: Argon2Params,
) -> Result<Vec<u8>, Error> {
    params.validate()?;
    let parsed = parse_file(bytes)?;
    let slot = parsed
        .header
        .slot(SlotKind::Master)
        .ok_or(Error::Corrupted)?;
    let old_params = argon2_params(slot)?;
    let old_kek = derive_kek(old_master, slot.kdf.salt(), &old_params)?;
    let vault_key = unwrap_slot(slot, &old_kek)?;

    let new_salt: [u8; SALT_LEN] = random_array();
    let new_kdf = KdfParams::Argon2id {
        m_kib: params.m_kib,
        t: params.t,
        p: params.p,
        salt: new_salt,
    };
    let new_kek = derive_kek(new_master, &new_salt, &params)?;
    let new_slot = wrap_slot(SlotKind::Master, new_kdf, &new_kek, &vault_key)?;

    let mut header = parsed.header;
    let index = header
        .slots
        .iter()
        .position(|slot| slot.kind == SlotKind::Master)
        .ok_or(Error::Corrupted)?;
    header.slots[index] = new_slot;
    header.validate()?;

    let header_bytes = encode_header(&header)?;
    let header_len = u32::try_from(header_bytes.len()).map_err(|_| Error::Corrupted)?;

    let mut out = Vec::with_capacity(PREFIX_LEN + header_bytes.len() + parsed.body.len());
    out.extend_from_slice(&MAGIC);
    out.extend_from_slice(&FORMAT_VERSION.to_le_bytes());
    out.extend_from_slice(&header_len.to_le_bytes());
    out.extend_from_slice(&header_bytes);
    out.extend_from_slice(parsed.body);
    Ok(out)
}

fn wrap_slot(
    kind: SlotKind,
    kdf: KdfParams,
    kek: &Kek,
    vault_key: &VaultKey,
) -> Result<Keyslot, Error> {
    let nonce: [u8; NONCE_LEN] = random_array();
    let mut slot = Keyslot {
        kind,
        kdf,
        nonce,
        wrapped_key: Vec::new(),
    };
    let aad = slot.aad();
    slot.wrapped_key = aead::seal_with_nonce(kek.as_bytes(), &nonce, vault_key.as_bytes(), &aad)?;
    if slot.wrapped_key.len() != WRAPPED_KEY_LEN {
        return Err(Error::Crypto);
    }
    Ok(slot)
}

fn unwrap_slot(slot: &Keyslot, kek: &Kek) -> Result<VaultKey, Error> {
    let aad = slot.aad();
    let plaintext = aead::open(kek.as_bytes(), &slot.nonce, &slot.wrapped_key, &aad)?;
    VaultKey::from_bytes(&plaintext[..])
}

fn open_body(
    header: &Header,
    body: &[u8],
    vault_key: &VaultKey,
) -> Result<Zeroizing<Vec<u8>>, Error> {
    if body.len() < NONCE_LEN + TAG_LEN {
        return Err(Error::Corrupted);
    }
    let nonce: [u8; NONCE_LEN] = body[..NONCE_LEN].try_into().map_err(|_| Error::Corrupted)?;
    let ciphertext = &body[NONCE_LEN..];
    let aad = body_aad(&header.vault_id);
    aead::open(vault_key.as_bytes(), &nonce, ciphertext, &aad)
}

fn argon2_params(slot: &Keyslot) -> Result<Argon2Params, Error> {
    match &slot.kdf {
        KdfParams::Argon2id { m_kib, t, p, .. } => Ok(Argon2Params {
            m_kib: *m_kib,
            t: *t,
            p: *p,
        }),
        KdfParams::HkdfSha256 { .. } => Err(Error::Corrupted),
    }
}

fn encode_header(header: &Header) -> Result<Vec<u8>, Error> {
    let mut bytes = Vec::new();
    ciborium::into_writer(header, &mut bytes).map_err(|_| Error::Corrupted)?;
    if bytes.is_empty() || bytes.len() > MAX_HEADER_LEN {
        return Err(Error::Corrupted);
    }
    Ok(bytes)
}

fn body_aad(vault_id: &[u8; VAULT_ID_LEN]) -> Vec<u8> {
    let mut aad = Vec::with_capacity(MAGIC.len() + 2 + VAULT_ID_LEN);
    aad.extend_from_slice(&MAGIC);
    aad.extend_from_slice(&FORMAT_VERSION.to_le_bytes());
    aad.extend_from_slice(vault_id);
    aad
}

struct Parsed<'a> {
    header: Header,
    body: &'a [u8],
}

fn parse_file(bytes: &[u8]) -> Result<Parsed<'_>, Error> {
    if bytes.len() < PREFIX_LEN + NONCE_LEN + TAG_LEN {
        return Err(Error::Corrupted);
    }
    if &bytes[..MAGIC.len()] != MAGIC.as_slice() {
        return Err(Error::Corrupted);
    }
    let version = u16::from_le_bytes([bytes[4], bytes[5]]);
    if version != FORMAT_VERSION {
        return Err(Error::UnsupportedVersion(version));
    }
    let header_len = u32::from_le_bytes([bytes[6], bytes[7], bytes[8], bytes[9]]) as usize;
    if header_len == 0 || header_len > MAX_HEADER_LEN {
        return Err(Error::Corrupted);
    }
    let body_offset = PREFIX_LEN.checked_add(header_len).ok_or(Error::Corrupted)?;
    let minimum = body_offset
        .checked_add(NONCE_LEN + TAG_LEN)
        .ok_or(Error::Corrupted)?;
    if bytes.len() < minimum {
        return Err(Error::Corrupted);
    }

    let header_bytes = &bytes[PREFIX_LEN..body_offset];
    let header: Header = ciborium::from_reader(header_bytes).map_err(|_| Error::Corrupted)?;
    header.validate()?;
    if header.format_version != version {
        return Err(Error::Corrupted);
    }
    // Require the canonical encoding we would produce ourselves. Without this
    // check, CBOR aliases such as a changed array-length marker (16 -> 17) can
    // parse to the same struct and silently bypass the byte-flip guarantee.
    if encode_header(&header)? != header_bytes {
        return Err(Error::Corrupted);
    }

    Ok(Parsed {
        header,
        body: &bytes[body_offset..],
    })
}
