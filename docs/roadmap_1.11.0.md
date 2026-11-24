# Keyel Roadmap: 1.11.0 — security hardening, real multi-window layouts and codebase simplification

This is a **major maintenance release**, not a feature drop. It keeps the vault
format, the offline contract and every existing security promise intact while
changing three things across the whole app:

1. **Security hardening.** Secrets stay masked by default and get masked again
   on lifecycle changes; autofill fails closed; OTA verification is re-checked
   at the last possible moment; the secure-screen flag is set before the first
   frame on every entrypoint.
2. **Responsive UI.** The phone-sized layout stops scaling with window width.
   Shared layout primitives, direction-aware navigation/modals and real
   multi-column compositions make medium, expanded and large windows first-class
   targets for desktop, tablet and mobile.
3. **Codebase simplification.** Dead widgets, dead theme/app helpers, unused
   localization keys and misleading settings are removed. Repeated UI state and
   secret-copy logic are consolidated behind shared primitives.

No vault schema change, no Keyel account/server, no new broad permission, no
Arabic locale, and no weakening of lock/unlock/onboarding/autofill/passkey
security, clipboard wipe, screenshot blocking or fail-closed OTA checksum
verification. EN/FR parity and RTL layout correctness remain hard requirements.

Release stays CI-driven: bump `pubspec.yaml`, add a `CHANGELOG.md` section,
merge to `main`, and let the workflow cut `v1.11.0`. **Never push tags by hand.**
Beta remains a manual `workflow_dispatch` prerelease.

**Rules for this phase**

- Every new user-facing string goes into the template ARB with a description,
  with a complete French translation. Unused keys are removed in the same pass.
- A secret is never rendered in plaintext on build. Reveal is explicit, timed,
  and cancelled on lock, background and route changes.
- Autofill and passkey matching can only *narrow* the credential set. A text
  search hit is never treated as an identity match.
- OTA downloads require HTTPS and a valid SHA-256, and the downloaded file is
  re-hashed immediately before installation. Local APKs are explicitly marked
  as unverified.
- Every new or changed layout primitive must be direction-aware
  (`EdgeInsetsDirectional`, `AlignmentDirectional`, directional icons) and
  must not overflow at 200 % text scale.
- Sizes are fixed dp or text-scale-aware, never a fraction of window width.
- Full verification (Dart format/analyze/test, Rust fmt/clippy/test, secret-log
  guard, FRB idempotency, gen-l10n idempotency, Android and Linux debug builds,
  Wear Gradle tests) must be green before the version and changelog bump.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 1.11.0 | Security: secret reveal lifecycle + autofill fail-closed | — | ☑ |
| 1.11.0 | Security: OTA, secure screen, native hardening | — | ☑ |
| 1.11.0 | Responsive: fixed metrics, direction-aware primitives, multi-column layouts | — | ☑ |
| 1.11.0 | Codebase: dead code, dead strings, duplicated logic, reactive reads | — | ☑ |
| 1.11.0 | Docs, matrix tests and full verification | — | ☑ |

Legend: ☐ todo · ◐ in progress · ☑ done

---

## 1. Security hardening

**Goal:** close the gaps where a secret could be visible longer than the user
intended, where autofill could offer an unverified match, or where an update
could be installed from an unverified source.

### Definition of done

- Notes attached to a login/card/passkey are not rendered until the user taps
  reveal, use the same 15 s auto-hide as passwords, and hide on lock/background.
- A single reveal timer covers passwords, card numbers, CVVs, secure-note
  bodies, attached notes and hidden custom fields.
- `EntryDetailScreen` masks all reveals on `paused`, `hidden` and `detached`,
  independently of the background auto-lock grace period.
- A TOTP code is cleared on background and on a failed refresh; an expired code
  is never left on screen or copyable.
- Autofill defaults to verified-only; missing preference keys keep that default.
  "Exact" match mode drops text-search hits as well as same-site hits.
- OTA refuses non-HTTPS download URLs, re-verifies the APK hash immediately
  before install, deletes a file that fails re-verification, and warns before
  installing a local APK that Keyel cannot checksum.
- Biometric authorization does not survive backgrounding. Secure-screen flags
  are applied natively before the first frame on the main and autofill
  entrypoints.
- Regression tests cover attached-note masking, autofill default/strict
  filtering, background masking, TOTP clearing and OTA URL/reverify rules.

Resolution notes: reveal requests carry a generation token, so a Rust response
that lands after a lock/background/route change can never publish plaintext or
write to the clipboard. A shared `RouteObserver` masks the detail screen when an
editor (or any other route) is pushed on top, and `openEdit()` masks eagerly.
`EntryTotpCard` cancels background refreshes, drops a code at period rollover
and refuses to copy an expired code. Autofill stamps settings files with
`autofillPolicyVersion`, so legacy installs that persisted an explicit `false`
are migrated to verified-only on upgrade; a missing/corrupt settings file also
restores the fail-closed defaults. OTA re-checks the final URL after redirects
and re-hashes the APK immediately before handing it to the installer, after all
permission prompts. `tool/check_reveal_lifecycle.sh` enforces the native and
configuration parts of this contract in CI.

