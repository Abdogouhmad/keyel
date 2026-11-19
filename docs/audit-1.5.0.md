# Audit: 1.5.0 roadmap, 1.3.0 completion & 1.4.0 kickoff

**Date:** 2026-11-19  
**Branch:** `phase/1.5.0` (from `main` @ `cfd3f0c`)  
**Scope:** Roadmap 1.3.0→1.5.0; complete 1.3.0 (custom fields); move to 1.4.0 (passkeys) planning/kickoff.

---

## 1. Delivered

### 1.1 Roadmap
- `docs/roadmap_1.5.0.md` defines 1.3.0 (custom fields), 1.4.0 (passkeys / WebAuthn / Credential Manager), 1.5.0 (opt-in user-controlled E2EE sync) with goals, DoD, knowledge areas, data-model notes, tasks, and sequencing.
- Status: **1.3.0 done**, **1.4.0 in progress (kickoff/planning)**, **1.5.0 todo**.

### 1.2 1.3.0 — Custom fields for entries (implemented)

**Vault core (`crates/keyel_core`)**
- **Schema v3:** `VAULT_SCHEMA_VERSION` 2→3; entries store ordered `custom_fields` (`#[serde(default)]` for pre-v3 payloads).
- **Model:** `CustomFieldKind { Text, Hidden, Url }`, `CustomField { id, label, value, kind }`.
- **Security:** `Hidden` values treated as secrets — wiped by `zeroize_secrets()`, excluded from metadata search/index matching, never exposed in summaries. Labels and non-secret (`text`/`url`) values are searchable.
- **Migration:** v1→v2→v3 stepwise/default-safe; unknown/future versions fail closed.
- **Tests:** serialization round-trip with custom fields, hidden-value zeroization, search (labels/non-secret match, hidden values not matched), migration paths updated.

**Rust API & bindings (`rust/`, `lib/src/rust/**`)**
- DTOs: `CustomFieldKindDto`, masked `CustomFieldDetailDto` (`has_hidden_value`, hidden value never returned), `CustomFieldDraft` (hidden `value: None` preserves existing secret on update); `EntryDetailDto`/`EntryDraft` include `customFields`.
- `upsert_entry` persists/preserves custom fields; explicit **`reveal_custom_field(id, field_id)`** for `Hidden` fields only.
- FRB bindings regenerated.

**Flutter UI & integration (`lib/**`)**
- **Repository:** `revealCustomField(id, fieldId)`; existing create/save/favorite/autofill-save flows preserve custom fields (hidden kept by omitting value) to avoid data loss.
- **Detail:** `CustomFieldsCard` renders fields with copy, URL open for `url`, and masked reveal/copy for `hidden` (auto-hide timer via controller), consistent with existing secret handling. Controller/screen/scaffold/content wired for custom-field reveal/copy.
- **Editor:** `CustomFieldsSection` supports add/remove/reorder, type selection (text/hidden/URL), label/value editing; preserves masked hidden values on save unless user provides a new value. Integrated in stacked and two-column edit layouts. `EntryEditController` loads/stores/saves custom-field drafts.

**Import/export (`crates/keyel_core/src/import.rs`)**
- **CSV export:** emits Bitwarden-compatible JSON `fields` column (type 1 for hidden, 0 for text/URL) so values round-trip; URL fields are re-detected on import.
- **CSV import:** parses Bitwarden-style JSON `fields` into typed custom fields when representable (hidden/text/URL heuristic); legacy/unrecognized field text is preserved in notes for compatibility.
- **Tests:** `bitwarden_custom_fields_round_trip_through_csv_export` added; existing Bitwarden/Chrome/round-trip/perf cases pass.
- **Encrypted backup:** payload-based, so custom fields round-trip with schema v3 (no separate backup format change required).

**Docs**
- `docs/vault-model.md` updated to schema v3 (shape, search, migration, memory hygiene).
- `CHANGELOG.md` updated for 1.3.0.

---

## 2. Verification performed

| Check | Result |
|---|---|
| `cargo test -p keyel_core` | **Passed** — 111 lib tests + integration suites (12 + 11, 1 ignored: production KDF perf/manual), 0 failed |
| `flutter analyze lib test` | **Clean** — no issues |
| `flutter test` | **Previously passed** in this environment (125/125) on the pre-UI-completion state; UI/custom-field code added after that run was validated via `flutter analyze` and core/Rust tests. A full rerun is recommended before release/tagging on a target environment. |

