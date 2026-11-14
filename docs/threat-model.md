# Keyel threat model

Status: initial model for phase 0.11.0 (hardening). Scope: the Android app and
the Rust core it embeds. Companion documents: `docs/crypto-design.md` (normative
vault format), `docs/vault-model.md` (payload schema) and
`docs/hardening-checklist.md` (item-by-item status).

This document is deliberately concrete: every mitigation names the code that
implements it, and every open item names what is missing. It is not a
substitute for the independent review planned before 1.0 (roadmap item 0.11.13).

## 1. What we are protecting

| Asset | Where it lives | Why it matters |
|---|---|---|
| Vault body (all entries, notes, card data, TOTP secrets) | `vault.keyel`, app-private storage | The user's whole digital life |
| Vault key (32 random bytes) | Rust process memory only | Decrypts the body; never crosses the bridge |
| Master password | User's head; transiently in Dart and Rust | Wraps the vault key; also the recovery fallback |
| Recovery key (one-time) | User's offline copy | Second way to unwrap the vault key |
| Encrypted backup password | User's head | Protects exported backups |
| Revealed secrets (one field at a time) | Dart widget memory, clipboard | Exposed by explicit user action |
| Keystore-wrapped master password (biometric unlock) | Android Keystore-backed store | Lets biometric unlock re-open the vault |

## 2. Trust boundaries

```
 user  ──▶  Flutter/Dart UI  ──▶  flutter_rust_bridge  ──▶  Rust core (keyel_core)
 (trusted)      (semi-trusted)        (boundary B)             (trusted for secrets)
                     │
                     ├──▶ Android platform (Keystore, BiometricPrompt, Autofill)  (trusted)
                     └──▶ Other apps / Chrome via the Autofill framework          (untrusted)
```

- **B — Dart↔Rust bridge.** Dart never holds the vault key. The only function
  that returns a secret is `api::entries::reveal_field`; it returns exactly one
  requested field. See `rust/src/api/entries.rs`.
- **Autofill boundary.** `KeyelAutofillService` parses an untrusted
  `AssistStructure` and matches it against the vault. Matching is authoritative
  in Rust (`keyel_core::autofill::find_matches`), never in Kotlin.
- **Filesystem.** `vault.keyel`, `vault.keyel.bak`, `settings.json` and any
  CSV/backup the user exports all live under app-private storage.

## 3. Assumptions and non-goals

Assumed true (else the model changes):

- The Android OS, its Keystore and the user's device are not compromised.
- The app is installed from a trusted source and signed with Keyel's key.
- The user's master password and recovery key are strong and kept offline.
- Physical access to an **unlocked, rooted** device is largely out of scope;
  we still minimise what such an attacker gets (see T9, T10).

Out of scope for v1: multi-user vaults, server-side sync (there is no server and
no `INTERNET` permission), hardware security keys, coercion resistance, and
protecting data the user deliberately exports to CSV.

## 4. Adversaries

| Id | Adversary | Capability |
|---|---|---|
| A1 | Opportunistic thief | Has the locked device; no root |
| A2 | Malicious app on the device | Runs in its own sandbox; can drive Autofill |
| A3 | Network attacker | Irrelevant in v1: the app has no network permission |
| A4 | Offline attacker | Has a copy of `vault.keyel` (e.g. from a backup) |
| A5 | Shoulder surfer / screen recorder | Can see the screen and the task switcher |
| A6 | Forensic examiner | Full disk image of a rooted or unlocked device |

## 5. Threats and mitigations

### T1 — Theft of the vault file at rest (A1, A4)

The whole payload is XChaCha20-Poly1305 encrypted under a random vault key; the
key is only recoverable by unwrapping it with a KEK derived by Argon2id
(master) or HKDF (recovery). Parameters are validated and capped on read so a
tampered header cannot force an unbounded allocation. The format fails closed
and does not reveal which step failed. See `docs/crypto-design.md`,
`crates/keyel_core/src/format/`.

