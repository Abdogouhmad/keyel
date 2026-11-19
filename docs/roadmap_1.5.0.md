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
| 1.3.0 | Custom fields for entries | 1-1.5 weeks | ◐ in progress |
| 1.4.0 | Passkeys (WebAuthn / Credential Manager) | 2-3 weeks | ☐ |
| 1.5.0 | Opt-in user-controlled E2EE cross-device sync | 3-4 weeks | ☐ |

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
   - [ ] Add `CustomField`/type enum and storage on `Entry` (ordered, defaulted for old payloads).
   - [ ] Bump `VAULT_SCHEMA_VERSION` and implement migration step(s) v1→v2→v3 preserving existing data; update `docs/vault-model.md`.
   - [ ] Ensure secret handling: `zeroize_secrets` clears hidden/custom secret values; `Drop`/replace paths remain safe.
   - [ ] Update search/indexing: define and implement searchable vs non-searchable custom-field data (recommend: searchable labels and `text`/`url` values only; never `hidden` values) and avoid leaking in summaries/subtitles.
   - [ ] Add/extend core unit tests: serialization round-trip, migration from prior schema, search behavior, zeroization expectations where testable.

2. **Bridge/API & bindings**
   - [ ] Extend DTOs: `EntryDetailDto`, `EntryDraft`, and a secret reveal mechanism for custom fields (e.g. reveal by field id/index) without exposing hidden values by default.
   - [ ] Map core <-> DTO in `rust/src/api/models.rs` and CRUD/reveal in `rust/src/api/entries.rs`.
   - [ ] Regenerate Flutter/Rust bridge bindings and update Dart DTO usage (`lib/src/rust/**`).

3. **Entry UI (Flutter)**
   - [ ] Editor: add/remove/reorder custom fields, choose type, edit label/value; keep UX usable on small screens.
   - [ ] Detail: render custom fields with appropriate affordances (copy, open URL for `url`, masked reveal/copy for `hidden`).
   - [ ] Controllers/state: load/save via draft, preserve masked/unchanged secret values on update, and handle reveal timers/clipboard behavior consistently with existing fields.
   - [ ] Wire any affected list/autofill/debug surfaces to remain secret-free and compatible.

4. **Backup, import/export & diagnostics**
   - [ ] Confirm encrypted backup/restore round-trips custom fields (payload-based); add regression coverage.
   - [ ] CSV export: include custom fields (e.g. Bitwarden `fields` column/compatible encoding) without exposing secrets unsafely; document behavior.
   - [ ] CSV import: map supported custom-field sources (notably Bitwarden `fields`) into custom fields; preserve types when representable.
   - [ ] Ensure diagnostics/debug bundles and logs remain redacted (no custom-field secret values).

5. **Verification & release prep**
   - [ ] Run `cargo test -p keyel_core` (and relevant Rust crate tests), `flutter analyze`, `flutter test`.
   - [ ] Manual smoke (if environment allows): create/edit/delete/reorder fields of each type, reveal/copy/URL open, relock/unlock persistence, encrypted backup restore, CSV import/export round-trip.
   - [ ] Update `CHANGELOG.md` / docs as needed for the 1.3.0 release when phase completes.

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
- Passkeys/WebAuthn concepts: relying party ID, credential ID, user handle, public-key credential source, origin/rp binding, user verification.
- Android Credential Manager / platform passkey provider APIs and Flutter/Rust bridging constraints (platform channels/FFI boundaries).
- Existing autofill architecture: `crates/keyel_core/src/autofill.rs`,
  `rust/src/api/autofill.rs`, `lib/features/autofill/**`, `android/**` integration.
- Threat model implications: phishing resistance relies on correct RP/origin binding; local verification and device security matter.

### Todo
1. **Vault & core support**
   - [ ] Design passkey data model (credential id, rp id/name, user name/display name, user handle, algorithm, public key, encrypted private key/secret material, counters/metadata, created/last-used timestamps) and schema migration.
   - [ ] Implement secure storage/zeroization and minimal operations needed for registration/authentication ceremonies (core logic in Rust where feasible, with tests).
   - [ ] Extend search/list/detail DTOs and UI-safe summaries (never expose private key material).

2. **Platform integration**
   - [ ] Android: integrate Credential Manager provider flows (create/get passkey), permissions/manifests, and activity/intent plumbing.
   - [ ] Define behavior for unsupported platforms/versions and desktop story (graceful unsupported states or platform-specific implementations as feasible).
   - [ ] Ensure user verification / unlock gating aligns with vault/session and auto-lock behavior.

3. **UX & management**
   - [ ] Entry/detail UI for passkeys: create/import (if supported), display RP/user info, copy safe identifiers if useful, delete/rename/manage.
   - [ ] Autofill/picker integration to select and assert the correct passkey for a request with clear RP context.
   - [ ] Error handling for mismatched RP, canceled verification, or missing credentials.

4. **Security, tests & docs**
   - [ ] Threat-model notes and security review for ceremony handling and key isolation.
   - [ ] Unit/integration tests for model serialization, migration, and selection logic; platform/manual verification on supported devices.
   - [ ] Update docs/changelog and in-app help/capability messaging.

---

## 1.5.0 — Opt-in user-controlled E2EE cross-device sync

**Goal:** let users keep vaults consistent across devices without Keyel servers,
using a user-chosen storage location, with client-side encryption and
conflict-aware behavior.

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
1. **Architecture & protocol**
   - [ ] Define sync payload/envelope format (versioned, authenticated, encrypted), device identity/pairing, and key exchange/bootstrap flow that never leaks secrets to the backend.
   - [ ] Choose merge strategy (entry-level LWW with conflict copies, or field-aware merge) and specify behavior for create/update/delete/trash/restore and attachment-like future data.
   - [ ] Define backend abstraction(s) starting with a user-selected folder/file target; keep transport swappable.

2. **Core implementation**
   - [ ] Implement change tracking/version metadata in the vault model as needed (with migration) and deterministic merge engine with tests (including concurrent edits and offline divergence).
   - [ ] Implement encrypted push/pull/sync operations, integrity checks, and atomic local application/recovery points.
   - [ ] Add conflict surfacing/resolution data structures and non-destructive conflict copies where required.

3. **UX & safety**
   - [ ] Settings/UI: enable/disable sync, choose backend/location, pair/restore device, show last sync/status/errors, and trigger manual sync.
   - [ ] First-run and recovery flows that prevent accidental overwrite (explicit direction/confirmation when remote/local differs).
   - [ ] Background/foreground sync policy respecting battery/network/platform limits and vault lock state.

4. **Security, testing & docs**
   - [ ] Threat-model and review of pairing, key storage, metadata leakage, rollback/replay resistance, and error handling.
   - [ ] Extensive automated tests (merge matrix, tampered/corrupt remote state, partial writes) plus multi-device/manual QA.
   - [ ] User documentation: setup, trust assumptions, limitations, and backup recommendations.

---

## Sequencing notes
- **1.3.0 first:** highest immediate UX/value, low platform risk, unblocks better import fidelity.
- **1.4.0 second:** strategic/table-stakes capability; depends on platform APIs but builds on autofill/session foundations.
- **1.5.0 third:** largest architectural change (merging, pairing, sync state); benefits from a stable, richer data model including custom fields/passkeys.
- Revisit estimates after 1.3.0 implementation data (vault-format/FRB churn) and after a 1.4.0 platform spike on target devices.
