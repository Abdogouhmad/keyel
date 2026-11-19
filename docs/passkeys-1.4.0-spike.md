# 1.4.0 Passkeys (WebAuthn / Credential Manager) — Spike & Draft

**Date:** 2026-11-19  
**Branch:** `phase/1.5.0`  
**Status:** Kickoff/spike (design draft). Builds on 1.3.0 (schema v3, custom fields, secret-safe DTO/reveal patterns).

This document captures the current integration surface, a proposed data model and schema migration, and a draft API/UX/platform plan for storing and autofilling passkeys while preserving Keyel’s offline/local, secret-safe model.

---

## 1. Current state (inspected)

### Android app & autofill
- **Manifest** (`android/app/src/main/AndroidManifest.xml`): permissions `USE_BIOMETRIC`, `USE_FINGERPRINT`, `INTERNET`, `REQUEST_INSTALL_PACKAGES`; `min` behavior via `minSdk 26` in `android/app/build.gradle.kts`; `KeyelAutofillService` declared with `android.permission.BIND_AUTOFILL_SERVICE` and `@xml/autofill_service_config`; `AuthActivity` hosts Flutter for fill/save flows; `FileProvider` for APK install.
- **Autofill service** (`android/.../autofill/KeyelAutofillService.kt`): handles `onFillRequest` (parses `AssistStructure` via `FieldParser`, returns a dataset gated behind `AuthActivity` intent with package/domain/field ids) and `onSaveRequest` (captures credentials, launches save UI). Returns nothing when it can’t confidently fill (avoids wildcard surfacing).
- **Auth bridge** (`AuthActivity.kt`): method channel `keyel/autofill` receives `fillCredential`/`saveDeclined` from Flutter and builds `Dataset` with `AutofillValue`.
- **Autofill config** (`res/xml/autofill_service_config.xml`): settings activity only, no `<compatibility-package>` wildcards; matching is done in core.
- **Main activity** (`MainActivity.kt`): platform channel `keyel/platform` for secure-screen flag, autofill-enabled check (`AutofillManager.hasEnabledAutofillServices`), open autofill settings, install helpers. No Credential Manager integration yet.
- **Flutter autofill entrypoint** (`lib/main_autofill.dart`): separate entrypoint renders picker/save/unlock flows in `AuthActivity`.

### Core / bridge / UI (password autofill)
- **Matching** (`crates/keyel_core/src/autofill.rs`): login-only matches by Android package (`androidapp://`/bare), exact host, or subdomain (label-boundary, no public-suffix/eTLD guessing). Conservative; text search is explicit/lower confidence. `MatchQuality {Exact, SameSite, Search}`.
- **API** (`rust/src/api/autofill.rs`, `lib/src/rust/api/autofill.dart`): `find_autofill_matches(package, web_domain, query)` returns secret-free `AutofillMatchDto`; password revealed separately via `reveal_field`.
- **Vault model** (`crates/keyel_core/src/vault/model.rs`): schema **v3** (`VAULT_SCHEMA_VERSION=3`), `EntryKind {Login, Card, Note}`, `EntryBody` variants, ordered `custom_fields`, secret zeroization, search over metadata/non-secret custom fields only. Migration is stepwise and default-safe (`migrate.rs`).
- **FRB DTOs/bindings** (`rust/src/api/models.rs`, `lib/src/rust/api/models.dart`): secret-free summaries/details, masked drafts, explicit `reveal_field`/`reveal_custom_field`.
- **UI**: kind-aware rendering/editing across entry detail/editor, vault list, trash, debug, autofill save (`VaultEntryKind`/`EntryKindDto` switches).

**Implication:** passkeys introduce a new credential type and a different platform ceremony (Credential Manager provider) alongside existing `AutofillService` password fill/save. Changes are cross-cutting (model/schema, search/match, DTOs/bindings, UI, Android integration).

---

## 2. Platform integration draft (Android Credential Manager)

### Goal
Act as a **passkey provider** so other apps/browsers can create and get WebAuthn passkeys stored in Keyel, with user verification and vault-unlock gating.

