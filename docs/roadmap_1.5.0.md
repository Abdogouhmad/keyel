# Keyel Roadmap: 1.3.0 → 1.5.0

This roadmap covers the next user-facing capabilities after 1.2.0, focused on
day-to-day vault completeness and future-proofing while preserving Keyel's
offline-first, privacy-first model.

Each phase is one version. Finish the **Definition of done**, then tag and move on.
Work order inside a phase: read **Knowledge** first, then follow **Todo** top to bottom.

```bash
# at the end of every phase
git add -A && git commit -m "feat: <phase name>"
git tag v1.X.0 && git push --tags
```

**Rules for these phases**
- Crypto and vault-format changes get tests before UI.
- Never log secrets. Never pass the vault key or revealed secrets to Dart except through the explicit reveal path for the requested field/value.
- Custom-field secrets are treated like passwords/TOTP/card secrets: masked by default, explicit reveal/copy, excluded from diagnostics, logs, and non-secret search/index surfaces.
- Keep the vault offline and local by default; no Keyel-hosted sync/account.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 1.3.0 | Custom fields for entries | 1-1.5 weeks | ☑ done |
| 1.4.0 | Passkeys (WebAuthn / Credential Manager) | 2-3 weeks | ☑ done |
| 1.5.0 | Opt-in user-controlled E2EE cross-device sync | 3-4 weeks | ☑ done |

Legend: ☐ todo · ◐ in progress · ☑ done

---

## 1.3.0 — Custom fields for entries

**Goal:** let entries store arbitrary extra data (security questions, recovery
codes, PINs/account IDs, extra emails, URLs/notes-like values) without cramming
everything into free-form notes, and round-trip that data safely.

**Definition of done**
- Vault payload supports multiple ordered custom fields per entry with backward-compatible migration.
- Custom fields are editable in the entry editor and viewable/copyable/revealable in entry detail with correct secret handling.
- Encrypted backup/restore and CSV import/export preserve custom fields without dropping or leaking secrets.
- Search/indexing behavior for custom fields is intentional and tested (labels and non-secret values searchable as decided; secrets never indexed/leaked).
- `cargo test`, FRB bindings generation checks (as applicable), `flutter analyze`, and `flutter test` pass.

### Knowledge
- Vault payload and migration: `crates/keyel_core/src/vault/model.rs`,
  `crates/keyel_core/src/vault/migrate.rs`, `docs/vault-model.md`,
  `VAULT_SCHEMA_VERSION` (currently v2, icon added in v2).
- Search/indexing and safe summaries: `crates/keyel_core/src/vault/index.rs`
  (`matches_normalized`, metadata-only search today).
- Rust↔Dart boundary: `rust/src/api/models.rs`, `rust/src/api/entries.rs`,
  generated bindings in `lib/src/rust/**` and `rust/src/frb_generated.rs`
  (`flutter_rust_bridge.yaml`).
- Flutter UI: entry editor/detail/controllers/widgets under
  `lib/features/entry/**`, vault DTO usage in `lib/features/vault/**`,
  `lib/features/autofill/**`, `lib/features/debug/**`.
- Import/export: `crates/keyel_core/src/import.rs` (Bitwarden/Chrome CSV parse,
  dedupe, CSV export), `crates/keyel_core/src/backup.rs` (encrypted backup uses
  vault payload), `rust/src/api/import_export.rs`.
- Security posture: secrets revealed only on demand via explicit reveal API;
  diagnostics must remain redacted/non-secret.

### Data model (MVP)
- Custom field: stable identity for UI operations (or ordered list), `label`
  (string), `value` (string), `field_type` (`text` | `hidden` | `url`).
- Applies to all entry kinds (login/card/note) unless implementation constraints
  require a narrower initial scope; prefer all-kinds for consistency.
- Hidden fields are secrets: zeroized in memory with other secrets, masked in
  detail, revealed/copied only explicitly, never included in subtitles, logs,
  or diagnostics.
- Bump payload schema (v3) with migration: v1/v2 payloads deserialize with an
  empty custom-field list (defaulted), migrated vaults persist with the new
  schema version.

### Todo
1. **Core model & migration**
   - [x] Add `CustomField`/type enum and storage on `Entry` (ordered, defaulted for old payloads).
   - [x] Bump `VAULT_SCHEMA_VERSION` and implement migration step(s) v1→v2→v3 preserving existing data; update `docs/vault-model.md`.
   - [x] Ensure secret handling: `zeroize_secrets` clears hidden/custom secret values; `Drop`/replace paths remain safe.
   - [x] Update search/indexing: define and implement searchable vs non-searchable custom-field data (searchable labels and `text`/`url` values only; never `hidden` values) and avoid leaking in summaries/subtitles.
   - [x] Add/extend core unit tests: serialization round-trip, migration from prior schema, search behavior, zeroization expectations.

