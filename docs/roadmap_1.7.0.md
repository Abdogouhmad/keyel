# Keyel Roadmap: 1.7.0 — opt-in breach check

This roadmap covers one phase after the 1.5.0 E2EE sync release: an optional
Have I Been Pwned (HIBP) password breach check. It deliberately **narrows**, but
does not remove, the offline-first promise: Keyel stays local and offline by
default, and makes exactly one additional network request only after the user
explicitly opts in and starts a check.

Version numbering: 1.6.0 (one-tap lock / Quick Settings tile / shortcuts /
widgets) is a separate, not-yet-started idea. This document targets 1.7.0 as
requested; see `docs/DECISIONS.md` (2026-11-20).

Each phase is one version. Finish the **Definition of done**, then merge to
`main`. As since 1.5.0, the release workflow creates the tag: bump
`pubspec.yaml` and add a `CHANGELOG.md` section, push to `main`, and let CI cut
`v<version>`. **Never push tags by hand.**

**Rules for this phase**
- No Keyel account, no Keyel server, and no new Android permission. `INTERNET`
  already exists for OTA.
- The vault, the master password and every plaintext password stay in Rust.
  Dart receives only 5-character hash prefixes to fetch, and only breach
  counts to display. The HTTP body is an opaque transport value: Dart never
  parses it, maps suffixes, or interprets a result.
- No full SHA-1 digest, password, username, breach response, or result state is
  ever persisted, logged, added to diagnostics, or included in a result DTO.
  The only response data in Dart is the transient raw body of the one fetch
  DTO, passed straight back to Rust.
- Opt-in is off by default and revocable. The user sees exactly what is sent
  before enabling it. Nothing is checked in the background or at unlock.
- A failed, partial, or unparsable response never changes vault data and never
  produces a "no breaches" claim.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 1.6.0 | One-tap lock / quick access (reserved, not started) | 1 week | ☐ |
| 1.7.0 | Opt-in HIBP k-anonymity breach check | 1–1.5 weeks | ◐ (code complete, device smoke pending) |

Legend: ☐ todo · ◐ code complete, on-device verification pending · ☑ done

---

## 1.7.0 — Opt-in breach check

**Goal:** let a user find out whether any password stored in the vault has
appeared in a known breach, without sending a password or a full hash to
anyone, and without changing the default offline behavior.

> **Kickoff (2026-11-20):** user chose the 1.7.0 breach-check phase and asked for
> this roadmap first. Design: Rust computes SHA-1 and keeps full digests in a
> zeroized pending check; Dart fetches 5-character ranges over hard-coded HTTPS
> and returns only raw bodies; Rust matches and returns titles/counts.
>
> **Complete (2026-11-20, code level):** `breach` core module with known-answer
> and parser tests, bridge APIs with lock-safe cleanup and response-coverage
> checks, regenerated FRB bindings,
> `BreachService` + Riverpod opt-in/check providers, a gated security-dashboard
> row with disclosure dialog, 11 new Dart tests, threat model/decision log/README
> updates, and the 1.7.0 version/changelog bump. The manual device smoke below
> is the only item that cannot run in CI.

**Definition of done**
- A security-dashboard action checks all active login passwords, gated by an
  unlocked vault and an explicit, informed, revocable opt-in.
- Only the first 5 uppercase hex characters of a SHA-1 digest are sent, over
  HTTPS, to `https://api.pwnedpasswords.com/range/`; the digest is computed in
  Rust and never exposed to Dart.
- Results are matched in Rust and surfaced as secret-free entry titles and
  breach counts. No plaintext secret, full hash, or parsed breach response
  reaches the UI, storage, logs or diagnostics. The raw body exists only as an
  opaque transport string in Dart and the fetch DTO, and is never persisted.
- Locking the vault, an error, or a cancelled check discards all ephemeral
  comparison state; no check runs while locked.
- Core and Dart tests, regenerated FRB bindings, `cargo fmt`, `cargo clippy
  -D warnings`, `cargo test`, `flutter analyze` and `flutter test` pass; docs,
  changelog and version are updated for the CI-driven release.

### Knowledge
- HIBP k-anonymity range API: GET `/range/{first5}`; response lines are
  `SUFFIX:COUNT` (uppercase hex suffix + decimal count). Only a 20-bit prefix
  leaves the device; the full comparison happens locally. SHA-1 here is
  **protocol compatibility**, not password storage — see `docs/crypto-design.md`
  and the existing TOTP SHA-1 use in `crates/keyel_core/src/totp.rs`.
- Rust core conventions: `crates/keyel_core/src/health.rs` iterates non-deleted
  `EntryBody::Login` entries without returning passwords; `sha1 = "0.10"` and
  `zeroize` are already dependencies.
- Bridge conventions: `rust/src/api/session.rs` (`with_session`, `drop_session`),
  `rust/src/api/sync.rs` (two-phase API with secret-free DTOs),
  `rust/src/api/error.rs` (unit error variants), DTOs in
  `rust/src/api/models.rs`, generated bindings under `lib/src/rust/**`.
  Regenerate with `flutter_rust_bridge_codegen generate` (no `--no-web`).
- Flutter conventions: `lib/data/app_preferences.dart` (`settings.json`,
  non-secret preferences only), `lib/data/vault_repository.dart` (thin wrappers
  over generated APIs), Riverpod notifiers in `lib/data/**`, OTA's injectable
  `http.Client` + `MockClient` test pattern in `lib/core/ota/ota_service.dart`
  and `test/ota_test.dart`.