### Expected Android surface (to validate in implementation)
- **Dependencies (Jetpack):** `androidx.credentials:credentials` (+ provider APIs), and likely `androidx.credentials:credentials-play-services-auth` only if/where needed for consumer-side compat; evaluate versions compatible with current AGP/Kotlin/compileSdk.
- **Provider service:** implement a `CredentialProviderService` (androidx/provider API) to handle:
  - `onBeginCreateCredentialRequest` / `onBeginGetCredentialRequest` (or `onCreateCredentialRequest`/`onGetCredentialRequest` depending on API level) to return candidate credentials/metadata.
  - `onClearCredentialStateRequest` (sign-out/clear state) — likely a no-op or local state clear consistent with privacy model.
- **Manifest:** declare the provider service with required permission/intent filters/meta-data per Credential Manager provider contract; add any required queries/permissions discovered during implementation. Keep `AutofillService` for passwords.
- **UI/activities:** fulfillment typically launches an activity (transparent or full UI) to authenticate/unlock, show RP/user context, let the user pick/confirm a passkey, then return the credential response. Can reuse/extend `AuthActivity`/autofill Flutter flows or add dedicated passkey request activities and a method-channel contract.
- **User verification / unlock:** align with vault session + existing biometric/app-lock behavior (see `lib/core/platform/biometric_auth.dart`, `MainActivity`, settings). Never complete a ceremony without explicit user intent and required verification.
- **Capability gating:** provider support is OS/device dependent (native on newer Android; Jetpack backport for providers is limited/conditional). App must detect support and present graceful “unsupported on this device/version” states (roadmap DoD). `minSdk 26` remains for the app, but passkey-provider features may be `API 34+` (confirm).

### Integration points to touch
- `android/app/build.gradle.kts` (dependencies, compile/target considerations)
- `android/app/src/main/AndroidManifest.xml` (provider service, activities, meta-data)
- New Kotlin classes under `android/.../autofill/` or `android/.../passkeys/` (provider service, request handlers, response builders)
- `MainActivity.kt` / platform channel(s) for capability checks and settings entry (e.g. “set as passkey provider” / open system credential provider settings if applicable)
- `lib/main_autofill.dart` or a new Flutter entrypoint/route for create/get ceremony UI
- `lib/features/autofill/**` and/or new `lib/features/passkeys/**`

### Open questions / risks
- Exact provider API shape and backport story for the project’s target/compile SDK and device matrix.
- How to perform WebAuthn signing: in Rust/core with stored private key bytes (portable, consistent with vault crypto model) vs platform/hardware-backed key APIs (stronger key isolation but different storage/portability/export semantics). **Decision needed:** prefer vault-encrypted private key material handled only in Rust/isolated paths (never sent to Dart) unless platform APIs mandate/enable a better-kept handle; document tradeoff.
- Browser/app behavior differences, resident/discoverable credential expectations, and conditional UI (likely out of initial scope; start with explicit create/get).

---

## 3. Data model & schema draft (proposed schema v4)

### 3.1 Core types (`crates/keyel_core/src/vault/model.rs`)

Add a passkey entry kind/body. Private key material is **secret** (encrypted at rest in vault, zeroized in memory, never in summaries/search/index/diagnostics).

```rust
// Proposed additions (illustrative)

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EntryKind {
    Login,
    Card,
    Note,
    Passkey, // NEW
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PasskeyAlgorithm {
    // COSE algorithm identifiers commonly used for passkeys (exact set TBD)
    #[default]
    Es256,      // -7
    Rs256,      // -257
    EdDsa,      // -8
    Unknown(i32),
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Passkey {
    /// Relying Party ID (e.g. "example.com"). Primary match key.
    pub rp_id: String,
    /// Human-readable RP name, if provided.
    pub rp_name: String,
    /// Credential ID (raw bytes, base64url/text-encoded for storage/serde as needed). Secret-adjacent identifier.
    pub credential_id: Vec<u8>,
    /// User handle provided by RP (raw bytes).
    pub user_handle: Vec<u8>,
    /// User name (account identifier shown to user).
    pub user_name: String,
    /// User display name.
    pub user_display_name: String,
    /// COSE public key bytes.
    pub public_key: Vec<u8>,
    /// Private key material used for assertions. SECRET: must be zeroized.
    pub private_key: Vec<u8>,
    /// COSE algorithm.
    pub algorithm: PasskeyAlgorithm,
    /// Signature counter (clone detection / RP policy).
    pub sign_count: u32,
    /// Creation time (Unix seconds).
    pub created_at: u64,
    /// Last successful use time (Unix seconds), if known.
    pub last_used_at: Option<u64>,
    /// Optional transports / hints (e.g. internal, usb, nfc, ble, hybrid) if stored.
    #[serde(default)]
    pub transports: Vec<String>,
    /// Discoverable/resident credential flag, if known.
    #[serde(default)]
    pub discoverable: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EntryBody {
    Login(Login),
    Card(Card),
    Note(Note),
    Passkey(Passkey), // NEW
}
```

