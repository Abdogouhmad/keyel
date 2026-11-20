//! Passkey (WebAuthn) management and ceremony APIs exposed to Dart.
//!
//! These APIs expose only secret-free operations and state updates where
//! possible. Private key material and ceremony signing must stay inside
//! Rust/session boundaries and must never be logged or included in
//! diagnostics. Storage APIs accept key material only to persist it into the
//! encrypted vault; callers must not retain copies after the call.

use keyel_core::autofill::{find_passkeys_for_rp, record_passkey_use};
use keyel_core::passkey::{
    b64url_decode, build_assertion_auth_data, build_attestation_auth_data,
    build_attestation_object_none, build_client_data_json, build_create_response_json,
    build_get_response_json, generate_es256_credential, parse_create_request, parse_get_request,
    sign_assertion,
};
use keyel_core::vault::{now_unix, Entry, EntryBody, Passkey};

use super::entries::parse_id;
use super::error::VaultApiError;
use super::models::EntrySummaryDto;
use super::session::with_session;

/// Input for creating/storing a passkey credential.
///
/// All byte fields are stored encrypted at rest inside the vault. `private_key`
/// is secret and is never exposed back to Dart/UI through read APIs.
#[derive(Clone)]
pub struct PasskeyCreateDto {
    /// Entry title shown in the vault.
    pub title: String,
    /// Relying Party identifier (e.g. `example.com`).
    pub rp_id: String,
    /// Human-readable relying party name.
    pub rp_name: String,
    /// Credential identifier bytes.
    pub credential_id: Vec<u8>,
    /// User handle bytes provided by the relying party.
    pub user_handle: Vec<u8>,
    /// Account/user name.
    pub user_name: String,
    /// Display name for the account/user.
    pub user_display_name: String,
    /// COSE public key bytes.
    pub public_key: Vec<u8>,
    /// Private key material. Secret.
    pub private_key: Vec<u8>,
    /// COSE algorithm identifier (e.g. -7 ES256, -257 RS256, -8 EdDSA).
    pub algorithm: i32,
    /// Signature counter.
    pub sign_count: u32,
    /// Transport hints (e.g. `internal`, `usb`, `nfc`, `ble`, `hybrid`).
    pub transports: Vec<String>,
    /// Whether the credential is discoverable/resident.
    pub discoverable: bool,
}

impl std::fmt::Debug for PasskeyCreateDto {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("PasskeyCreateDto")
            .field("title", &self.title)
            .field("rp_id", &self.rp_id)
            .field("rp_name", &self.rp_name)
            .field("credential_id", &self.credential_id)
            .field("user_handle", &self.user_handle)
            .field("user_name", &self.user_name)
            .field("user_display_name", &self.user_display_name)
            .field("public_key", &self.public_key)
            .field("private_key", &"[REDACTED]")
            .field("algorithm", &self.algorithm)
            .field("sign_count", &self.sign_count)
            .field("transports", &self.transports)
            .field("discoverable", &self.discoverable)
            .finish()
    }
}

/// Result of creating/registering a passkey via a WebAuthn ceremony.
#[derive(Debug, Clone)]
pub struct PasskeyCreateResultDto {
    /// Created vault entry id.
    pub entry_id: String,
    /// WebAuthn credential creation response JSON to return to the platform.
    pub response_json: String,
}

/// Store a new passkey entry in the unlocked vault.
///
/// Returns the created entry id. Private key material is written only to the
/// encrypted vault payload and is zeroized in-memory by normal vault handling.
pub fn store_passkey(passkey: PasskeyCreateDto) -> Result<String, VaultApiError> {
    let title = passkey.title.trim();
    let rp_id = passkey.rp_id.trim();
    if title.is_empty() || rp_id.is_empty() || passkey.credential_id.is_empty() {
        return Err(VaultApiError::InvalidField);
    }

    with_session(|session| {
        let now = now_unix();
        let entry = Entry::passkey(
            title.to_string(),
            Passkey {
                rp_id: rp_id.to_string(),
                rp_name: passkey.rp_name,
                credential_id: passkey.credential_id,
                user_handle: passkey.user_handle,
                user_name: passkey.user_name,
                user_display_name: passkey.user_display_name,
                public_key: passkey.public_key,
                private_key: passkey.private_key,
                algorithm: passkey.algorithm,
                sign_count: passkey.sign_count,
                created_at: now,
                last_used_at: None,
                transports: passkey.transports,
                discoverable: passkey.discoverable,
            },
        );
        let id = session.vault_mut().add_entry(entry);
        session.save()?;
        Ok(id.to_string())
    })
}

