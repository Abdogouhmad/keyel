//! WebAuthn/passkey ceremony primitives.
//!
//! Implements the minimal cryptographic and data-structure operations needed to
//! create and assert passkeys (ES256 / P-256) inside the Rust trust boundary.
//!
//! # Security
//! - Private key material is handled as bytes/vectors that callers must store in
//!   the encrypted vault and zeroize appropriately; this module never logs or
//!   persists secrets.
//! - RP/origin binding is enforced by callers supplying the expected RP ID and
//!   request parameters from the platform; response construction uses only the
//!   provided, validated inputs.
//! - Attestation uses `fmt = "none"` (no attestation statement) which is the
//!   common choice for software authenticators/password managers.

use ciborium::value::{Integer, Value};
use p256::ecdsa::signature::Signer;
use p256::ecdsa::{Signature, SigningKey};
use p256::elliptic_curve::Generate;
use p256::pkcs8::{DecodePrivateKey, EncodePrivateKey};
use serde::Deserialize;
use sha2::{Digest, Sha256};
use thiserror::Error;
use zeroize::Zeroizing;

/// Errors from passkey/WebAuthn operations.
#[derive(Debug, Error)]
pub enum PasskeyError {
    /// The request or stored data is malformed/unsupported.
    #[error("invalid passkey data")]
    InvalidData,
    /// Cryptographic operation failed.
    #[error("crypto error")]
    Crypto,
    /// JSON parsing/serialization failed.
    #[error("json error")]
    Json,
    /// CBOR encoding failed.
    #[error("cbor error")]
    Cbor,
}

/// Result alias for passkey operations.
pub type Result<T> = std::result::Result<T, PasskeyError>;

/// Output of generating/storing a new passkey credential.
#[derive(Clone)]
pub struct GeneratedPasskey {
    /// Credential ID bytes (random identifier).
    pub credential_id: Vec<u8>,
    /// COSE-encoded public key bytes.
    pub public_key_cose: Vec<u8>,
    /// Private key material in PKCS#8 DER form. Secret; zeroized on drop so a
    /// transient copy cannot outlive the credential ceremony.
    pub private_key_pkcs8: Zeroizing<Vec<u8>>,
    /// COSE algorithm identifier (-7 for ES256).
    pub algorithm: i32,
}

impl std::fmt::Debug for GeneratedPasskey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("GeneratedPasskey")
            .field("credential_id", &self.credential_id)
            .field("public_key_cose", &self.public_key_cose)
            .field("private_key_pkcs8", &"[REDACTED]")
            .field("algorithm", &self.algorithm)
            .finish()
    }
}

/// Generate a new ES256 (P-256) credential.
pub fn generate_es256_credential() -> Result<GeneratedPasskey> {
    let signing_key = SigningKey::generate();
    let verify_key = signing_key.verifying_key();

    let private_key_pkcs8 = Zeroizing::new(
        signing_key
            .to_pkcs8_der()
            .map_err(|_| PasskeyError::Crypto)?
            .as_bytes()
            .to_vec(),
    );

    let point = verify_key.to_sec1_point(false);
    let x = point.x().ok_or(PasskeyError::Crypto)?.to_vec();
    let y = point.y().ok_or(PasskeyError::Crypto)?.to_vec();
    let public_key_cose = encode_cose_ec2_p256_public_key(&x, &y, -7)?;

    let credential_id = <[u8; 32] as Generate>::generate().to_vec();

    Ok(GeneratedPasskey {
        credential_id,
        public_key_cose,
        private_key_pkcs8,
        algorithm: -7,
    })
}

/// Encode an uncompressed P-256 public key as a COSE_Key map (CBOR bytes).
///
/// COSE key for ES256: {1:2, 3:alg, -1:1, -2:x, -3:y}
pub fn encode_cose_ec2_p256_public_key(x: &[u8], y: &[u8], alg: i32) -> Result<Vec<u8>> {
    if x.len() != 32 || y.len() != 32 {
        return Err(PasskeyError::InvalidData);
    }
    let key = Value::Map(vec![
        (Value::Integer(1.into()), Value::Integer(2.into())), // kty: EC2
        (Value::Integer(3.into()), Value::Integer(Integer::from(alg))), // alg
        (Value::Integer(Integer::from(-1)), Value::Integer(1.into())), // crv: P-256
        (Value::Integer(Integer::from(-2)), Value::Bytes(x.to_vec())),
        (Value::Integer(Integer::from(-3)), Value::Bytes(y.to_vec())),
    ]);
    let mut out = Vec::new();
    ciborium::into_writer(&key, &mut out).map_err(|_| PasskeyError::Cbor)?;
    Ok(out)
}

