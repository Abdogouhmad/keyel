//! XChaCha20-Poly1305 sealing and opening.
//!
//! Every call to [`seal`] generates a fresh random 24-byte nonce. Callers
//! that need a deterministic nonce (tests, or a keyslot already carrying its
//! own nonce) use [`seal_with_nonce`].

use chacha20poly1305::aead::{Aead, KeyInit, Payload};
use chacha20poly1305::{XChaCha20Poly1305, XNonce};
use zeroize::Zeroizing;

use crate::crypto::random_array;
use crate::error::Error;

/// XChaCha20-Poly1305 nonce length in bytes.
pub const NONCE_LEN: usize = 24;

/// Poly1305 authentication tag length in bytes.
pub const TAG_LEN: usize = 16;

/// Encrypt with a fresh random nonce.
pub(crate) fn seal(
    key: &[u8; 32],
    plaintext: &[u8],
    aad: &[u8],
) -> Result<([u8; NONCE_LEN], Vec<u8>), Error> {
    let nonce: [u8; NONCE_LEN] = random_array();
    let ciphertext = seal_with_nonce(key, &nonce, plaintext, aad)?;
    Ok((nonce, ciphertext))
}

/// Encrypt with an explicit nonce.
///
/// Only use this when the nonce is already stored alongside the ciphertext
/// (keyslots) or in a test. Reusing a nonce with the same key breaks the AEAD.
pub(crate) fn seal_with_nonce(
    key: &[u8; 32],
    nonce: &[u8; NONCE_LEN],
    plaintext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>, Error> {
    let cipher = XChaCha20Poly1305::new_from_slice(key).map_err(|_| Error::Crypto)?;
    cipher
        .encrypt(
            XNonce::from_slice(nonce),
            Payload {
                msg: plaintext,
                aad,
            },
        )
        .map_err(|_| Error::Crypto)
}

/// Decrypt and authenticate.
///
/// Any failure is reported as [`Error::WrongPassword`] so callers cannot
/// distinguish a bad key from a modified ciphertext or AAD.
pub(crate) fn open(
    key: &[u8; 32],
    nonce: &[u8; NONCE_LEN],
    ciphertext: &[u8],
    aad: &[u8],
) -> Result<Zeroizing<Vec<u8>>, Error> {
    if ciphertext.len() < TAG_LEN {
        return Err(Error::WrongPassword);
    }
    let cipher = XChaCha20Poly1305::new_from_slice(key).map_err(|_| Error::WrongPassword)?;
    let plaintext = cipher
        .decrypt(
            XNonce::from_slice(nonce),
            Payload {
                msg: ciphertext,
                aad,
            },
        )
        .map_err(|_| Error::WrongPassword)?;
    Ok(Zeroizing::new(plaintext))
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY: [u8; 32] = [7u8; 32];
    const NONCE: [u8; NONCE_LEN] = [9u8; NONCE_LEN];

    #[test]
    fn round_trip() {
        let plaintext = b"top secret";
        let aad = b"header";
        let ciphertext = seal_with_nonce(&KEY, &NONCE, plaintext, aad).unwrap();
        let opened = open(&KEY, &NONCE, &ciphertext, aad).unwrap();
        assert_eq!(&opened[..], plaintext);
    }

    #[test]
    fn wrong_key_fails() {
        let ciphertext = seal_with_nonce(&KEY, &NONCE, b"secret", b"aad").unwrap();
        let mut other = KEY;
        other[0] ^= 1;
        assert_eq!(
            open(&other, &NONCE, &ciphertext, b"aad").unwrap_err(),
            Error::WrongPassword
        );
    }

    #[test]
    fn tampered_ciphertext_fails() {
        let mut ciphertext = seal_with_nonce(&KEY, &NONCE, b"secret", b"aad").unwrap();
        ciphertext[0] ^= 1;
        assert_eq!(
            open(&KEY, &NONCE, &ciphertext, b"aad").unwrap_err(),
            Error::WrongPassword
        );
    }

    #[test]
    fn tampered_aad_fails() {
        let ciphertext = seal_with_nonce(&KEY, &NONCE, b"secret", b"aad").unwrap();
        assert_eq!(
            open(&KEY, &NONCE, &ciphertext, b"other").unwrap_err(),
            Error::WrongPassword
        );
    }

    #[test]
    fn nonce_is_fresh_and_ciphertext_differs() {
        let (n1, c1) = seal(&KEY, b"same", b"").unwrap();
        let (n2, c2) = seal(&KEY, b"same", b"").unwrap();
        assert_ne!(n1, n2);
        assert_ne!(c1, c2);
    }

    #[test]
    fn short_ciphertext_is_rejected() {
        assert_eq!(
            open(&KEY, &NONCE, &[0u8; 3], b"").unwrap_err(),
            Error::WrongPassword
        );
    }
}