/// List passkey entries matching a relying party ID.
///
/// Returns secret-free summaries suitable for candidate selection during a
/// WebAuthn get/create ceremony. Matching is case-insensitive on the RP ID.
pub fn list_passkeys_for_rp(rp_id: String) -> Result<Vec<EntrySummaryDto>, VaultApiError> {
    with_session(|session| {
        Ok(find_passkeys_for_rp(session.vault(), &rp_id)
            .into_iter()
            .map(EntrySummaryDto::from)
            .collect())
    })
}

/// Record a successful passkey assertion use.
///
/// Updates the stored signature counter and `last_used_at` timestamp, then
/// persists the vault. Returns [`VaultApiError::NotFound`] if the entry does not
/// exist or is not a passkey.
pub fn record_passkey_sign_count(id: String, sign_count: u32) -> Result<(), VaultApiError> {
    with_session(|session| {
        let id = parse_id(&id)?;
        if !record_passkey_use(session.vault_mut(), id, sign_count, now_unix()) {
            return Err(VaultApiError::NotFound);
        }
        session.save()?;
        Ok(())
    })
}

/// Delete a passkey entry by moving it to trash.
///
/// This is a convenience wrapper for passkey management flows.
pub fn delete_passkey(id: String) -> Result<(), VaultApiError> {
    with_session(|session| {
        let id = parse_id(&id)?;
        let entry = session.vault().entry(id).ok_or(VaultApiError::NotFound)?;
        if !matches!(entry.body, EntryBody::Passkey(_)) {
            return Err(VaultApiError::InvalidField);
        }
        session.vault_mut().delete_entry(id)?;
        session.save()?;
        Ok(())
    })
}

/// Create a new passkey from a WebAuthn creation request and return the
/// platform response.
///
/// This performs ES256 key generation, stores the credential in the encrypted
/// vault (private key never leaves Rust/session boundaries), and builds an
/// attestation response (`fmt = "none"`). The caller must provide the correct
/// `origin` for the requesting RP/context (e.g. `https://example.com` or
/// `android:apk-key-hash:<...>`).
pub fn create_passkey_for_request(
    request_json: String,
    origin: String,
) -> Result<PasskeyCreateResultDto, VaultApiError> {
    let req = parse_create_request(&request_json).map_err(|_| VaultApiError::InvalidField)?;
    let rp_id = req.rp.id.trim();
    if rp_id.is_empty() {
        return Err(VaultApiError::InvalidField);
    }

    let user_handle = b64url_decode(&req.user.id).map_err(|_| VaultApiError::InvalidField)?;
    let user_name = if req.user.name.is_empty() {
        req.user.display_name.clone()
    } else {
        req.user.name.clone()
    };
    let display_name = if req.user.display_name.is_empty() {
        user_name.clone()
    } else {
        req.user.display_name.clone()
    };

    let generated = generate_es256_credential().map_err(|_| VaultApiError::Internal)?;
    let sign_count = 0u32;

    let client_data = build_client_data_json("webauthn.create", &req.challenge, &origin);
    let auth_data = build_attestation_auth_data(
        rp_id,
        sign_count,
        &generated.credential_id,
        &generated.public_key_cose,
    )
    .map_err(|_| VaultApiError::Internal)?;
    let att_obj = build_attestation_object_none(&auth_data).map_err(|_| VaultApiError::Internal)?;
    let response_json =
        build_create_response_json(&generated.credential_id, &client_data, &att_obj, &[])
            .map_err(|_| VaultApiError::Internal)?;

    let rp_name = if req.rp.name.is_empty() {
        rp_id.to_string()
    } else {
        req.rp.name.clone()
    };
    let title = if user_name.is_empty() {
        rp_name.clone()
    } else {
        format!("{rp_name} ({user_name})")
    };

    let entry_id = with_session(|session| {
        let now = now_unix();
        let entry = Entry::passkey(
            title,
            Passkey {
                rp_id: rp_id.to_string(),
                rp_name: rp_name.clone(),
                credential_id: generated.credential_id.clone(),
                user_handle,
                user_name: user_name.clone(),
                user_display_name: display_name.clone(),
                public_key: generated.public_key_cose.clone(),
                private_key: generated.private_key_pkcs8.to_vec(),
                algorithm: generated.algorithm,
                sign_count,
                created_at: now,
                last_used_at: None,
                transports: vec!["internal".to_string()],
                discoverable: true,
            },
        );
        let id = session.vault_mut().add_entry(entry);
        session.save()?;
        Ok(id.to_string())
    })?;

    Ok(PasskeyCreateResultDto {
        entry_id,
        response_json,
    })
}

