//! Time-based one-time passwords (RFC 6238) and their HOTP base (RFC 4226).
//!
//! Everything here is pure and deterministic: callers pass the Unix time, so
//! the same code path is unit-tested against the RFC vectors and reused by the
//! bridge without a clock dependency.
//!
//! The stored secret is a base32 string (the format services print next to a
//! QR code). [`decode_base32`] tolerates the spacing and padding variants seen
//! in the wild; [`parse_otpauth`] reads a full `otpauth://` URI.

use data_encoding::BASE32_NOPAD;
use hmac::{Hmac, Mac};
use sha1::Sha1;
use sha2::{Sha256, Sha512};

use crate::vault::model::{TotpAlgorithm, TotpConfig};

/// Errors produced while decoding a secret or computing a code.
#[derive(Debug, thiserror::Error, Clone, PartialEq, Eq)]
pub enum TotpError {
    /// The secret is not valid base32.
    #[error("invalid base32 secret")]
    InvalidBase32,
    /// The URI is not a well-formed `otpauth://totp/...` URI.
    #[error("invalid otpauth URI")]
    InvalidUri,
    /// The algorithm is not one of SHA1/SHA256/SHA512.
    #[error("unsupported TOTP algorithm")]
    UnsupportedAlgorithm,
    /// The digit count is outside the accepted 4..=10 range.
    #[error("invalid TOTP digit count")]
    InvalidDigits,
    /// The period is zero.
    #[error("invalid TOTP period")]
    InvalidPeriod,
}

impl TotpConfig {
    /// Validate every field, including that the secret decodes as base32.
    pub fn validate(&self) -> Result<(), TotpError> {
        decode_base32(&self.secret)?;
        if !(4..=10).contains(&self.digits) {
            return Err(TotpError::InvalidDigits);
        }
        if self.period == 0 {
            return Err(TotpError::InvalidPeriod);
        }
        Ok(())
    }
}

/// Normalise a user-supplied secret: drop spaces and hyphens, upper-case the
/// letters and strip base32 padding (`=`).
pub fn normalize_secret(secret: &str) -> String {
    secret
        .chars()
        .filter(|c| !c.is_whitespace() && *c != '-')
        .filter(|c| *c != '=')
        .map(|c| c.to_ascii_uppercase())
        .collect()
}

/// Decode a base32 secret, tolerating spacing, lower-case and padding.
pub fn decode_base32(secret: &str) -> Result<Vec<u8>, TotpError> {
    let normalized = normalize_secret(secret);
    if normalized.is_empty() {
        return Err(TotpError::InvalidBase32);
    }
    BASE32_NOPAD
        .decode(normalized.as_bytes())
        .map_err(|_| TotpError::InvalidBase32)
}

/// HOTP value for a counter (RFC 4226 §5.3).
///
/// `digits` is validated against 4..=10; the dynamic truncation always uses the
/// low four bytes regardless of the hash size, as the RFC specifies.
pub fn hotp(
    secret: &[u8],
    counter: u64,
    digits: u8,
    algorithm: TotpAlgorithm,
) -> Result<String, TotpError> {
    if !(4..=10).contains(&digits) {
        return Err(TotpError::InvalidDigits);
    }

    // The three HMAC types differ, so each arm finalises into bytes and the
    // dynamic truncation works on the resulting digest.
    let counter_bytes = counter.to_be_bytes();
    let digest: Vec<u8> = match algorithm {
        TotpAlgorithm::Sha1 => {
            let mut mac =
                Hmac::<Sha1>::new_from_slice(secret).expect("HMAC accepts keys of any length");
            mac.update(&counter_bytes);
            mac.finalize().into_bytes().to_vec()
        }
        TotpAlgorithm::Sha256 => {
            let mut mac =
                Hmac::<Sha256>::new_from_slice(secret).expect("HMAC accepts keys of any length");
            mac.update(&counter_bytes);
            mac.finalize().into_bytes().to_vec()
        }
        TotpAlgorithm::Sha512 => {
            let mut mac =
                Hmac::<Sha512>::new_from_slice(secret).expect("HMAC accepts keys of any length");
            mac.update(&counter_bytes);
            mac.finalize().into_bytes().to_vec()
        }
    };
    let offset = (digest[digest.len() - 1] & 0x0f) as usize;
    let binary = ((u64::from(digest[offset]) & 0x7f) << 24)
        | (u64::from(digest[offset + 1]) << 16)
        | (u64::from(digest[offset + 2]) << 8)
        | u64::from(digest[offset + 3]);

    let modulus = 10u64.pow(u32::from(digits));
    let code = binary % modulus;
    Ok(format!("{code:0width$}", width = usize::from(digits)))
}

