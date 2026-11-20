//! HIBP k-anonymity helpers.
//!
//! SHA-1 is used here only for protocol compatibility with the Pwned Passwords
//! range API. It is **not** a password storage scheme. The full digest is a
//! secret: it stays in Rust, wrapped in `Zeroizing`, and only its first five
//! hex characters are ever handed to Dart for the HTTPS request.
//!
//! This module is pure so the hashing, prefix/suffix split and response parser
//! can be tested with known-answer vectors without a session or network.

use data_encoding::HEXUPPER;
use sha1::{Digest, Sha1};
use zeroize::Zeroizing;

/// Number of leading hex characters sent to the HIBP range endpoint.
pub const PREFIX_LEN: usize = 5;

/// Length of an uppercase SHA-1 hex digest.
const DIGEST_HEX_LEN: usize = 40;

/// Length of the suffix HIBP returns in a range response line.
const SUFFIX_LEN: usize = DIGEST_HEX_LEN - PREFIX_LEN;

/// An HIBP range response could not be interpreted safely.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BreachResponseError {
    /// The caller supplied a suffix that is not 35 hex characters.
    InvalidSuffix,
}

/// Compute the uppercase hex SHA-1 digest of a password.
///
/// The result is a secret derived from a password. Keep it zeroized and never
/// return it across the bridge.
pub fn sha1_hex(password: &str) -> Zeroizing<String> {
    let mut hasher = Sha1::new();
    hasher.update(password.as_bytes());
    Zeroizing::new(HEXUPPER.encode(&hasher.finalize()))
}

/// Split a well-formed uppercase hex digest into its range prefix and suffix.
pub fn split_digest(digest_hex: &str) -> Option<(&str, &str)> {
    if digest_hex.len() != DIGEST_HEX_LEN
        || !digest_hex.bytes().all(|byte| byte.is_ascii_hexdigit())
    {
        return None;
    }
    Some(digest_hex.split_at(PREFIX_LEN))
}

/// The 5-character prefix Dart may send to HIBP.
pub fn prefix_of(digest_hex: &str) -> Option<String> {
    split_digest(digest_hex).map(|(prefix, _)| prefix.to_string())
}

/// The remaining 35 characters, compared locally against a range response.
pub fn suffix_of(digest_hex: &str) -> Option<String> {
    split_digest(digest_hex).map(|(_, suffix)| suffix.to_string())
}

/// Whether a range body is made only of well-formed `SUFFIX:COUNT` lines.
///
/// An empty body is valid: HIBP may return 200 with no hashes for a rare
/// prefix. A non-empty body containing any malformed line is rejected by the
/// caller so a broken or HTML error page cannot be read as an all-clear.
pub fn is_well_formed_body(body: &str) -> bool {
    body.lines().all(|line| {
        let line = line.trim();
        if line.is_empty() {
            return true;
        }
        let Some((suffix, count)) = line.split_once(':') else {
            return false;
        };
        suffix.len() == SUFFIX_LEN
            && suffix.bytes().all(|byte| byte.is_ascii_hexdigit())
            && count.trim().parse::<u32>().is_ok()
    })
}

/// Find the breach count for `suffix` in an HIBP range response body.
///
/// Lines are `SUFFIX:COUNT`, separated by CR/LF. Callers validate the whole
/// body with [`is_well_formed_body`] first; malformed lines are still skipped
/// here as defence in depth. Duplicate suffixes keep the largest count.
pub fn count_for_suffix(body: &str, suffix: &str) -> Result<Option<u32>, BreachResponseError> {
    if suffix.len() != SUFFIX_LEN || !suffix.bytes().all(|byte| byte.is_ascii_hexdigit()) {
        return Err(BreachResponseError::InvalidSuffix);
    }

    let mut found = None;
    for line in body.lines() {
        let line = line.trim_end_matches('\r');
        if line.is_empty() {
            continue;
        }
        let Some((candidate, count)) = line.split_once(':') else {
            continue;
        };
        if candidate.len() != SUFFIX_LEN || !candidate.bytes().all(|byte| byte.is_ascii_hexdigit())
        {
            continue;
        }
        let Ok(count) = count.trim().parse::<u32>() else {
            continue;
        };
        if candidate.eq_ignore_ascii_case(suffix) {
            found = Some(found.unwrap_or(0).max(count));
        }
    }
    Ok(found)
}

/// Generate an opaque, non-secret token to correlate one check's two phases.
pub fn new_token() -> String {
    let bytes: [u8; 16] = rand::random();
    HEXUPPER.encode(&bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha1_matches_hibp_known_answers() {
        // HIBP's own documentation uses "password": SHA-1 begins with 5BAA6.
        assert_eq!(
            *sha1_hex("password"),
            "5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8"
        );
        assert_eq!(*sha1_hex(""), "DA39A3EE5E6B4B0D3255BFEF95601890AFD80709");
    }

    #[test]
    fn digest_splits_into_prefix_and_suffix() {
        let digest = sha1_hex("password");
        assert_eq!(prefix_of(&digest).as_deref(), Some("5BAA6"));
        assert_eq!(
            suffix_of(&digest).as_deref(),
            Some("1E4C9B93F3F0682250B6CF8331B7EE68FD8")
        );
        assert_eq!(split_digest("5BAA6"), None);
        assert_eq!(split_digest(&"Z".repeat(DIGEST_HEX_LEN)), None);
    }

    #[test]
    fn parses_range_response_and_keeps_largest_duplicate_count() {
        let suffix = "1E4C9B93F3F0682250B6CF8331B7EE68FD8";
        let other = "F".repeat(SUFFIX_LEN);
        let absent = "0".repeat(SUFFIX_LEN);
        let malformed = "BAD".repeat(12);
        let body = format!(
            "{malformed}:1\r\n\
             {suffix}:3730471\r\n\
             {suffix}:2\r\n\
             {other}:9\r\n\
             malformed-line\r\n\
             BAD:1\r\n\r\n"
        );
        assert_eq!(count_for_suffix(&body, suffix), Ok(Some(3730471)));
        assert_eq!(count_for_suffix(&body, &other), Ok(Some(9)));
        assert_eq!(count_for_suffix(&body, &absent), Ok(None));
    }

    #[test]
    fn validates_whole_range_bodies() {
        let suffix = "1E4C9B93F3F0682250B6CF8331B7EE68FD8";
        assert!(is_well_formed_body(""));
        assert!(is_well_formed_body("\r\n"));
        assert!(is_well_formed_body(&format!("{suffix}:3730471\r\n")));
        assert!(!is_well_formed_body("<html>Service unavailable</html>"));
        assert!(!is_well_formed_body(&format!("{suffix}:nope")));
        assert!(!is_well_formed_body(&format!("BAD:{suffix}:1")));
    }

    #[test]
    fn rejects_invalid_suffixes() {
        assert_eq!(
            count_for_suffix("", "short"),
            Err(BreachResponseError::InvalidSuffix)
        );
        assert_eq!(
            count_for_suffix("", &"G".repeat(SUFFIX_LEN)),
            Err(BreachResponseError::InvalidSuffix)
        );
    }

    #[test]
    fn tokens_are_opaque_and_unique() {
        let first = new_token();
        let second = new_token();
        assert_eq!(first.len(), 32);
        assert_ne!(first, second);
    }
}