*Residual:* an offline attacker can brute-force the master password at the cost
of Argon2id per guess. The default parameters (see `Argon2Params::default`) are
the mitigation; strength depends on the user's password.

### T2 — Plaintext left on disk (A1, A6)

- `android:allowBackup="false"` and explicit `dataExtractionRules` /
  `backup_rules` keep the vault out of cloud backups
  (`android/app/src/main/AndroidManifest.xml`).
- `build.sh` fails a release that requests `INTERNET`, is debuggable, or does
  not set `allowBackup="false"`.
- The vault lives in `getApplicationSupportDirectory()` (app-private).
- Secrets are never written to `settings.json` (non-secret UI preferences only,
  `lib/data/app_preferences.dart`).

*Open:* the on-device `adb run-as` storage dump (roadmap 0.11.4) still needs to
be performed on a real build; see `docs/hardening-checklist.md`.

### T3 — Secrets in logs (A2, A6)

- Rust has **no** `println!`, `eprintln!`, `dbg!` or `log::` calls.
- Dart has a single logging call, `lib/main.dart:41`, which reports only a
  storage error, never a secret.
- `Debug` impls redact secrets: `Session`, `UnlockedVault` print `[REDACTED]`.
- `build.sh --obfuscate` strips Dart symbols from release builds.

*Open:* an `adb logcat` sweep across every flow on a device (roadmap 0.11.2).

### T4 — Secrets lingering in memory (A6)

- Key material is wrapped in `zeroize::Zeroizing`: `VaultKey`, `Kek`,
  `RecoveryKey` (`crates/keyel_core/src/crypto/`).
- The decrypted payload is `Zeroizing<Vec<u8>>` (`format::UnlockedVault`) and is
  wiped on drop.
- `Vault` wipes every secret field on drop; `update_entry`, `purge_entry` and
  `purge_expired` wipe the replaced/removed entry
  (`crates/keyel_core/src/vault/model.rs`, `zeroize_secrets`).
- Bridge functions that take a master password, recovery key or backup password
  wrap the owned `String` in `Zeroizing` so the Rust-side buffer is wiped on
  return (`rust/src/api/session.rs`, `rust/src/api/import_export.rs`).

*Residual (accepted):* a `String` copied by a caller before wiping, and the
Dart-side copy of a password, cannot be tracked. `EntryDraft` DTO secrets are
dropped without an explicit wipe because a `Drop` impl would forbid moving
fields out of it; the window is a single bridge call. `reveal_field` returns a
`String` that the Dart side owns — that is the feature, not a bug, and the UI
reveals on demand and clears the clipboard after a delay.

### T5 — Shoulder surfing and screenshots (A5)

- `FLAG_SECURE` is toggled through `keyel/platform` (`setSecure` in
  `MainActivity.kt`, `lib/core/platform/secure_screen.dart`); while on, the OS
  blocks screenshots and blanks the Recents thumbnail.
- The autofill picker activity is `excludeFromRecents` and `noHistory`.
- Passwords are masked by default in the UI.
- Copied secrets are flagged sensitive and auto-cleared
  (`lib/core/platform/sensitive_clipboard.dart`).

*Open:* an on-device check that `FLAG_SECURE` is actually engaged on every
secret-bearing screen.

### T6 — Malformed or malicious vault bytes (A4)

The parser is the only code that consumes untrusted bytes. It is fuzzed with
`cargo-fuzz` (`crates/keyel_core/fuzz/fuzz_targets/parse_vault.rs`) and now runs
nightly for one hour in CI (`.github/workflows/fuzz.yml`). The fuzzer uses a
fixed 32-byte key so iterations are not spent in Argon2id; the password path is
covered by unit tests. The canonical-CBOR check rejects non-canonical encodings
so a length-marker flip cannot deserialize to the same struct.

*Open:* a longer (multi-hour) soak and turning any crash into a regression test.