/// Compute SHA-256 hash.
pub fn sha256(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let out = hasher.finalize();
    let mut arr = [0u8; 32];
    arr.copy_from_slice(&out);
    arr
}

/// Base64url encode without padding.
pub fn b64url_encode(data: &[u8]) -> String {
    data_encoding::BASE64URL_NOPAD.encode(data)
}

/// Base64url decode without padding (accepts missing padding).
pub fn b64url_decode(s: &str) -> Result<Vec<u8>> {
    data_encoding::BASE64URL_NOPAD
        .decode(s.as_bytes())
        .or_else(|_| {
            // Try with padding added if needed.
            let mut padded = s.to_string();
            while !padded.len().is_multiple_of(4) {
                padded.push('=');
            }
            data_encoding::BASE64URL.decode(padded.as_bytes())
        })
        .map_err(|_| PasskeyError::InvalidData)
}

/// Minimal fields extracted from a WebAuthn creation request JSON.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateRequest {
    /// Challenge (base64url).
    pub challenge: String,
    /// Relying party info.
    pub rp: RpEntity,
    /// User info.
    pub user: UserEntity,
    /// Optional authenticator selection hints (ignored except for future use).
    #[serde(default)]
    pub authenticator_selection: Option<AuthenticatorSelection>,
}

/// Relying party entity.
#[derive(Debug, Clone, Deserialize)]
pub struct RpEntity {
    /// RP ID (e.g. "example.com").
    pub id: String,
    /// RP display name.
    #[serde(default)]
    pub name: String,
}

/// User entity for creation.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UserEntity {
    /// User handle (base64url bytes).
    pub id: String,
    /// User name.
    #[serde(default)]
    pub name: String,
    /// Display name.
    #[serde(default)]
    pub display_name: String,
}

/// Authenticator selection criteria (subset).
#[derive(Debug, Clone, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthenticatorSelection {
    /// "required", "preferred", or "discouraged".
    #[serde(default)]
    pub resident_key: Option<String>,
    /// "platform" or "cross-platform".
    #[serde(default)]
    pub authenticator_attachment: Option<String>,
    /// "required"/"preferred"/"discouraged".
    #[serde(default)]
    pub user_verification: Option<String>,
}

/// Minimal fields extracted from a WebAuthn get/assertion request JSON.
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GetRequest {
    /// Challenge (base64url).
    pub challenge: String,
    /// Relying party ID.
    #[serde(default)]
    pub rp_id: Option<String>,
    /// Allowed credentials.
    #[serde(default)]
    pub allow_credentials: Vec<AllowCredential>,
}

/// Allowed credential descriptor.
#[derive(Debug, Clone, Deserialize)]
pub struct AllowCredential {
    /// Credential ID (base64url).
    pub id: String,
    /// Type (usually "public-key").
    #[serde(rename = "type", default)]
    pub cred_type: String,
}

/// Parse a creation request JSON.
pub fn parse_create_request(json: &str) -> Result<CreateRequest> {
    serde_json::from_str(json).map_err(|_| PasskeyError::Json)
}

/// Parse a get/assertion request JSON.
pub fn parse_get_request(json: &str) -> Result<GetRequest> {
    serde_json::from_str(json).map_err(|_| PasskeyError::Json)
}

/// Build clientDataJSON bytes for a create or get ceremony.
///
/// `typ` is `"webauthn.create"` or `"webauthn.get"`.
/// `challenge_b64url` is the challenge as base64url string (as in request).
/// `origin` is the caller origin (e.g. `https://example.com` or
/// `android:apk-key-hash:<hash>`).
pub fn build_client_data_json(typ: &str, challenge_b64url: &str, origin: &str) -> Vec<u8> {
    // Keep field order simple/stable; JSON string values are properly escaped by serde_json.
    let obj = serde_json::json!({
        "type": typ,
        "challenge": challenge_b64url,
        "origin": origin,
        "crossOrigin": false
    });
    serde_json::to_vec(&obj).unwrap_or_else(|_| {
        format!(
            "{{\"type\":\"{}\",\"challenge\":\"{}\",\"origin\":\"{}\",\"crossOrigin\":false}}",
            typ, challenge_b64url, origin
        )
        .into_bytes()
    })
}