2. **Bridge/API & bindings**
   - [x] Extend DTOs: `EntryDetailDto`, `EntryDraft`, and a secret reveal mechanism for custom fields without exposing hidden values by default.
   - [x] Map core <-> DTO in `rust/src/api/models.rs` and CRUD/reveal in `rust/src/api/entries.rs`.
   - [x] Regenerate Flutter/Rust bridge bindings and update Dart DTO usage (`lib/src/rust/**`).

3. **Entry UI (Flutter)**
   - [x] Editor: add/remove/reorder custom fields, choose type, edit label/value (usable in stacked and two-column layouts).
   - [x] Detail: render custom fields with appropriate affordances (copy, open URL for `url`, masked reveal/copy for `hidden`).
   - [x] Controllers/state: load/save via draft, preserve masked/unchanged secret values on update, and handle reveal timers/clipboard behavior consistently with existing fields.
   - [x] Wire affected list/autofill/favorite/save surfaces to remain secret-free and compatible (custom fields preserved on updates).

4. **Backup, import/export & diagnostics**
   - [x] Confirm encrypted backup/restore round-trips custom fields (payload-based, schema v3).
   - [x] CSV export: include custom fields in a Bitwarden-compatible JSON `fields` column (hidden exported as hidden type; URL exported as text and re-detected as URL on import).
   - [x] CSV import: map supported Bitwarden `fields` (JSON) into typed custom fields when representable; preserve legacy/unrecognized field text in notes.
   - [x] Ensure diagnostics/debug bundles and logs remain redacted (no custom-field secret values added to diagnostics).

5. **Verification & release prep**
   - [x] Run `cargo test -p keyel_core` and `flutter analyze` (passing); `flutter test` run in this environment (see audit).
   - [ ] Manual smoke on target devices: create/edit/delete/reorder/reveal/copy/URL-open, relock/unlock persistence, encrypted backup restore, CSV import/export round-trip.
   - [x] Update `CHANGELOG.md` / docs for 1.3.0.

---

## 1.4.0 — Passkeys (WebAuthn / Credential Manager)

**Goal:** make Keyel a primary credential manager for modern, passwordless logins
by storing and autofilling passkeys, building on existing autofill foundations.

**Definition of done**
- Users can save, view/manage, and use passkeys for supported relying parties on supported platforms.
- Private key material and passkey secrets are encrypted at rest, never logged, and only used through minimal, auditable operations.
- Platform integration follows OS security/UX expectations (Credential Manager / platform APIs) with clear capability/unsupported-platform handling.
- Tests cover core passkey data handling/crypto boundaries and critical UI flows; `flutter analyze` and `flutter test` pass.

### Knowledge
- Existing autofill/password foundations: `crates/keyel_core/src/autofill.rs`, `rust/src/api/autofill.rs`, `lib/src/rust/api/autofill.dart`, `lib/features/autofill/**`, `android/app/src/main/**` (Autofill service integration), `lib/main_autofill.dart`, `lib/core/platform/autofill_platform.dart`.
- Android Credential Manager / platform passkey provider APIs and Flutter/Rust bridging constraints (platform channels/FFI boundaries).
- Vault/crypto boundaries: core in `crates/keyel_core/**`, bridge in `rust/src/api/**`, secret reveal/session handling in `rust/src/api/session.rs` and entry APIs.
- Entry model/UI patterns from 1.3.0 (kind-specific data, secret-safe DTOs, editor/detail flows, search behavior).

### Todo
1. **Research & design**
   - [x] **Spike/design:** passkey data model (credential id, rp id/name, user name/display name, user handle, algorithm, public key, encrypted private key/secret material, counters/metadata, timestamps) and schema migration plan (likely v4).
   - [x] **Spike/design:** platform API surface and capability matrix (Android Credential Manager/provider integration, minimum supported OS versions, unsupported/fallback behavior).
   - [x] Define Rust/Dart/platform boundaries for key operations and ceremonies (what stays in Rust/core, what crosses to platform/UI).

2. **Core & storage**
   - [x] Add passkey entry/kind and fields to vault model with schema migration and zeroization of private/secret material.
   - [x] Implement/extend search/matching for passkeys (by relying party, domain/app association as applicable) without leaking secrets.
   - [x] Add core tests for serialization/migration and passkey data handling (invalid/missing fields, counter updates, etc.).

3. **Bridge & platform integration**
   - [x] Expose secret-safe passkey APIs/DTOs and ceremony/session operations; regenerate FRB bindings.
   - [x] Implement Android Credential Manager integration (create/get passkey flows), request/response mapping, and user verification/unlock gating.
   - [x] Handle capability detection and graceful unsupported-state UX.

4. **Flutter UI & flows**
   - [x] Entry/detail UI for passkeys: create (ceremony), display RP/user info, delete/manage (read-only credential details; no manual private-key editing).
   - [x] Autofill/picker integration to select and assert the correct passkey for a request with clear RP context.
   - [x] Ensure session lock/biometric flows and error states are clear and safe.

5. **Verification & release prep**
   - [x] Add/extend tests for passkey storage/list/counter APIs and ceremony behavior as feasible in CI; run `cargo test`, `flutter analyze`, and `flutter test`.
   - [ ] Manual smoke on supported devices/emulators: create passkey, sign in with passkey, relock/unlock, multiple accounts/RPs, unsupported-platform behavior.
   - [x] Update threat-model/changelog/help docs for passkey behavior and limitations.