**Secret handling requirements**
- `Passkey.private_key` (and consider `user_handle`/`credential_id` sensitivity per threat model; at minimum treat private key as secret): include in `Entry::zeroize_secrets()`; never copy into summaries/diagnostics/logs.
- No plaintext private key exposure via any DTO except not at all — ceremonies should operate inside Rust/platform boundary and return only assertion/attestation results or success markers, never raw key material.
- Search/index: match `rp_id`, `rp_name`, `user_name`, `user_display_name`, title/tags; **never** index/match key material or raw credential ids as free-text secrets beyond what’s necessary for exact lookup (exact credential-id lookup is an internal operation, not user search text exposure).

### 3.2 Migration (`crates/keyel_core/src/vault/migrate.rs`)
- Bump `VAULT_SCHEMA_VERSION` **2→3→4** with v3→v4 step: structural addition of a new `EntryBody` variant; existing v3 payloads contain no passkeys, so deserialization/migration is default-safe (no field backfill needed on existing entries). Keep fail-closed for unknown/future versions.
- Update `docs/vault-model.md` for v4 (kinds, secret fields, search, ceremony note).

### 3.3 Summary/subtitle (`Entry::summary`)
- Passkey subtitle: e.g. `user_name` or `user_display_name` falling back to `rp_id` (never secret material).

### 3.4 Cross-cutting match sites (must be updated exhaustively)
`autofill.rs` (matching), `import.rs` (CSV mapping/export — passkeys likely unsupported in Bitwarden/Chrome CSV; decide representation), `health.rs` (health scoring applicability?), `index.rs`/search, `rust/src/api/{models,entries,totp,autofill,...}`, Flutter `VaultEntryKind`/`EntryKindDto` switches (detail, edit, list, trash, debug, autofill save, icons, etc.), tests.

---

## 4. API / bridge surface draft

### 4.1 DTOs (`rust/src/api/models.rs`)

```rust
// Proposed (illustrative)
pub enum EntryKindDto { Login, Card, Note, Passkey }

pub struct PasskeyDetailDto {
    pub rp_id: String,
    pub rp_name: String,
    pub user_name: String,
    pub user_display_name: String,
    pub credential_id_b64: String, // display/copy-safe identifier if useful; confirm sensitivity
    pub algorithm: PasskeyAlgorithmDto,
    pub sign_count: u32,
    pub created_at: u64,
    pub last_used_at: Option<u64>,
    pub discoverable: bool,
    // NO private_key, NO raw secret material
}

// EntryDetailDto: + passkey: Option<PasskeyDetailDto>
// EntryDraft: + passkey fields OR a dedicated create-passkey input (ceremony-driven creates
// differ from manual form drafts; see 4.2)
// SecretFieldDto: likely no revealable passkey private key; ceremony-only use
```

**Design choice:** passkey creation/registration is usually driven by a platform `create` ceremony (origin/RP/user/challenge/options from requesting app) rather than a manual “edit form” like logins. Model may need:
- A **ceremony/create API** that accepts the platform request + selected user confirmation and persists a new passkey entry.
- Standard CRUD for list/view/delete/rename (metadata-only edits) consistent with other entries, but editing key material is not applicable.

### 4.2 Rust bridge functions (proposed modules)
- `rust/src/api/passkeys.rs` (new) or extend `autofill.rs`:
  - `list_passkey_matches(rp_id, user_handle_or_credential_ids_hint?) -> Vec<PasskeyMatchDto>` (secret-free; for get-ceremony candidate selection)
  - `begin_create_passkey(...)` / `complete_create_passkey(...)` or a single `create_passkey_from_request(...)` returning platform-ready response bytes — exact split depends on Android flow and whether Rust owns crypto steps
  - `get_passkey_assertion(...)` to produce assertion for a chosen credential (increments sign_count, updates last_used)
  - capability/support helpers as needed
