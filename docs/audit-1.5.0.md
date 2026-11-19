# Audit: 1.5.0 roadmap & custom-fields (1.3.0) progress

**Date:** 2026-11-19  
**Branch:** `phase/1.5.0` (from `main` @ `cfd3f0c`)  
**Scope:** Create `docs/roadmap_1.5.0.md` and begin implementing the roadmap (starting with 1.3.0 — custom fields for entries).

> This is a point-in-time engineering audit/report of work done in this branch. Changes are currently **uncommitted** (see “Working tree”).

---

## 1. What was delivered

### 1.1 Roadmap
- Added **`docs/roadmap_1.5.0.md`** covering phases **1.3.0 → 1.5.0** with goals/definition-of-done, knowledge areas, MVP data-model notes, task checklists, and sequencing:
  - **1.3.0 — Custom fields for entries** (in progress)
  - **1.4.0 — Passkeys (WebAuthn / Credential Manager)** (planned)
  - **1.5.0 — Opt-in user-controlled E2EE cross-device sync** (planned)

### 1.2 1.3.0 implementation progress (core/schema/API/bindings)

#### Vault core (Rust, `crates/keyel_core`)
- **Schema v3:** `VAULT_SCHEMA_VERSION` bumped `2 → 3` (v3 = ordered `custom_fields` on entries).
- **Model (`crates/keyel_core/src/vault/model.rs`, `mod.rs`):**
  - Added `CustomFieldKind { Text, Hidden, Url }` and `CustomField { id, label, value, kind }` (stable UUID id, `is_secret()` helper).
  - `Entry.custom_fields: Vec<CustomField>` with `#[serde(default)]` for backward-compatible reads of pre-v3 payloads.
  - **Secret handling:** `zeroize_secrets()` now wipes `Hidden` custom-field values (non-secret `text`/`url` values preserved), in addition to existing secrets.
  - **Search/indexing:** `matches_normalized` matches custom-field **labels** and **non-secret (`text`/`url`) values**; **hidden custom-field values are never matched** (passwords/notes/card secrets still excluded). Subtitles remain unchanged/non-secret.
- **Migration (`crates/keyel_core/src/vault/migrate.rs`):** stepwise migration to current (v1→v2→v3). v2→v3 is a default/no-op (empty `custom_fields`). Unknown/future versions fail closed.
- **Docs (`docs/vault-model.md`):** updated to payload schema v3 (entry/custom-field shape), search rules, versioning/migration history, and memory-hygiene notes to include hidden custom-field values.

#### Rust bridge/API (`rust/`)
- **DTOs (`rust/src/api/models.rs`):** `CustomFieldKindDto`, `CustomFieldDetailDto` (masked: hidden values never exposed; `has_hidden_value` flag), `CustomFieldDraft` (hidden `value: None` preserves existing secret on update); added `custom_fields` to `EntryDetailDto` and `EntryDraft`; core↔DTO mapping and `map_custom_fields` to preserve hidden secrets by field id when omitted.
- **Entries API (`rust/src/api/entries.rs`):** `upsert_entry` now loads/persists `custom_fields` (preserving existing on update); added **`reveal_custom_field(id, field_id)`** — explicit reveal path that only returns values for `Hidden` custom fields (non-secret fields rejected).
- **FRB bindings regenerated** (`flutter_rust_bridge_codegen generate`): updated `lib/src/rust/api/entries.dart`, `lib/src/rust/api/models.dart`, `lib/src/rust/frb_generated*.dart`, and `rust/src/frb_generated.rs`.

#### Flutter integration (compatibility & no data-loss wiring)
- **Repository (`lib/data/vault_repository.dart`):** added `revealCustomField(id, fieldId)` wrapper.
- **Draft/custom-field preservation through existing flows** (hidden values sent as `null` to preserve on update, avoiding silent loss until full UI lands):
  - `lib/features/entry/entry_edit_controller.dart`: loads custom fields from detail into drafts (hidden masked), stores them on controller, includes in save draft.
  - `lib/features/entry/entry_detail_controller.dart`, `lib/features/vault/widgets/vault_favorite_button.dart`: favorite-toggle upserts preserve custom fields.
  - `lib/data/vault_repository.dart` (`createLogin`, `setFavorite`), `lib/features/autofill/autofill_save_screen.dart`: updated drafts to include `customFields` (new entries empty).
- **Tests updated:** `test/autofill_picker_screen_test.dart` fake `EntryDetailDto` includes `customFields`.

---

## 2. Verification performed

