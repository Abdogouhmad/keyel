//! Versioned, authenticated sync blob envelope.
//!
//! The blob is what lives in the user-chosen sync folder. It has a fixed
//! binary header (no CBOR aliases) followed by an XChaCha20-Poly1305 payload.
//! All routing metadata is authenticated as associated data, so a blob from
//! another sync group cannot be relabeled, and sequence numbers cannot be
//! edited without invalidating the ciphertext.
//!
//! ```text
//! 0       4    magic = "KYS1"
//! 4       2    format_version = 1 (u16 LE)
//! 6       16   sync_id
//! 22      16   writer_device_id
//! 38      8    sequence (u64 LE)
//! 46      24   nonce
//! 70      n    ciphertext (payload + 16-byte Poly1305 tag)
//! ```

use zeroize::Zeroizing;

use crate::crypto::aead;
use crate::crypto::random_array;
use crate::Error;

/// Magic bytes of a Keyel sync blob.
pub const SYNC_MAGIC: &[u8; 4] = b"KYS1";
/// Only this envelope version is understood.
pub const SYNC_FORMAT_VERSION: u16 = 1;
/// Length of the fixed header before the nonce.
pub const HEADER_LEN: usize = 4 + 2 + 16 + 16 + 8 + 24;
const NONCE_OFFSET: usize = HEADER_LEN - aead::NONCE_LEN;
const AAD_DOMAIN: &[u8] = b"KYS1-SYNC/v1";

/// Non-secret routing metadata of a sync blob.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncBlobHeader {
    pub format_version: u16,
    pub sync_id: [u8; 16],
    pub device_id: [u8; 16],
    pub sequence: u64,
}

/// Encrypt a sync payload into a blob for one device.
pub fn seal(
    sync_key: &[u8; 32],
    sync_id: &[u8; 16],
    device_id: &[u8; 16],
    sequence: u64,
    payload: &[u8],
) -> Result<Vec<u8>, Error> {
    let nonce = random_array::<{ aead::NONCE_LEN }>();
    let aad = build_aad(SYNC_FORMAT_VERSION, sync_id, device_id, sequence);
    let ciphertext = aead::seal_with_nonce(sync_key, &nonce, payload, &aad)?;

    let mut out = Vec::with_capacity(HEADER_LEN + ciphertext.len());
    out.extend_from_slice(SYNC_MAGIC);
    out.extend_from_slice(&SYNC_FORMAT_VERSION.to_le_bytes());
    out.extend_from_slice(sync_id);
    out.extend_from_slice(device_id);
    out.extend_from_slice(&sequence.to_le_bytes());
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}

/// Authenticate and decrypt a sync blob.
///
/// Authentication failures are reported as [`Error::WrongPassword`] (the same
/// coarse error as a vault body failure) so callers cannot distinguish a bad
/// sync key from tampering.
pub fn open(
    sync_key: &[u8; 32],
    bytes: &[u8],
) -> Result<(SyncBlobHeader, Zeroizing<Vec<u8>>), Error> {
    if bytes.len() < HEADER_LEN + aead::TAG_LEN {
        return Err(Error::Corrupted);
    }
    if &bytes[..4] != SYNC_MAGIC {
        return Err(Error::Corrupted);
    }
    let format_version = u16::from_le_bytes([bytes[4], bytes[5]]);
    if format_version != SYNC_FORMAT_VERSION {
        return Err(Error::UnsupportedVersion(format_version));
    }

    let mut sync_id = [0u8; 16];
    sync_id.copy_from_slice(&bytes[6..22]);
    let mut device_id = [0u8; 16];
    device_id.copy_from_slice(&bytes[22..38]);
    let sequence = u64::from_le_bytes(bytes[38..46].try_into().map_err(|_| Error::Corrupted)?);
    let nonce: &[u8; aead::NONCE_LEN] = bytes[NONCE_OFFSET..HEADER_LEN]
        .try_into()
        .map_err(|_| Error::Corrupted)?;

    let aad = build_aad(format_version, &sync_id, &device_id, sequence);
    let plaintext = aead::open(sync_key, nonce, &bytes[HEADER_LEN..], &aad)?;
    Ok((
        SyncBlobHeader {
            format_version,
            sync_id,
            device_id,
            sequence,
        },
        plaintext,
    ))
}

