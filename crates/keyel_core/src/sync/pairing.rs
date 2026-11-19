//! One-time pairing code for establishing a sync group.
//!
//! The first device shows the code once; the joiner scans/enters it to obtain
//! the same `sync_id` and `sync_key`. The code is a **bearer secret** — treat it
//! like the vault recovery key (show once, never log, never screenshot). The
//! short tag detects typos and truncated scans; it is not an authentication
//! mechanism. Every blob's AEAD tag authenticates the actual key.

use data_encoding::BASE32_NOPAD;
use sha2::{Digest, Sha256};
use zeroize::Zeroizing;

use crate::crypto::random_array;
use crate::Error;

const PREFIX: &str = "KYSYNC1-";
const DOMAIN: &[u8] = b"KYSYNC1/pairing/v1";
const SYNC_ID_LEN: usize = 16;
const SYNC_KEY_LEN: usize = 32;
const TAG_LEN: usize = 4;
const PAYLOAD_LEN: usize = SYNC_ID_LEN + SYNC_KEY_LEN + TAG_LEN;

/// A freshly generated or scanned sync pairing.
#[derive(Debug, Clone)]
pub struct PairingCode {
    /// Non-secret id of the sync group; stored in every blob header.
    pub sync_id: [u8; SYNC_ID_LEN],
    /// Shared secret. Zeroized on drop; never leaves Rust.
    pub sync_key: Zeroizing<[u8; SYNC_KEY_LEN]>,
}

impl PairingCode {
    /// Generate a new sync group and key from the OS CSPRNG.
    pub fn generate() -> Self {
        Self {
            sync_id: random_array::<SYNC_ID_LEN>(),
            sync_key: Zeroizing::new(random_array::<SYNC_KEY_LEN>()),
        }
    }

    /// Encode as a copyable/QR-scannable string.
    pub fn encode(&self) -> String {
        let mut raw = Vec::with_capacity(PAYLOAD_LEN);
        raw.extend_from_slice(&self.sync_id);
        raw.extend_from_slice(&self.sync_key[..]);
        raw.extend_from_slice(&tag(&self.sync_id, &self.sync_key));
        format!("{PREFIX}{}", BASE32_NOPAD.encode(&raw))
    }

    /// Parse a pairing code, rejecting bad formatting, length or typos.
    pub fn parse(input: &str) -> Result<Self, Error> {
        let trimmed = input.trim();
        let upper = trimmed.to_ascii_uppercase();
        let body = upper
            .strip_prefix(PREFIX)
            .ok_or(Error::InvalidRecoveryKey)?;
        let compact: String = body
            .chars()
            .filter(|c| !c.is_whitespace() && *c != '-')
            .collect();
        let raw = BASE32_NOPAD
            .decode(compact.as_bytes())
            .map_err(|_| Error::InvalidRecoveryKey)?;
        if raw.len() != PAYLOAD_LEN {
            return Err(Error::InvalidRecoveryKey);
        }

        let mut sync_id = [0u8; SYNC_ID_LEN];
        sync_id.copy_from_slice(&raw[..SYNC_ID_LEN]);
        let mut key_bytes = [0u8; SYNC_KEY_LEN];
        key_bytes.copy_from_slice(&raw[SYNC_ID_LEN..SYNC_ID_LEN + SYNC_KEY_LEN]);
        let sync_key = Zeroizing::new(key_bytes);

        if tag(&sync_id, &sync_key) != raw[SYNC_ID_LEN + SYNC_KEY_LEN..] {
            return Err(Error::InvalidRecoveryKey);
        }

        Ok(Self { sync_id, sync_key })
    }
}

fn tag(sync_id: &[u8; SYNC_ID_LEN], sync_key: &[u8; SYNC_KEY_LEN]) -> [u8; TAG_LEN] {
    let mut hasher = Sha256::new();
    hasher.update(DOMAIN);
    hasher.update(sync_id);
    hasher.update(sync_key);
    let digest = hasher.finalize();
    let mut out = [0u8; TAG_LEN];
    out.copy_from_slice(&digest[..TAG_LEN]);
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generated_code_round_trips() {
        let code = PairingCode::generate();
        let encoded = code.encode();
        assert!(encoded.starts_with(PREFIX));
        let decoded = PairingCode::parse(&encoded).unwrap();
        assert_eq!(decoded.sync_id, code.sync_id);
        assert_eq!(&decoded.sync_key[..], &code.sync_key[..]);
    }

    #[test]
    fn generated_keys_are_distinct() {
        let a = PairingCode::generate();
        let b = PairingCode::generate();
        assert_ne!(a.sync_id, b.sync_id);
        assert_ne!(&a.sync_key[..], &b.sync_key[..]);
    }

    #[test]
    fn formatting_is_tolerated() {
        let code = PairingCode::generate();
        let encoded = code.encode();
        let body = &encoded[PREFIX.len()..];
        let spaced = format!("{}\n  {}-{}\t", PREFIX, &body[..10], &body[10..]);
        let decoded = PairingCode::parse(&spaced).unwrap();
        assert_eq!(decoded.sync_id, code.sync_id);
    }

    #[test]
    fn malformed_and_tampered_codes_are_rejected() {
        let code = PairingCode::generate();
        let encoded = code.encode();
        assert!(PairingCode::parse("").is_err());
        assert!(PairingCode::parse("NOT-A-CODE").is_err());
        assert!(PairingCode::parse(&encoded[..encoded.len() - 2]).is_err());
        let mut chars: Vec<char> = encoded.chars().collect();
        let last = chars.len() - 1;
        chars[last] = if chars[last] == 'A' { 'B' } else { 'A' };
        assert!(PairingCode::parse(&chars.into_iter().collect::<String>()).is_err());
    }
}