/// TOTP value for `config` at `unix_time` (RFC 6238 §4.2).
pub fn generate_code(config: &TotpConfig, unix_time: u64) -> Result<String, TotpError> {
    config.validate()?;
    let secret = decode_base32(&config.secret)?;
    let counter = unix_time / u64::from(config.period);
    hotp(&secret, counter, config.digits, config.algorithm)
}

/// Seconds until the current code rolls over (1..=`period`).
pub fn seconds_left(config: &TotpConfig, unix_time: u64) -> u32 {
    let period = u64::from(config.period.max(1));
    let elapsed = unix_time % period;
    (period - elapsed) as u32
}

/// Parse an `otpauth://totp/...` URI into a [`TotpConfig`].
///
/// Unknown parameters are ignored; `secret` is required and `algorithm`,
/// `digits` and `period` fall back to the RFC defaults (SHA1 / 6 / 30).
pub fn parse_otpauth(uri: &str) -> Result<TotpConfig, TotpError> {
    let trimmed = uri.trim();
    let rest = trimmed
        .strip_prefix("otpauth://")
        .ok_or(TotpError::InvalidUri)?;

    let (path, query) = match rest.split_once('?') {
        Some((path, query)) => (path, Some(query)),
        None => (rest, None),
    };

    // Only the `totp` type is supported; `hotp` counters are out of scope.
    let (kind, _label) = path.split_once('/').ok_or(TotpError::InvalidUri)?;
    if !kind.eq_ignore_ascii_case("totp") {
        return Err(TotpError::InvalidUri);
    }

    let query = query.ok_or(TotpError::InvalidUri)?;
    let mut secret = None;
    let mut algorithm = TotpAlgorithm::Sha1;
    let mut digits = 6u8;
    let mut period = 30u32;

    for pair in query.split('&') {
        if pair.is_empty() {
            continue;
        }
        let (key, value) = pair.split_once('=').unwrap_or((pair, ""));
        let value = percent_decode(value);
        match key.to_ascii_lowercase().as_str() {
            "secret" => secret = Some(value),
            "algorithm" => {
                algorithm = match value.to_ascii_uppercase().as_str() {
                    "SHA1" => TotpAlgorithm::Sha1,
                    "SHA256" => TotpAlgorithm::Sha256,
                    "SHA512" => TotpAlgorithm::Sha512,
                    _ => return Err(TotpError::UnsupportedAlgorithm),
                };
            }
            "digits" => {
                digits = value.parse().map_err(|_| TotpError::InvalidDigits)?;
            }
            "period" => {
                period = value.parse().map_err(|_| TotpError::InvalidPeriod)?;
            }
            _ => {}
        }
    }

    let config = TotpConfig {
        secret: secret.ok_or(TotpError::InvalidUri)?,
        algorithm,
        digits,
        period,
    };
    config.validate()?;
    Ok(config)
}