### Known constraints

- Wear OS keeps its standalone, opt-in model: no vault on the watch, no
  clipboard, no screenshots, no other credentials. The system-bound Wearable
  listener is a message handler, not an always-running foreground service.
  Audited and resolved: `WearMessageListenerService` is a GMS-bound
  `WearableListenerService` scoped to `wear://*/keyel/totp`, with no boot
  receiver, foreground-service type/permission or `startForeground` call.
  `tool/check_wear_isolation.sh` enforces this in CI.
- Rust crypto, vault format and unlock/onboarding flows are unchanged.

---

## 2. Responsive UI

**Goal:** the same codebase gives a polished phone UI, a real tablet UI and a
usable desktop UI, in both LTR and RTL, at up to 200 % text scale.

### Definition of done

- Button metrics no longer scale with window width; a 1600 dp window shows the
  same 15 dp labels as a 400 dp one.
- Shared primitives exist for page scaffolding, effective layout capacity,
  direction-aware helpers and adaptive modals, and the shell uses them.
- Adaptive side sheets have a bounded width, scrollable content and RTL-correct
  corners/slide direction.
- High-value screens (vault, security, settings, generator, import/export) use
  multi-column compositions when effective capacity allows, and collapse back
  to one column on phones or at high text scale.
- Physical `left`/`right` alignments, paddings and chevrons in user-facing
  screens are replaced with directional equivalents.
- Layout decisions use effective capacity (window width minus nav chrome and
  margins, adjusted for text scale), not a raw breakpoint.
- Tests cover 360/400/700/840/1000/1200/1600 dp, 1.0/1.4/2.0 text scale,
  LTR/RTL and EN/FR on representative surfaces.

### Deferred, not forgotten

Route-driven vault master/detail (URL as the source of truth for the selected
entry, deep links, resizable panes) needs a router restructuring and is tracked
for a later phase. The 1.10 `KeyelSubShell` decision stays in place for this
release; wide screens get real content columns without changing navigation.

---

## 3. Codebase simplification

**Goal:** delete code that does nothing, remove settings that lie, and make hot
paths reactive without changing behavior.

### Definition of done

- Verified-dead Dart declarations and their barrel exports are removed:
  `BuildContextExtension`, `KeyelActionButtonGroup`, unused theme/haptic/app
  helpers, unused vault-entry samples and low-level passkey wrappers.
- Unused ARB keys are removed from both locales while EN/FR parity and
  placeholder checks stay green.
- The non-functional "offline vault" switch is removed from Settings.
- Settings radio dialogs and duration formatters are consolidated; OTA settings
  watch only the state they render.
- Primary-secret copying has one implementation and one tested precedence.
- Destructive vault deletion and preferences loading do not do synchronous file
  I/O on the UI path.
- `AppPreferences` reads on hot widget paths are mirrored by reactive providers,
  following the `securitySettingsProvider` pattern from 1.10.2.

Resolution notes: primary-secret copying now uses one `PrimarySecretCopy`
resolver with an explicit **password/card-number-first, username-fallback**
precedence (the row button and the swipe action previously disagreed); notes
and passkeys have no primary secret and still open their detail screen. Settings
dialogs share one radio primitive and one set of duration/byte formatters. OTA
progress no longer rebuilds the global banner or settings tree file-by-file.
Preference loading and vault deletion use async file I/O with the fail-closed
defaults and lock-in-`finally` guarantees intact. `autofillSettingsProvider`
mirrors the four autofill preferences for Settings; the fail-closed picker keeps
reading the singleton fresh on each async load. `uiSettingsProvider` mirrors
recent searches and the motion preference for build-time reads. All three
entrypoint apps now derive theme/locale from the reactive
`appearanceProvider`/`localeProvider`.

---

## Verification and sequencing

1. Land security fixes first, each with a focused regression test.
2. Land responsive primitives and the width-scaling fix together; they are the
   largest visible improvement and the lowest behavioral risk.
3. Land codebase deletions and consolidations; run the full suite after each
   batch because dead-code removals can hide live references.
4. Finish with the matrix tests, docs and version bump.

Full local gate, using the CI-pinned Flutter 3.47.9 (not the newer local 3.50.1):

- `dart format --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `cargo fmt --all --check`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test --workspace`
- `./tool/check_no_secret_logs.sh`, `./tool/check_wear_isolation.sh`,
  `./tool/check_reveal_lifecycle.sh`
- `flutter gen-l10n` and `flutter_rust_bridge_codegen generate` idempotency
- Android debug APK, Linux debug bundle, Wear Gradle unit tests and release APK
- `./tool/check_ci.sh --frb`

Only after all of the above is green does the version/changelog bump happen,
followed by a PR, CI monitoring and the automated release workflow.