| Check | Result |
|---|---|
| `cargo test -p keyel_core` | **Passed** — 110 lib tests + integration suites (12 + 11, 1 ignored: production KDF perf/manual), 0 failed |
| `cargo test -p keyel_core` (post-index/model test additions) | **Passed** — 110 lib tests total, 0 failed (see above run output) |
| `flutter analyze lib test` | **Clean** — no issues |
| `flutter test` | **Passed — 125/125 tests** (completed in environment; includes perf/layout suites) |

**Targeted core tests added/updated for custom fields**
- `vault::model::tests::serialize_round_trip_is_lossless` — includes `text/hidden/url` custom fields.
- `vault::model::tests::zeroize_secrets_clears_every_secret_field` — asserts hidden custom-field value wiped, non-secret values retained.
- `vault::index::tests::search_matches_non_secret_custom_fields_but_not_hidden_values` — labels and non-secret values searchable; hidden values not searchable.
- Migration tests updated for v3 path (`current_version_migrates_without_changes`, `v1_migrates_to_current_and_preserves_entries`, `v2_migrates_to_current_and_adds_empty_custom_fields`, unknown/future fail closed).

---

## 3. Security & privacy notes (as implemented)

- **Secrets stay local/offline:** no network surfaces added; vault remains encrypted-at-rest in the existing format/payload model.
- **Hidden custom fields treated as secrets:** masked in detail DTOs, wiped via `zeroize_secrets`, excluded from metadata search/index matching on values, and only retrievable via explicit `reveal_custom_field` for `Hidden` kind.
- **Reveal discipline:** fixed secrets still via `reveal_field`; hidden custom-field reveal is a separate explicit path; UI/controllers updated in this pass do not log secrets (existing patterns preserved).
- **Diagnostics:** no new diagnostics fields added; summaries/masked details remain secret-free (full diagnostics redaction review for custom fields should be re-checked when UI/CSV mapping lands).
- **Backward compatibility:** pre-v3 payloads load via defaults/migration; editing existing entries through updated flows preserves existing custom fields.

---

## 4. Gaps / remaining work (1.3.0)

Per `docs/roadmap_1.5.0.md`, the following 1.3.0 items are **not yet implemented**:

1. **Flutter entry UI (editor/detail)**
   - Editor: add/remove/reorder custom fields, choose type, edit label/value; small-screen usability.
   - Detail: render custom fields with copy, URL-open for `url`, and masked reveal/copy for `hidden` (consistent reveal timer/clipboard behavior).
   - Wire any additional list/autofill/debug surfaces as needed (keep secret-free).
2. **Import/export mapping for custom fields**
   - CSV export: include custom fields (e.g. Bitwarden `fields`-compatible encoding) without unsafe secret exposure; document behavior.
   - CSV import: map supported sources (notably Bitwarden `fields`) into typed custom fields where representable.
   - Add/confirm regression coverage for encrypted backup/restore and CSV round-trips with custom fields.
3. **Broader regression/tests**
   - Rust: API-level tests for reveal/mapping/CSV/backup cases involving custom fields (core coverage added; API/import/export coverage pending).
   - Flutter: widget/controller tests for custom-field edit/detail/reveal flows once UI exists.
4. **Release hygiene (on phase completion)**
   - `CHANGELOG.md` / user-facing docs updates for 1.3.0, and final manual smoke (create/edit/reorder/reveal/copy/URL, persistence across relock, backup restore, CSV import/export).

**Not started (future phases):** 1.4.0 passkeys and 1.5.0 opt-in user-controlled E2EE sync remain planned per roadmap.

---

## 5. Working tree (at audit time)

**Modified:** core vault (`model/index/migrate/mod`), `docs/vault-model.md`, Rust API + FRB generated files (`rust/src/api/*`, `rust/src/frb_generated.rs`, `lib/src/rust/**`), Flutter repository/controllers/save/favorite flows, and one test fixture.  
**Untracked:** `docs/roadmap_1.5.0.md`, `docs/audit-1.5.0.md`.

Recommended next commit granularity: (a) roadmap+audit/docs, (b) core schema/migration+tests, (c) API/FRB bindings, (d) Flutter preservation wiring/UI — or a single scoped 1.3.0-in-progress commit per project conventions.

---

## 6. Recommended next steps

1. Implement **custom-fields UI** (editor + detail with reveal/copy/URL-open) and controller state for add/remove/reorder, preserving masked hidden values on save.
2. Add **Bitwarden/CSV custom-field mapping** (import/export) with explicit handling for hidden/typed fields and tests; verify encrypted backup round-trips (payload already includes fields).
3. Run full verification again (`cargo test`, `flutter analyze`, `flutter test`) plus manual smoke; then update **`CHANGELOG.md`** and mark 1.3.0 done when criteria met.
4. Proceed to **1.4.0 platform spike** (passkeys/Credential Manager) and later **1.5.0 sync design spike** per roadmap sequencing.
