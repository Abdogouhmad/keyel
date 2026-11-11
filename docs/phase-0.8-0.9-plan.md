# Plan — Phases 0.8.0 and 0.9.0

**Branch:** `phase/0.8-0.9-generator-totp-security`
**Base:** `phase/0.6-0.7-lock-and-vault-ui` @ `3c9e993` (clean, `flutter analyze` clean, all tests green)
**Status:** phase 0.8 implemented (`72f3694`); phase 0.9 **not started** (see the estimate below).

Priority when documents disagree: **roadmap > plan > design** (`docs/DECISIONS.md`).

---

## 0. Progress update — 2026-11-11

### Done (phase 0.8, commit `72f3694`)
- **Rust TOTP** (`crates/keyel_core/src/totp.rs`): base32 decode, HOTP (RFC 4226),
  TOTP (RFC 6238), `seconds_left`, `parse_otpauth`; RFC SHA-1/256/512 vectors
  and malformed-input tests. Bridge `current_code` / `parse_otpauth`; bindings
  regenerated.
- **Generator**: passphrase `separator` (core + bridge + UI); all generator
  options persisted in `AppPreferences`; passphrase strength corrected to
  10 bits/word for the 1024-word list.
- **TOTP UI**: entry detail shows a live self-refreshing code; the editor sets
  the secret via a validated manual-entry dialog and preserves the parsed
  algorithm/digits/period.
- **Tests**: Rust 50 core + 12 + 10; Dart 31 (strength, preference
  round-trip, TOTP section states). `cargo fmt/clippy/test`, FRB idempotency,
  `flutter analyze`, `flutter test` all green.

### Deferred from phase 0.8 (recorded in `docs/DECISIONS.md`)
- 0.8.2 Rust `zxcvbn` `estimate_strength` (Dart heuristic still used).
- 0.8.4 "Use this password" bottom sheet (the editor's inline generate button
  already covers the core need).
- 0.8.5 QR scanning (`mobile_scanner`); manual entry is the supported path.
- Exposing per-class min-counts over the bridge (core already supports them;
  no UI consumes them).

### Phase 0.9 estimate
Phase 0.9 is roughly **3–4×** the code and integration of phase 0.8: the
encrypted backup round trip (`backup.rs`) is comparable to the vault format
work, the CSV import adds two parsers plus a dedup/preview/report UI, the
health analyser needs reuse detection over salted in-memory hashes, and it
adds `zxcvbn` + `file_picker` (native picker). Phase 0.8 alone consumed a
large share of this session. **Recommendation: stop here; phase 0.9 will not
fit the remaining budget at the same tested quality.**

---


## 1. Where we are today (gap analysis)

### Generator — mostly done
| Piece | State |
|---|---|
| `crates/keyel_core/src/generator.rs` | ✅ bias-free selection (`OsRng` + rejection sampling), guaranteed minimum counts, Fisher-Yates shuffle, `Zeroizing` output. Tests: length/charset, min counts, only-digits, impossible constraints, no-char-class, ambiguous exclusion, statistical sanity, length sweep. |
| `crates/keyel_core/src/pass_words.rs` | ⚠️ curated **1024-word** list (10 bits/word), not the EFF 7776-word list the roadmap asks for. |
| `rust/src/api/generator.rs` | ⚠️ exposes `generate_password` (no min-count params) and `generate_passphrase` (**no separator**). |
| `lib/features/generator/generator_screen.dart` | ✅ already wired to the Rust API (mode toggle, length/word slider, class switches, exclude-ambiguous, strength meter, copy). |
| Options persistence / "Use this password" in Add-Edit / supporting pane | ❌ not done (roadmap 0.8.5–0.8.6). |
| Password strength | ⚠️ Dart heuristic only (`lib/core/security/password_strength.dart`); no Rust `zxcvbn`. |

### TOTP — not started
- No `totp.rs`, no bridge, no `current_code`/`parse_otpauth`.
- UI hooks exist but are placeholders: design-system `KeyelTotpDisplay` (live ring), `TotpSection` in the edit form, `has_totp` on `EntrySummary`, TOTP filter chip — all currently show "arrives later" snackbars.

### Security dashboard — prototype only
- `lib/features/security_dashboard/` (screen + 10 widgets) renders on demo data; every action calls `_notYet(...)`.
- No `health.rs`; no real analyser.

### Backup / import — not started
- `lib/features/totp/` and `lib/features/import_export/` contain only `.gitkeep`.
- No `backup.rs`, no CSV importers, no bridge.

### Docs debt
- `docs/DECISIONS.md` (2026-11-05) is stale: "generator UI exposes only options the Rust API supports" and "passphrase mode is a local placeholder" no longer describe the code.

---

## 2. Dependencies to add

| Where | Crate / package | Why |
|---|---|---|
| `crates/keyel_core` | `zxcvbn` | strength estimation for the generator and the 0.9 health analyser |
| `crates/keyel_core` | `hmac`, `sha1` (or `totp-rs` with `otpauth`) | TOTP/HOTP |
| `pubspec.yaml` | `mobile_scanner` | QR scanning for 2FA (camera permission) |
| `pubspec.yaml` | `file_picker` | SAF file open/save for backup & CSV (`share_plus` already present) |

Keep the `cargo audit` surface minimal and pin new deps (project rule).

---

## 3. Phase 0.8.0 — Generator and TOTP

**Goal:** a good password/passphrase generator and working two-factor codes.
**Definition of done:** adding a real 2FA account by QR produces codes the real login accepts; generator output is covered by tests and options persist.