- Keep private key operations inside Rust/session scope (`with_session`), update and `save()` on counter/last-used changes.

### 4.3 Flutter repository (`lib/data/vault_repository.dart`)
- Add methods mirroring bridge API (matches, create/get flows, metadata fetch). No methods that expose private key.
- UI flows: passkey picker/confirmation screen for get requests; create-confirmation screen; management/detail view; graceful unsupported state.

### 4.4 Platform channel contract (draft)
- Request payloads/ids passed from Kotlin provider service to Flutter (or handled natively with callbacks into Rust) must carry only what’s needed (RP, user info, challenge/options, allowed credentials) — no secrets.
- Response returns WebAuthn/credential response structures to the framework; signing material never crosses to Dart.

---

## 5. Autofill & selection behavior

- **Matching:** primary key is `rp_id` (with correct origin/RP binding enforced per platform request). Candidate filtering by `user_handle`/allowed credential IDs when provided. This is stricter and different from password host/package heuristics — reuse concepts (exactness) but implement passkey-specific logic (new core function, not conflated with login URL matching).
- **Picker UX:** show RP name/id, user name/display name, last used; never show key material. Require explicit user selection and verification/unlock.
- **Counters:** increment `sign_count` and persist on successful assertion (and handle storage write failures safely).

---

## 6. Import/export & interoperability (initial stance)

- **Encrypted backup:** payload-based, so v4 passkeys round-trip automatically once model supports them (verify in tests).
- **CSV (Bitwarden/Chrome):** passkeys are generally **not** representable in these CSV formats. Initial behavior: exclude passkeys from CSV export or represent as a clearly marked non-secret note/unsupported placeholder per product decision; on import, ignore/record as unsupported if encountered. Document explicitly (avoid silent loss or secret leakage). Revisit if/when a standard passkey exchange format is adopted.
- **Diagnostics/logs:** no credential ids/keys/user handles leaked in debug bundles or logs.

---

## 7. Security considerations

- Private keys and any assertion secrets are vault-encrypted at rest, zeroized in memory, and never exposed to Dart/UI/diagnostics.
- Ceremonies must bind to the requesting RP/origin as provided by the platform; reject/guard mismatches.
- User verification and vault unlock required per policy; respect auto-lock/session lifecycle.
- Threat-model updates needed in `docs/` for ceremony handling, key origin, and counter/clone-detection behavior.
- Fuzz/robustness: parse platform/request inputs defensively (no panics on malformed data).

---

## 8. Suggested implementation slices

1. **Core model + migration v4 + secret handling + tests** (serialization, v3→v4, zeroization, search non-leakage, match-by-rp logic). Land behind minimal/no UI if needed.
2. **Rust API/DTOs + FRB bindings** for passkey CRUD/metadata and match queries (no ceremony yet, or stubbed).
3. **Flutter management UI** (list/detail/delete, unsupported states) + repository wiring.
4. **Android Credential Manager spike/prototype** (dependencies, manifest, provider service skeleton, capability detection) on a supported device/API level.
5. **Create/get ceremony end-to-end** (platform <-> Rust signing/storage <-> Flutter confirmation UI), counter updates, and integration tests/manual verification.
6. **Docs/changelog/help** and CSV/export behavior decisions.

---

## 9. Immediate next actions (recommended)

- [ ] Decide and document **key-handling strategy** (vault-held software key in Rust vs hardware-backed/platform key) and its implications for backup/portability/security.
- [ ] Confirm **target Android/SDK and dependency versions** for Credential Manager provider support in this project.
- [ ] Prototype **`CredentialProviderService` skeleton + manifest entries + capability detection** on API 34+ device/emulator.
- [ ] Implement **schema v4 draft in core** (types, migration, zeroize, search/subtitle, tests) once strategy is chosen, then regenerate bindings and fix exhaustiveness across the codebase.
- [ ] Define **ceremony API contract** (Kotlin <-> Flutter <-> Rust) with strict no-secret-crossing boundaries.

---

*This is a spike/draft document: field names, encoding choices (e.g. base64url vs raw bytes in DTOs), algorithm enum coverage, and platform API details must be validated against the final Credential Manager/WebAuthn implementation and target devices.*