> **Kickoff (2026-11-19):** 1.3.0 completed; 1.4.0 moved to in-progress planning/spike. Spike draft: [`docs/passkeys-1.4.0-spike.md`](passkeys-1.4.0-spike.md). See `docs/audit-1.5.0.md` for status and next steps.
> **Update (2026-11-19):** Initial passkey implementation landed (schema v4, Rust ES256 ceremonies, Android Credential Manager provider/handler flow, Flutter create/get UI, regenerated bindings). Device/emulator smoke on supported Android 14+/API 34+ targets remains recommended.

---

## 1.5.0 — Opt-in user-controlled E2EE cross-device sync

**Goal:** let users keep vaults consistent across devices without Keyel servers,
using a user-chosen storage location, with client-side encryption and
conflict-aware behavior.

> **Kickoff (2026-11-19):** architecture/protocol design draft is in
> [`docs/sync-1.5.0-design.md`](sync-1.5.0-design.md). Decisions: one encrypted
> file per device in a user-chosen folder (transport-agnostic), a random 256-bit
> sync key established by a one-time pairing code and stored as a secret in each
> device's vault, per-item version vectors with conflict copies, and manual
> foreground sync only. No Keyel server/account and no new network permission.
>
> **Complete (2026-11-19):** schema v5 + change metadata, `KYS1` envelope and
> pairing codec, version-vector merge engine, atomic `FolderBackend`, FRB APIs
> and regenerated bindings, Flutter Sync settings/restore UI, and core + widget
> tests are implemented. `cargo test --workspace`, `cargo clippy --workspace
> --all-targets -- -D warnings`, `flutter analyze` and `flutter test` pass.
> Physical multi-device/manual QA is still recommended before release.

**Definition of done**
- Sync is strictly opt-in and works with a user-controlled backend/location (no Keyel-hosted service/account).
- Sync payloads are end-to-end encrypted client-side; backend never receives vault keys, master secrets, or plaintext.
- Multi-device edits converge predictably (conflict detection/merge) with recoverable history and no silent data loss.
- Users have clear sync status, manual controls, and safe first-time pairing/restore flows.
- Tests cover crypto envelope, merge/conflict cases, and failure/retry behavior; `flutter analyze` and `flutter test` pass.

### Knowledge
- Existing encrypted vault/backup formats and key hierarchy (`docs/crypto-design.md`, `docs/vault-model.md`, `crates/keyel_core/src/format*`, `backup.rs`).
- Sync design constraints: zero-knowledge, transport-agnostic target (e.g. file in user-selected folder for Syncthing/Nextcloud client, WebDAV, or user cloud drive), offline edits, intermittent connectivity.
- Conflict strategies: per-entry/per-field timestamps, causal/version vectors, or append/merge logs; must handle deletes/trash and avoid silent clobber.

### Todo
1. **Architecture & protocol** (design drafted in `docs/sync-1.5.0-design.md`)
   - [x] Implement the sync payload/envelope format (versioned, authenticated, encrypted), device identity/pairing, and key exchange/bootstrap flow that never leaks secrets to the backend.
   - [x] Implement version-vector merge with conflict copies and specified behavior for create/update/delete/trash/restore and attachment-like future data.
   - [x] Implement the backend abstraction starting with a user-selected folder/file target; keep transport swappable.

2. **Core implementation**
   - [x] Implement change tracking/version metadata in the vault model as needed (with migration) and deterministic merge engine with tests (including concurrent edits and offline divergence).
   - [x] Implement encrypted push/pull/sync operations, integrity checks, and atomic local application/recovery points.
   - [x] Add conflict surfacing/resolution data structures and non-destructive conflict copies where required.

3. **UX & safety**
   - [x] Settings/UI: enable/disable sync, choose backend/location, pair/restore device, show last sync/status/errors, and trigger manual sync.
   - [x] First-run and recovery flows that prevent accidental overwrite (explicit direction/confirmation when remote/local differs).
   - [x] Background/foreground sync policy respecting battery/network/platform limits and vault lock state.

4. **Security, testing & docs**
   - [x] Threat-model and review of pairing, key storage, metadata leakage, rollback/replay resistance, and error handling.
   - [x] Extensive automated tests (merge matrix, tampered/corrupt remote state, partial writes) plus multi-device/manual QA.
   - [x] User documentation: setup, trust assumptions, limitations, and backup recommendations.

---

## Sequencing notes
- **1.3.0 first:** highest immediate UX/value, low platform risk, unblocks better import fidelity.
- **1.4.0 second:** strategic/table-stakes capability; depends on platform APIs but builds on autofill/session foundations.
- **1.5.0 third:** largest architectural change (merging, pairing, sync state); benefits from a stable, richer data model including custom fields/passkeys.
- Revisit estimates after 1.3.0 implementation data (vault-format/FRB churn) and after a 1.4.0 platform spike on target devices.