### 0.8.1 — Rust generator completion
- Add a `separator` option to `PassphraseOptions` (default `-`).
- Expose min-counts and separator through `rust/src/api/generator.rs`.
- Decide the wordlist (see Q2): either bundle the EFF long 7776-word list or keep the curated list and document the entropy.
- Tests: separator behaviour, entropy accounting matches the bundled list size, keep the existing suite green.

### 0.8.2 — Rust strength (`estimate_strength`)
- Add `crates/keyel_core/src/strength.rs` using `zxcvbn`: `estimate_strength(pw) -> Strength { score: 0..4, feedback }`.
- Expose via FRB; route the generator UI and (later) health through it. Resolves the 0.6 leftover.
- Tests: known weak/strong samples.

### 0.8.3 — Rust TOTP
- `crates/keyel_core/src/totp.rs`: base32 decode, HOTP (RFC 4226), TOTP (RFC 6238), `seconds_left`, `parse_otpauth`.
- Tests: RFC 6238 SHA-1/256/512 vectors, period/digits handling, malformed base32 and malformed `otpauth://`.
- Expose `current_code` and `parse_otpauth` through `rust/src/api/totp.rs`.

### 0.8.4 — Generator UI completion
- Remember last options (length, mode, switches) in `AppPreferences`.
- "Use this password" bottom sheet inside Add/Edit; on Expanded show it as the supporting pane (plan §adaptive).
- Swap the Dart strength heuristic for the Rust estimate where it matters.

### 0.8.5 — TOTP UI
- Entry detail: live code via `KeyelTotpDisplay`, refreshed by a Dart ticker (not per-frame Rust calls) + Copy.
- Add/Edit Login: wire `TotpSection` — scan (QR) or type a base32 key, validate via `parse_otpauth`.
- QR scan screen: `mobile_scanner`, camera-permission rationale, flashlight, error state, manual-entry fallback.

### 0.8.6 — Tests
- Generator widget tests; TOTP ticker test with fake time; scan flow with a mocked scanner; option persistence.

---

## 4. Phase 0.9.0 — Security dashboard, backup, import

**Goal:** vault health insights and safe data in/out.
**Definition of done:** export → wipe app data → import restores every field exactly; importing a real Bitwarden/Chrome export works and the dashboard shows sensible numbers.

### 0.9.1 — Rust health analyser
- `crates/keyel_core/src/health.rs`: `analyze() -> HealthReport { weak, reused, old, no_2fa, insecure_urls }`.
- Reuse detection compares salted hashes **in memory only**; passwords never leave Rust.
- Tests: fixtures for each category, empty vault, perfect score.

### 0.9.2 — Security dashboard wiring
- Replace demo data with the report; score ring, issue cards, filtered lists, "Fix" action opening edit with the generator, perfect-score state.

### 0.9.3 — Encrypted backup
- `crates/keyel_core/src/backup.rs`: `export_encrypted(path, password)` / `import_encrypted(path, password, Merge | Replace)`, reusing the vault format with a separate backup password.
- Tests: round trip, wrong password, merge vs replace.
- UI: export with password + strength meter, success sheet with Share; import picker with mode choice.

### 0.9.4 — CSV import
- Bitwarden and Chrome parsers; map fields; preview counts; de-duplicate (title + username + URL); Merge/Replace; import report.
- Tests: 1,000-row import, malformed CSV, UTF-8 BOM, duplicates.

### 0.9.5 — Optional
- Unencrypted CSV export behind a red warning + explicit confirmation; delete the temp file after sharing. (Roadmap marks this optional — see Q9.)

---

## 5. Cross-cutting

- Regenerate FRB bindings and commit them (CI fails if `lib/src/rust` is out of date).
- Keep `cargo fmt --check`, `cargo clippy -D warnings`, `cargo test`, `flutter analyze`, `flutter test` green at every commit.
- Crypto/TOTP/health get Rust tests before UI (project rule).
- Update `docs/DECISIONS.md` (stale generator notes + any decisions taken here) and tick the roadmap tracker rows for 0.8.0 / 0.9.0.
- Device checks that can't be automated: a real 2FA account, and a real Bitwarden/Chrome export.

---

## 6. Open questions (please confirm before I start)

1. **Branch scope** — the roadmap is "one phase = one branch", but this branch covers both 0.8 and 0.9 (as requested). Keep `phase/0.8-0.9-generator-totp-security`, or split into two branches?
2. **Wordlist** — bundle the EFF long 7776-word list (roadmap) or keep the curated 1024-word list and document the lower entropy?
3. **Strength** — add Rust `zxcvbn` now (needed for 0.9 health) and use it for the generator too, or keep the Dart heuristic for the generator and only use `zxcvbn` inside health?
4. **TOTP crate** — `totp-rs` (batteries included) or hand-rolled `hmac` + `sha1` + `data-encoding` (smaller dep surface)?
5. **QR scanning** — OK to add `mobile_scanner` (native camera dependency)? Manual base32 entry stays as a fallback either way.
6. **File access** — OK to add `file_picker` for backup/CSV, using SAF (no broad storage permission)?
7. **Order** — 0.8 fully first, then 0.9? Or interleave (e.g. Rust `zxcvbn` shared early)?
8. **0.6 leftovers** — include the Rust `estimate_strength`/zxcvbn work and the DECISIONS cleanup in this branch (recommended)?
9. **Unencrypted CSV export** — implement in 0.9, or defer?
10. **Scope confirmation** — anything in the roadmap 0.8/0.9 lists you want to cut or pull forward (e.g. defer QR scanning, ship TOTP manual-entry first)?