/// Build a WebAuthn assertion response for a stored passkey.
///
/// `credential_id_b64` selects a specific credential (as provided by the
/// platform selection). If omitted, the request is accepted only when there is
/// exactly one matching passkey for the RP. The signature counter is
/// incremented and persisted on success. Private key material never leaves
/// Rust/session boundaries.
pub fn get_passkey_assertion_response(
    request_json: String,
    origin: String,
    credential_id_b64: Option<String>,
) -> Result<String, VaultApiError> {
    let req = parse_get_request(&request_json).map_err(|_| VaultApiError::InvalidField)?;
    let rp_id = req
        .rp_id
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or(VaultApiError::InvalidField)?
        .to_string();

    with_session(|session| {
        // Resolve candidate entry id.
        let entry_id = if let Some(cred_b64) = credential_id_b64
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
        {
            let cred_bytes = b64url_decode(cred_b64).map_err(|_| VaultApiError::InvalidField)?;
            session
                .vault()
                .entries
                .iter()
                .find(|e| {
                    e.deleted_at.is_none()
                        && matches!(&e.body, EntryBody::Passkey(p)
                            if p.rp_id.eq_ignore_ascii_case(&rp_id) && p.credential_id == cred_bytes)
                })
                .map(|e| e.id)
                .ok_or(VaultApiError::NotFound)?
        } else {
            let matches = find_passkeys_for_rp(session.vault(), &rp_id);
            if matches.len() != 1 {
                return Err(VaultApiError::NotFound);
            }
            matches[0].id
        };

        // Read needed fields and sign.
        let (credential_id, user_handle, private_key, next_count) = {
            let entry = session
                .vault()
                .entry(entry_id)
                .ok_or(VaultApiError::NotFound)?;
            let EntryBody::Passkey(passkey) = &entry.body else {
                return Err(VaultApiError::InvalidField);
            };
            (
                passkey.credential_id.clone(),
                passkey.user_handle.clone(),
                passkey.private_key.clone(),
                passkey.sign_count.saturating_add(1),
            )
        };

        let client_data = build_client_data_json("webauthn.get", &req.challenge, &origin);
        let auth_data = build_assertion_auth_data(&rp_id, next_count);
        let signature = sign_assertion(&private_key, &auth_data, &client_data)
            .map_err(|_| VaultApiError::Internal)?;
        let response_json = build_get_response_json(
            &credential_id,
            &client_data,
            &auth_data,
            &signature,
            &user_handle,
        )
        .map_err(|_| VaultApiError::Internal)?;

        if !record_passkey_use(session.vault_mut(), entry_id, next_count, now_unix()) {
            return Err(VaultApiError::NotFound);
        }
        session.save()?;

        Ok(response_json)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn passkey_create_dto_debug_redacts_private_key() {
        const SENTINEL: &[u8] = b"SENTINEL-PRIVATE-KEY";
        let dto = PasskeyCreateDto {
            title: "Example".into(),
            rp_id: "example.com".into(),
            rp_name: "Example".into(),
            credential_id: vec![1, 2, 3],
            user_handle: vec![4, 5],
            user_name: "ada".into(),
            user_display_name: "Ada".into(),
            public_key: vec![6, 7],
            private_key: SENTINEL.to_vec(),
            algorithm: -7,
            sign_count: 0,
            transports: Vec::new(),
            discoverable: true,
        };
        let debug = format!("{dto:?}");
        assert!(!debug.contains("83, 69"), "raw key bytes leaked: {debug}");
        assert!(!debug.contains("SENTINEL"), "secret leaked: {debug}");
        assert!(debug.contains("[REDACTED]"));
    }
}