/// Minimal `%XX` decoder for query values (enough for the fields we read).
fn percent_decode(value: &str) -> String {
    if !value.contains('%') {
        return value.to_owned();
    }
    let bytes = value.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            let hex = std::str::from_utf8(&bytes[i + 1..i + 3]).ok();
            if let Some(byte) = hex.and_then(|h| u8::from_str_radix(h, 16).ok()) {
                out.push(byte);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config(secret: &str, algorithm: TotpAlgorithm, digits: u8, period: u32) -> TotpConfig {
        TotpConfig {
            secret: secret.to_owned(),
            algorithm,
            digits,
            period,
        }
    }

    /// RFC 4226 Appendix D: SHA-1, secret "12345678901234567890", 6 digits.
    #[test]
    fn rfc4226_hotp_vectors() {
        let secret = b"12345678901234567890";
        let expected = [
            "755224", "287082", "359152", "969429", "338314", "254676", "287922", "162583",
            "399871", "520489",
        ];
        for (counter, code) in expected.iter().enumerate() {
            assert_eq!(
                hotp(secret, counter as u64, 6, TotpAlgorithm::Sha1).unwrap(),
                *code,
                "counter {counter}"
            );
        }
    }

    /// RFC 6238 Appendix B: 8-digit SHA-1/256/512 vectors. The RFC uses raw
    /// ASCII secrets of 20/32/64 bytes.
    #[test]
    fn rfc6238_totp_vectors() {
        let sha1_secret = "12345678901234567890";
        let sha256_secret = "12345678901234567890123456789012";
        let sha512_secret = "1234567890123456789012345678901234567890123456789012345678901234";

        let cases: [(u64, [&str; 3]); 6] = [
            (59, ["94287082", "46119246", "90693936"]),
            (1111111109, ["07081804", "68084774", "25091201"]),
            (1111111111, ["14050471", "67062674", "99943326"]),
            (1234567890, ["89005924", "91819424", "93441116"]),
            (2000000000, ["69279037", "90698825", "38618901"]),
            (20000000000, ["65353130", "77737706", "47863826"]),
        ];

        for (time, [sha1, sha256, sha512]) in cases {
            let counter = time / 30;
            assert_eq!(
                hotp(sha1_secret.as_bytes(), counter, 8, TotpAlgorithm::Sha1).unwrap(),
                sha1,
                "sha1 t={time}"
            );
            assert_eq!(
                hotp(sha256_secret.as_bytes(), counter, 8, TotpAlgorithm::Sha256).unwrap(),
                sha256,
                "sha256 t={time}"
            );
            assert_eq!(
                hotp(sha512_secret.as_bytes(), counter, 8, TotpAlgorithm::Sha512).unwrap(),
                sha512,
                "sha512 t={time}"
            );
        }
    }

    #[test]
    fn base32_variants_decode_identically() {
        // "12345678901234567890" in base32.
        let canonical = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        let spaced = "gezd gnbv gy3t qojq gezd gnbv gy3t qojq";
        let padded = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ=";
        assert_eq!(decode_base32(canonical).unwrap(), b"12345678901234567890");
        assert_eq!(decode_base32(spaced).unwrap(), b"12345678901234567890");
        assert_eq!(decode_base32(padded).unwrap(), b"12345678901234567890");
    }

    #[test]
    fn malformed_base32_is_rejected() {
        assert_eq!(decode_base32(""), Err(TotpError::InvalidBase32));
        assert_eq!(decode_base32("1890"), Err(TotpError::InvalidBase32));
    }

    #[test]
    fn seconds_left_wraps_on_period() {
        let c = config(
            "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
            TotpAlgorithm::Sha1,
            6,
            30,
        );
        assert_eq!(seconds_left(&c, 0), 30);
        assert_eq!(seconds_left(&c, 1), 29);
        assert_eq!(seconds_left(&c, 29), 1);
        assert_eq!(seconds_left(&c, 30), 30);
        assert_eq!(seconds_left(&c, 59), 1);
    }

    #[test]
    fn period_and_digits_are_honoured() {
        let secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        let six = config(secret, TotpAlgorithm::Sha1, 6, 30);
        let eight = config(secret, TotpAlgorithm::Sha1, 8, 30);
        assert_eq!(generate_code(&six, 59).unwrap(), "287082");
        assert_eq!(generate_code(&eight, 59).unwrap(), "94287082");

        // A 60-second period keeps the same counter across two 30s windows.
        let slow = config(secret, TotpAlgorithm::Sha1, 6, 60);
        assert_eq!(
            generate_code(&slow, 59).unwrap(),
            generate_code(&slow, 30).unwrap()
        );
    }

    #[test]
    fn parse_otpauth_full_uri() {
        let uri = "otpauth://totp/Example:alice@example.com\
            ?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ\
            &issuer=Example&algorithm=SHA256&digits=8&period=45";
        let parsed = parse_otpauth(uri).unwrap();
        assert_eq!(parsed.secret, "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ");
        assert_eq!(parsed.algorithm, TotpAlgorithm::Sha256);
        assert_eq!(parsed.digits, 8);
        assert_eq!(parsed.period, 45);
    }

    #[test]
    fn parse_otpauth_defaults() {
        let uri = "otpauth://totp/Example?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        let parsed = parse_otpauth(uri).unwrap();
        assert_eq!(parsed.algorithm, TotpAlgorithm::Sha1);
        assert_eq!(parsed.digits, 6);
        assert_eq!(parsed.period, 30);
    }

    #[test]
    fn parse_otpauth_rejects_bad_input() {
        assert_eq!(
            parse_otpauth("https://example.com"),
            Err(TotpError::InvalidUri)
        );
        assert_eq!(
            parse_otpauth("otpauth://totp/Example"),
            Err(TotpError::InvalidUri)
        );
        assert_eq!(
            parse_otpauth("otpauth://totp/Example?secret=abc"),
            Err(TotpError::InvalidBase32)
        );
        assert_eq!(
            parse_otpauth("otpauth://totp/Example?secret=GEZDGNBVGY3TQOJQ&algorithm=MD5"),
            Err(TotpError::UnsupportedAlgorithm)
        );
        assert_eq!(
            parse_otpauth("otpauth://hotp/Example?secret=GEZDGNBVGY3TQOJQ&counter=1"),
            Err(TotpError::InvalidUri)
        );
    }
}