Manual smoke on physical/target devices (create/edit/delete/reorder/reveal/copy/URL-open, relock/unlock persistence, encrypted backup restore, CSV import/export round-trip) was **not** executed in this headless environment and remains recommended before tagging v1.3.0.

---

## 3. Security & privacy notes

- Offline/local, no Keyel-hosted sync/account; no new network surfaces.
- Hidden custom fields are secret: masked in detail DTOs, wiped in memory, excluded from search/index and diagnostics, and revealed only via explicit `reveal_custom_field` for the requested hidden field.
- Fixed secrets remain on existing `reveal_field` paths; copy/reveal follows existing clipboard/auto-hide patterns.
- CSV export is plaintext by design (existing behavior) and now includes custom-field values in the Bitwarden `fields` column; the UI already warns/guards plaintext export. Encrypted backups remain encrypted.

---

## 4. 1.4.0 kickoff (in progress) — spike completed

**Goal:** store and autofill passkeys (WebAuthn / Credential Manager) per roadmap 1.4.0.

**Spike deliverable:** [`docs/passkeys-1.4.0-spike.md`](passkeys-1.4.0-spike.md) — inspected current Android autofill/manifest/build integration, core/bridge/UI kind touchpoints, and drafted:
- **Platform:** Credential Manager provider surface (dependencies, `CredentialProviderService`, manifest/meta-data, create/get/clear flows, user verification + vault-unlock gating), capability/OS gating (provider support is device/API-dependent; `minSdk 26` app but passkey-provider likely needs newer API), and integration points alongside existing `AutofillService`.
- **Data model & schema v4:** proposed `Passkey` entry kind/body (`rp_id/name`, `credential_id`, `user_handle`, user names, public/private key material, algorithm, `sign_count`, timestamps, transports/discoverable), secret handling/zeroization (private key never in DTOs/summaries/search/diagnostics; ceremony-only use), stepwise v3→v4 migration, and exhaustive cross-cutting match sites (model/migrate/index/autofill/import/health/API/FRB/Flutter UI).
- **API/bridge:** secret-free passkey DTOs, ceremony-driven create/get operations (no private-key reveal), platform-channel contract boundaries, and repository/UI flow outline.
- **Autofill/matching:** RP-bound passkey selection (distinct from login host/package heuristics), counter persistence, explicit user verification/selection.
- **Interop & security:** encrypted backup round-trips via payload; CSV passkeys likely unsupported initially (must avoid silent loss/leakage); threat-model updates for ceremony/RP binding/counters.
- **Risks/open decisions:** key-handling strategy (vault-held Rust key vs hardware/platform-backed), target SDK/dependency matrix, provider backport/support, and ceremony API split.

**Initial observations (codebase/platform touchpoints)**
- Existing autofill: `crates/keyel_core/src/autofill.rs`, `rust/src/api/autofill.rs`, `lib/features/autofill/**`, `android/app/src/main/kotlin/com/freesoftware/keyel/autofill/*` (e.g. `KeyelAutofillService`, parser/activities, manifest declarations), `lib/main_autofill.dart`.
- Vault/session: schema migrations and secret-handling patterns established in 1.3.0 apply to passkey private material (must be encrypted at rest, zeroized, never exposed in summaries/diagnostics).
- Bridge/UI: FRB DTO/API additions and regenerated bindings required; adding an `EntryKind`/body variant is cross-cutting across Rust core/API and many Flutter switches.

**Recommended next steps (from spike)**
1. Decide/document **key-handling strategy** (vault-held software key in Rust vs hardware/platform-backed) and backup/portability/security implications.
2. Confirm **target Android/SDK and dependency versions** for Credential Manager provider support; prototype **`CredentialProviderService` skeleton + manifest + capability detection** on API 34+.
3. Implement **schema v4 draft in core** (types, migration, zeroize, search/subtitle, tests), then extend API/FRB/bindings and fix exhaustiveness.
4. Define **ceremony API contract** (Kotlin ↔ Flutter ↔ Rust) with strict no-secret-crossing boundaries, then build create/get end-to-end with management UI and unsupported states.

---

## 5. Working tree / commits

- **`08a9d34`** — wip(1.3.0): schema v3 core/API/bindings + preservation wiring + roadmap/audit/docs baseline.
- This update completes 1.3.0 implementation (entry UI, CSV custom-field mapping, tests/analyze fixes, changelog/roadmap/audit updates) and initiates 1.4.0 kickoff documentation/status.