/// Build authenticator data for attestation (credential creation).
///
/// Flags: UP|UV|BE|BS|AT set (0x5D) for a discoverable user-verified credential.
/// AAGUID is 16 zero bytes.
pub fn build_attestation_auth_data(
    rp_id: &str,
    sign_count: u32,
    credential_id: &[u8],
    credential_public_key_cose: &[u8],
) -> Result<Vec<u8>> {
    let rp_id_hash = sha256(rp_id.as_bytes());
    let flags: u8 = 0x01 /* UP */ | 0x04 /* UV */ | 0x08 /* BE */ | 0x10 /* BS */ | 0x40 /* AT */;

    let mut out =
        Vec::with_capacity(37 + 16 + 2 + credential_id.len() + credential_public_key_cose.len());
    out.extend_from_slice(&rp_id_hash);
    out.push(flags);
    out.extend_from_slice(&sign_count.to_be_bytes());

    // Attested credential data
    out.extend_from_slice(&[0u8; 16]); // AAGUID
    let cred_id_len = u16::try_from(credential_id.len()).map_err(|_| PasskeyError::InvalidData)?;
    out.extend_from_slice(&cred_id_len.to_be_bytes());
    out.extend_from_slice(credential_id);
    out.extend_from_slice(credential_public_key_cose);

    Ok(out)
}

/// Build an attestation object (CBOR) with `fmt = "none"`.
pub fn build_attestation_object_none(auth_data: &[u8]) -> Result<Vec<u8>> {
    let obj = Value::Map(vec![
        (
            Value::Text("fmt".to_string()),
            Value::Text("none".to_string()),
        ),
        (Value::Text("attStmt".to_string()), Value::Map(vec![])),
        (
            Value::Text("authData".to_string()),
            Value::Bytes(auth_data.to_vec()),
        ),
    ]);
    let mut out = Vec::new();
    ciborium::into_writer(&obj, &mut out).map_err(|_| PasskeyError::Cbor)?;
    Ok(out)
}

/// Build the JSON response for a create (registration) ceremony.
///
/// Returns `PublicKeyCredential` JSON with `response.attestationObject`,
/// `response.clientDataJSON`, etc., suitable for Credential Manager.
pub fn build_create_response_json(
    credential_id: &[u8],
    client_data_json: &[u8],
    attestation_object: &[u8],
    _transports: &[String],
) -> Result<String> {
    // Android/Credential Manager expects standard WebAuthn fields.
    let resp = serde_json::json!({
        "id": b64url_encode(credential_id),
        "rawId": b64url_encode(credential_id),
        "type": "public-key",
        "authenticatorAttachment": "platform",
        "response": {
            "clientDataJSON": b64url_encode(client_data_json),
            "attestationObject": b64url_encode(attestation_object),
            "transports": ["internal"]
        },
        "clientExtensionResults": {}
    });
    serde_json::to_string(&resp).map_err(|_| PasskeyError::Json)
}

/// Build authenticator data for assertion (get).
///
/// Flags: UP|UV|BE|BS set (0x1D), no AT/ED.
pub fn build_assertion_auth_data(rp_id: &str, sign_count: u32) -> [u8; 37] {
    let rp_id_hash = sha256(rp_id.as_bytes());
    let flags: u8 = 0x01 /* UP */ | 0x04 /* UV */ | 0x08 /* BE */ | 0x10 /* BS */;
    let mut out = [0u8; 37];
    out[..32].copy_from_slice(&rp_id_hash);
    out[32] = flags;
    out[33..37].copy_from_slice(&sign_count.to_be_bytes());
    out
}

/// Sign an assertion with an ES256 private key (PKCS#8 DER).
///
/// Signature is over `auth_data || SHA256(client_data_json)`.
pub fn sign_assertion(
    private_key_pkcs8: &[u8],
    auth_data: &[u8],
    client_data_json: &[u8],
) -> Result<Vec<u8>> {
    let signing_key =
        SigningKey::from_pkcs8_der(private_key_pkcs8).map_err(|_| PasskeyError::Crypto)?;
    let client_hash = sha256(client_data_json);

    let mut msg = Vec::with_capacity(auth_data.len() + client_hash.len());
    msg.extend_from_slice(auth_data);
    msg.extend_from_slice(&client_hash);

    let sig: Signature = signing_key.sign(&msg);
    // WebAuthn expects DER-encoded ECDSA signature.
    Ok(sig.to_der().as_bytes().to_vec())
}