### T7 — Autofill misfill into the wrong app or site (A2)

`keyel_core::autofill::find_matches` matches an app only on its exact Android
package and a site only on the same host or a label-boundary subdomain
relationship. Look-alikes (`evil-paypal.com`, `paypal.com.evil.net`) never
match. Weaker text hits are surfaced only through an explicit search box and are
labelled `MatchQuality::Search` so the picker warns about a possible mismatch.
There is **no public suffix list yet**, so we never collapse to an eTLD+1 guess.

*Residual:* without a PSL, `foo.co.uk` and `bar.co.uk` are not recognised as
siblings; the conservative rule errs toward not matching.

### T8 — Malicious Autofill caller (A2)

`KeyelAutofillService` is bound with `BIND_AUTOFILL_SERVICE` (system only) and
the picker activity is `exported="false"`. Field parsing walks an untrusted
`AssistStructure` defensively. Autofill only ever fills a field the framework
identified; it never returns the whole vault.

### T9 — Brute force against the running app (A1)

*Gap.* The plan's checklist asks for an **exponential delay** on repeated wrong
master-password attempts (never a wipe). This is **not implemented yet**: the
unlock path (`lib/data/vault_session_provider.dart`) currently reports a wrong
password immediately with no backoff. Argon2id still makes each online guess
expensive, and a thief with the device can also attack the file offline (T1),
so the delay is a usability-vs-security speed bump rather than the primary
defence. Tracked in `docs/hardening-checklist.md`.

### T10 — Recovery key and biometric credential (A1, A6)

- The recovery key is shown once at creation and never returned again; only its
  HKDF-derived KEK wraps the vault key. Resetting the master password preserves
  the recovery slot.
- Biometric unlock requires a **strong** (Class 3) modality
  (`BiometricAuth._isStrong`) and hands the check to the OS `BiometricPrompt`.
  The master password is stored in Keystore-backed storage **only** after a
  successful password unlock with biometrics enabled.

*Residual:* on a rooted/compromised device the Keystore may be defeated and the
stored master password recovered. Users who do not want this can leave
biometric unlock off; the setting is explicit.

### T11 — Backup and CSV export (A4)

- Encrypted backups reuse the vault format under a user-chosen password and are
  read back through the same hardened parser.
- CSV export is unencrypted by design; the UI warns and requires explicit
  confirmation. The file is the user's responsibility after export.

### T12 — Supply chain (A3-adjacent)

- `Cargo.lock` and `pubspec.lock` are committed.
- `cargo audit` (RustSec advisories) and `cargo deny` (advisories, bans,
  licences, sources) run on every push and pull request
  (`.github/workflows/ci.yml`).
- `deny.toml` restricts licences to a reviewed allow-list.

*Open:* dependency update cadence is manual; no `dependabot`/`renovate` yet.

## 6. Verification map

| Threat | How it is checked |
|---|---|
| T1, T6 | `crates/keyel_core` unit/property tests; `cargo fuzz` (nightly) |
| T2 | `build.sh` policy checks (no INTERNET, not debuggable, `allowBackup=false`); on-device dump pending |
| T3 | Source grep (documented in `docs/hardening-checklist.md`); `adb logcat` pending |
| T4 | `zeroize_secrets` unit test; `Zeroizing` wrappers; review |
| T5 | Manual on-device pass pending |
| T7, T8 | `keyel_core::autofill` unit tests |
| T12 | `cargo audit` + `cargo deny` CI job |

## 7. Open items

1. Wrong-attempt exponential delay (T9) — design + implement + test.
2. On-device storage dump, `adb logcat` sweep, `FLAG_SECURE` verification,
   release-APK functional test (T2, T3, T5) — need a physical device.
3. Multi-hour fuzz soak and crash-to-regression promotion (T6).
4. Independent review of this document and `docs/crypto-design.md` before 1.0.
5. Optional: a public suffix list for web matching (T7).

_Last updated: 2026-11-14._