- UI: `lib/features/security_dashboard/widgets/breach_check_row.dart` is
  currently static placeholder copy ("local bloom filter") and must be replaced
  with the real, gated flow. `test/security_screen_layout_test.dart` asserts the
  current copy.

### Protocol and trust boundaries

1. **Prepare (Rust, unlocked session only).** For every active login with a
   non-empty password, compute `SHA-1(password)` in Rust as uppercase hex.
   Store the digest (zeroized) together with the entry id/title in a
   bridge-local pending check; return an opaque token and the deduplicated
   5-character prefixes to Dart.
2. **Fetch (Dart).** For each prefix, issue a sequential HTTPS GET to the
   hard-coded HIBP range endpoint with a descriptive `User-Agent` and a timeout.
   Dart receives only a response body string; it computes no hash.
3. **Compare (Rust).** Dart returns the token and the range bodies. Rust
   requires exactly one body per requested prefix and rejects malformed bodies;
   it then parses `SUFFIX:COUNT` lines, compares suffixes against the stored
   digests, clears the pending state, and returns only
   `(entry id, entry title, count)` matches.
4. **Display (Dart).** Show "no exposed passwords found" or a list of entry
   titles with breach counts. Never display a password or digest.

The HIBP service and any network observer learn only that *some* password with
a given 20-bit hash prefix is being looked up. They never learn the password,
the username, the vault, or which Keyel user asked. This is the only new data
egress in 1.7.0, and it is off unless the user turns it on.

### Todo

1. **Core (`crates/keyel_core`)**
   - [x] Add `breach` module: SHA-1 digest → uppercase hex, 5-character prefix,
         `SUFFIX:COUNT` parser (`count_for_suffix`), and opaque token generator.
   - [x] Add known-answer tests (SHA-1 vectors, prefix/suffix split, duplicate
         and malformed lines, counts, empty body) and zeroization expectations.
   - [x] Register the module in `crates/keyel_core/src/lib.rs`.

2. **Bridge (`rust/src/api`)**
   - [x] Add `breach` API module with `begin_breach_check`,
         `finish_breach_check`, `cancel_breach_check` and secret-free DTOs
         (request: token/prefixes/checked count; result: id/title/count matches).
   - [x] Keep pending digests in a Rust-only `Mutex`, wrapped in `Zeroizing`,
         cleared on finish, cancel, error and `drop_session` (lock).
   - [x] Add coarse unit error variants (check already active, invalid/cancelled
         token, invalid response) without diagnostic detail; register the module
         and regenerate FRB bindings.

3. **Dart data layer**
   - [x] Add `breachCheckEnabled` (default `false`) to `AppPreferences` with
         round-trip tests; keep all result and hash state out of storage and the
         diagnostics allow-list.
   - [x] Add injectable `BreachService` for the HTTPS range request (hard-coded
         endpoint, timeout, status handling, no configurable URL), tested with
         `MockClient` including failure cases.
   - [x] Add Riverpod providers for opt-in and check state, plus thin
         `VaultRepository` wrappers over the generated bridge APIs. The run
         method refuses to start unless unlocked and opted in.

4. **Flutter UI**
   - [x] Replace the static `BreachCheckRow` with the gated row: clear opt-in
         disclosure dialog, opt-in switch, "Check now" action, running state,
         result summary, match list, and actionable error state.
   - [x] Keep titles/counts only; add semantics labels, high-contrast and 200 %
         font-scale safe layout; update `security_screen_layout_test.dart` and
         add widget tests for opt-in, running, result and error states.

5. **Security, docs and release prep**
   - [x] Extend `docs/threat-model.md` (new threat for breach-check egress and
         HIBP/misconfiguration) and `docs/DECISIONS.md` (privacy-promise change).
   - [x] Update `README.md`'s `INTERNET` explanation and `docs/plan.md`'s
         breach-check note to point at 1.7.0.
   - [x] Run the full CI suite locally, regenerate bindings cleanly, bump
         `pubspec.yaml` to `1.7.0+1` and add the `[1.7.0]` `CHANGELOG.md` entry.
   - [ ] Manual device smoke: enable/disable, offline failure, locked vault,
         known-breached test password (`password`), relock mid-check.

### Risks and mitigations
- **Leaking more than a prefix:** only Rust computes hashes; Dart-visible DTOs
  carry prefixes, entry titles and counts only, never a password or digest.
- **Sending the master password by mistake:** only active `Login` entry
  passwords are considered; the master password is never in the vault payload
  and is never passed to this flow.
- **Stale pending state after lock:** `drop_session` clears it, and every exit
  path (finish/cancel/error) takes and drops it.
- **Malicious response causing false assurance:** Rust requires one body per
  requested prefix and rejects non-empty bodies with malformed lines; any
  missing, duplicated or unparsable response is an error, never "no breaches".
- **Privacy-promise confusion:** explicit disclosure dialog, README wording,
  threat model and decision log all describe the one new endpoint.

### Sequencing notes
- Core and bridge work comes before UI, per the project rule "crypto gets tests
  before UI".
- No schema change: the opt-in flag lives in `settings.json`, not the vault, so
  1.5.0 sync payloads and v1–v5 vaults are unaffected.
- On-device smoke (including a real HIBP response) remains manual and is the
  only item that cannot be completed in CI.