/// Build the JSON response for a get (assertion) ceremony.
pub fn build_get_response_json(
    credential_id: &[u8],
    client_data_json: &[u8],
    auth_data: &[u8],
    signature: &[u8],
    user_handle: &[u8],
) -> Result<String> {
    let resp = serde_json::json!({
        "id": b64url_encode(credential_id),
        "rawId": b64url_encode(credential_id),
        "type": "public-key",
        "authenticatorAttachment": "platform",
        "response": {
            "clientDataJSON": b64url_encode(client_data_json),
            "authenticatorData": b64url_encode(auth_data),
            "signature": b64url_encode(signature),
            "userHandle": b64url_encode(user_handle),
        },
        "clientExtensionResults": {}
    });
    serde_json::to_string(&resp).map_err(|_| PasskeyError::Json)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generated_passkey_debug_redacts_private_key() {
        let credential = GeneratedPasskey {
            credential_id: vec![1, 2, 3],
            public_key_cose: vec![4, 5],
            private_key_pkcs8: Zeroizing::new(b"SENTINEL-PKCS8".to_vec()),
            algorithm: -7,
        };
        let debug = format!("{credential:?}");
        assert!(!debug.contains("SENTINEL"), "secret leaked: {debug}");
        assert!(debug.contains("[REDACTED]"));
    }

    #[test]
    fn b64url_round_trip() {
        let data = b"\x00\x01\x02\xfe\xff hello";
        let enc = b64url_encode(data);
        assert!(!enc.contains('='));
        assert_eq!(b64url_decode(&enc).unwrap(), data);
    }

    #[test]
    fn parse_create_and_get_requests() {
        let create = r#"{
            "challenge":"AQID",
            "rp":{"id":"example.com","name":"Example"},
            "user":{"id":"BQYH","name":"ada","displayName":"Ada"}
        }"#;
        let req = parse_create_request(create).unwrap();
        assert_eq!(req.rp.id, "example.com");
        assert_eq!(req.user.name, "ada");

        let get = r#"{"challenge":"AQID","rpId":"example.com","allowCredentials":[{"id":"AgME","type":"public-key"}]}"#;
        let greq = parse_get_request(get).unwrap();
        assert_eq!(greq.rp_id.as_deref(), Some("example.com"));
        assert_eq!(greq.allow_credentials.len(), 1);
    }

    #[test]
    fn generate_credential_and_build_attestation() {
        let cred = generate_es256_credential().unwrap();
        assert_eq!(cred.credential_id.len(), 32);
        assert_eq!(cred.algorithm, -7);
        assert!(!cred.private_key_pkcs8.is_empty());
        assert!(!cred.public_key_cose.is_empty());

        let client_data = build_client_data_json("webauthn.create", "AQID", "https://example.com");
        let auth_data = build_attestation_auth_data(
            "example.com",
            0,
            &cred.credential_id,
            &cred.public_key_cose,
        )
        .unwrap();
        assert!(auth_data.len() > 37);
        assert_eq!(&auth_data[32..33], &[0x5D]); // UP|UV|BE|BS|AT

        let att_obj = build_attestation_object_none(&auth_data).unwrap();
        assert!(!att_obj.is_empty());

        let json =
            build_create_response_json(&cred.credential_id, &client_data, &att_obj, &[]).unwrap();
        assert!(json.contains("\"type\":\"public-key\""));
        assert!(json.contains("\"attestationObject\""));
    }

    #[test]
    fn sign_and_build_assertion() {
        let cred = generate_es256_credential().unwrap();
        let client_data = build_client_data_json("webauthn.get", "AQID", "https://example.com");
        let auth_data = build_assertion_auth_data("example.com", 1);
        assert_eq!(auth_data[32], 0x1D);

        let sig = sign_assertion(&cred.private_key_pkcs8, &auth_data, &client_data).unwrap();
        assert!(!sig.is_empty());

        let json =
            build_get_response_json(&cred.credential_id, &client_data, &auth_data, &sig, b"user")
                .unwrap();
        assert!(json.contains("\"signature\""));
        assert!(json.contains("\"authenticatorData\""));
    }
}