fn build_aad(
    format_version: u16,
    sync_id: &[u8; 16],
    device_id: &[u8; 16],
    sequence: u64,
) -> Vec<u8> {
    let mut aad = Vec::with_capacity(AAD_DOMAIN.len() + 2 + 16 + 16 + 8);
    aad.extend_from_slice(AAD_DOMAIN);
    aad.extend_from_slice(&format_version.to_le_bytes());
    aad.extend_from_slice(sync_id);
    aad.extend_from_slice(device_id);
    aad.extend_from_slice(&sequence.to_le_bytes());
    aad
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key() -> [u8; 32] {
        [7u8; 32]
    }

    fn ids() -> ([u8; 16], [u8; 16]) {
        let mut sync_id = [0u8; 16];
        sync_id[0] = 1;
        let mut device_id = [0u8; 16];
        device_id[0] = 2;
        (sync_id, device_id)
    }

    #[test]
    fn round_trip_preserves_header_and_payload() {
        let (sync_id, device_id) = ids();
        let blob = seal(&key(), &sync_id, &device_id, 42, b"hello sync").unwrap();
        let (header, plaintext) = open(&key(), &blob).unwrap();
        assert_eq!(header.format_version, SYNC_FORMAT_VERSION);
        assert_eq!(header.sync_id, sync_id);
        assert_eq!(header.device_id, device_id);
        assert_eq!(header.sequence, 42);
        assert_eq!(&plaintext[..], b"hello sync");
    }

    #[test]
    fn wrong_key_is_rejected() {
        let (sync_id, device_id) = ids();
        let blob = seal(&key(), &sync_id, &device_id, 1, b"secret").unwrap();
        let mut wrong = key();
        wrong[0] ^= 1;
        assert_eq!(open(&wrong, &blob).unwrap_err(), Error::WrongPassword);
    }

    #[test]
    fn tampered_header_fields_are_rejected() {
        let (sync_id, device_id) = ids();
        let blob = seal(&key(), &sync_id, &device_id, 9, b"payload").unwrap();

        let mut bad_magic = blob.clone();
        bad_magic[0] ^= 1;
        assert_eq!(open(&key(), &bad_magic).unwrap_err(), Error::Corrupted);

        let mut bad_version = blob.clone();
        bad_version[5] ^= 1;
        assert!(matches!(
            open(&key(), &bad_version).unwrap_err(),
            Error::UnsupportedVersion(_)
        ));

        let mut bad_sync = blob.clone();
        bad_sync[6] ^= 1;
        assert_eq!(open(&key(), &bad_sync).unwrap_err(), Error::WrongPassword);

        let mut bad_device = blob.clone();
        bad_device[22] ^= 1;
        assert_eq!(open(&key(), &bad_device).unwrap_err(), Error::WrongPassword);

        let mut bad_sequence = blob.clone();
        bad_sequence[38] ^= 1;
        assert_eq!(
            open(&key(), &bad_sequence).unwrap_err(),
            Error::WrongPassword
        );

        let mut bad_nonce = blob.clone();
        bad_nonce[NONCE_OFFSET] ^= 1;
        assert_eq!(open(&key(), &bad_nonce).unwrap_err(), Error::WrongPassword);

        let mut bad_ciphertext = blob;
        let last = bad_ciphertext.len() - 1;
        bad_ciphertext[last] ^= 1;
        assert_eq!(
            open(&key(), &bad_ciphertext).unwrap_err(),
            Error::WrongPassword
        );
    }

    #[test]
    fn truncated_and_empty_blobs_are_corrupted() {
        let (sync_id, device_id) = ids();
        let blob = seal(&key(), &sync_id, &device_id, 1, b"x").unwrap();
        assert_eq!(open(&key(), &[]).unwrap_err(), Error::Corrupted);
        for len in [1, 4, HEADER_LEN - 1, HEADER_LEN + aead::TAG_LEN - 1] {
            assert_eq!(open(&key(), &blob[..len]).unwrap_err(), Error::Corrupted);
        }
    }

    #[test]
    fn fresh_nonce_makes_equal_payloads_differ() {
        let (sync_id, device_id) = ids();
        let a = seal(&key(), &sync_id, &device_id, 1, b"same").unwrap();
        let b = seal(&key(), &sync_id, &device_id, 1, b"same").unwrap();
        assert_ne!(a, b);
    }
}
