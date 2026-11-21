# Keyel Roadmap: 1.10.0 — localization, autofill completeness and quick access

This phase turns three deferred ideas into shipped behaviour:

1. **Localization** for English and French, with the RTL layout work that makes a
   future Arabic locale safe to add. Arabic translation itself stays deferred.
2. **Autofill completeness** — the three items carried past 0.10: a persisted
   "Never for this site" list, inline suggestions on Android 11+, and Digital
   Asset Links verification.
3. **Android quick access** — a generator launcher shortcut and a small
   home-screen widget, mirroring the lock shortcut and tile shipped in 1.9.0.
4. **Wear OS TOTP companion** — an opt-in, standalone watch app that shows
   one-time codes the user explicitly pushes from an unlocked phone. It holds
   no vault, no password and no other credential.

No vault schema change, no Keyel account/server, and no weakening of lock,
unlock, clipboard, screenshot or OTA guarantees. Keyel stays offline by default:
nothing in this phase adds a background service, a broad permission, or a
network call on the normal path.

Release stays CI-driven: bump `pubspec.yaml`, add a `CHANGELOG.md` section,
merge to `main`, and let the workflow cut `v1.10.0`. **Never push tags by hand.**
Beta remains a manual `workflow_dispatch` prerelease.

**Rules for this phase**

- Every user-facing string added or changed during this phase goes into the
  template ARB with a description. English is the template; French is a complete
  translation of that template. Debug screens stay out of scope.
- Locale selection never changes crypto, storage or matching behaviour. The
  Rust matcher and all secret handling stay language- and locale-independent.
- Autofill matching stays fail-closed. A deny-list, inline suggestion or asset
  link can only *narrow* the set of credentials offered; none may widen it or
  bypass the unlock/auth step.
- The widget and the new shortcut use the existing launch-action/lock-request
  plumbing. No native "locked" flag, no widget-side vault access, no plaintext
  secrets in a RemoteViews tree, and no always-running service.
- Every new or changed widget must be readable at 200 % text scale and respect
  reduced motion. RTL layout correctness is verified without shipping Arabic.
- Full verification (Dart format/analyze/test, Rust fmt/clippy/test, secret-log
  guard, FRB idempotency, Android and Linux debug builds) must be green before
  the version and changelog bump.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 1.10.0 | EN/FR localization + RTL layout | — | ☑ |
| 1.10.0 | Autofill completeness | — | ☑ |
| 1.10.0 | Generator shortcut + home-screen widget | — | ☑ |
| 1.10.0 | Wear OS TOTP companion | — | ☑ |

Legend: ☐ todo · ◐ in progress · ☑ done

**Status note:** all four phases are implemented and green under the full
verification list, executed with the CI-pinned Flutter 3.47.9 (not just the
newer local 3.50.1). French README/store copy remains an explicit carve-out;
on-device watch smoke needs physical hardware. See the sections below.

---

## 1.10.0 — English and French localization

**Goal:** a user can read Keyel in French, switch language at runtime, and the
layout remains correct when the locale is right-to-left even though Arabic is
not yet translated.

### Definition of done

- ARB template + French translation are checked in and generated classes are
  reproducible with a documented command; CI's analyze/test jobs do not depend
  on a local generation step the workflow does not run.
- A **Language** setting offers System / English / Français and takes effect
  without a restart. `MaterialApp` receives the resolved locale and delegates.
- All user-facing copy in the main app (shell, vault, entry, generator,
  security, settings, OTA, autofill, passkeys, folders, trash, import/export,
  sync, onboarding/unlock) uses generated messages. Debug screens are exempt
  and documented.
- README FAQ and store description copy have French equivalents, or an
  explicit, documented carve-out where translations are not yet available.
- Widget tests assert English and French rendering on representative screens,
  plus no overflow at 200 % text scale and an RTL directionality smoke test.
- No crypto, vault format, secret-log, screenshot or clipboard behaviour is
  touched by the localization change.

### Coverage at this checkpoint

- 878 messages in each ARB (English template + complete French translation),
  with generated classes checked in and both CI jobs guarding regeneration.
- System / English / Français selector on Appearance, runtime locale switching
  for both widget and non-widget code, and `TextDirection.rtl` layout smoke at
  200 % text scale.
- All user-facing copy in the main app is migrated: shell/top bars, vault,
  entry create/detail/edit, generator, security dashboard, settings, OTA,
  autofill, passkeys, folders, trash, import/export, sync, onboarding/unlock
  and the new watch-codes screen. Android autofill/widget/watch strings also
  have `values-fr` variants.
- `test/localization_test.dart` fails on an EN/FR key mismatch and on ICU `#`
  placeholders (Flutter's `pluralLogic` needs `{count}`); analyze fails on any
  referenced-but-missing message getter.

Explicit carve-out: debug-only screens, brand/proper nouns, stable identifiers,
technical constants and example data stay literal. README FAQ and store
description copy remain English for this release. Arabic translation is still
deferred; RTL layout is tested without shipping an untranslated locale.

### Knowledge

- Existing settings rows (theme mode, clipboard timeout) are the pattern for a
  language choice; locale preference belongs with the other non-secret app
  preferences.
- 200 % scale and reduced-motion test helpers already exist in `test/`; reuse
  them rather than adding a parallel harness.
- The earlier deferral is recorded in `docs/DECISIONS.md` (2026-11-15) and
  `docs/roadmap.md` (0.11 item 11 / 0.12 status).

### Risks and mitigations

- **Generated-code drift / CI mismatch.** Mitigation: check in or deterministically
  generate localizations, and add a CI guard if generation is required.
- **Partial translation treated as complete.** Mitigation: generator reports
  untranslated messages, and a test or tool fails on a missing French message.
- **RTL regressions without an Arabic locale.** Mitigation: force
  `TextDirection.rtl` in a layout smoke test; fix directional padding/alignment
  rather than mirroring strings by hand.

---

## 1.10.0 — Autofill completeness

**Goal:** close the three gaps that kept roadmap 0.10 at "code complete,
on-device verification pending" rather than truly finished.

### Definition of done

- **Never for this site** is persisted across restarts, is suppressible from
  the picker/save flow, and prevents Keyel from offering credentials for that
  site. Stored data is non-secret (package/domain identifiers only).
- **Inline suggestions** on Android 11+ work within the platform's autofill
  contract, or are explicitly documented as unsupported with the reason and a
  tracked follow-up if the platform/IME surface makes a safe implementation
  impossible in this phase.
- **Digital Asset Links** handling is fail-closed: it can only reduce the set of
  offered credentials, never add a match, and it does not introduce a network
  call into the offline-by-default path. If real online verification is out of
  scope, the decision and the local strict-match substitute are documented in
  `docs/DECISIONS.md` and `docs/threat-model.md`.
- Tests cover each behaviour (native and/or Dart, as appropriate) and confirm
  the existing unlock/auth gate still applies.

### Risks and mitigations

- **A deny-list must not leak into logs or the diagnostics bundle.** Mitigation:
  keep domains only, reuse the existing redacted bundle rules.
- **Platform APIs that need a keyboard/IME integration.** Mitigation: verify the
  real Android contract before committing to an implementation; cut scope with
  a documented reason rather than shipping a fake.
- **No network permission by design.** Mitigation: any DAL work stays local and
  conservative; never silently fetch a remote statement from the app.

---

## 1.10.0 — Android quick access

**Goal:** reach the generator and the most common lock/open actions without
navigating the app, using the same safe plumbing as the 1.9.0 lock shortcut.

### Definition of done

- A **Generate password** launcher shortcut opens the generator route on cold
  and warm start, covered by the same action tests as the lock shortcut.
- A small **home-screen widget** offers quick actions only (no vault contents,
  no clipboard contents, no secrets in RemoteViews). It uses `PendingIntent`s
  to `MainActivity`, needs no background service and no new permission.
- Lock from either surface still wipes the clipboard natively and routes
  through `VaultSessionNotifier.lock()`. No native flag is authoritative.
- Android debug build and the existing manifest/resource checks are green.

### Risks and mitigations

- **Background launch restrictions.** Mitigation: all widget intents originate
  from a user tap and target `MainActivity`; no service-side `startActivity`.
- **Secrets in a widget.** Mitigation: RemoteViews shows static labels only;
  generated passwords are never rendered or stored by the widget.
- **PendingIntent mutability on Android 12+.** Mitigation: explicit
  `FLAG_IMMUTABLE` / update-current flags, tested by build and review.

---

## 1.10.0 — Wear OS TOTP companion

**Goal:** an opted-in watch can show TOTP codes without carrying the vault,
a password or a live link to the phone.

### Definition of done

- A small standalone `wear/` module with an RFC 6238 generator covered by the
  Appendix B vectors for SHA-1, SHA-256 and SHA-512, plus parameter validation.
- Seeds are pushed one at a time from an unlocked vault through a checked
  MethodChannel, over a paired-device channel; no paired watch means no send.
- The watch encrypts seeds at rest with a Keystore-backed master key, blocks
  screenshots, keeps no clipboard and masks codes whenever the app is paused.
- The phone can remove one seed or all seeds without unlocking the vault; no
  vault schema or backup setting is changed.
- Security notes and residual risks are recorded in `docs/threat-model.md`.

### Risks and mitigations

- **Seed copied off the phone.** Mitigation: an explicit per-entry action in an
  unlocked session, no background retry, and a native payload buffer that is
  zero-filled after the send. The watch is the only new owner of the seed.
- **Malicious peer on the wearable channel.** Mitigation: path- and size-bound
  messages, full validation before persistence, and no response carrying secret
  material.
- **Shoulder surfing on the watch.** Mitigation: `FLAG_SECURE`, masked-by-default
  codes, foreground-only UI and no clipboard write.

---

## Verification and sequencing

1. Localization infrastructure and settings first, then string migration,
   then autofill, then quick access, then the watch companion.
2. Run the full suite before the version bump: `dart format`, `flutter analyze`,
   `flutter test`, `cargo fmt --all --check`,
   `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test
   --workspace`, `./tool/check_no_secret_logs.sh`, FRB regeneration idempotency,
   and both Android and Linux debug builds. Watch unit tests run through Gradle.
3. Bump `pubspec.yaml` to `1.10.0+1` and add the `## [1.10.0]` changelog section
   last, then merge to `main` and monitor both CI workflows.

### Deferred, not forgotten

- Arabic translation and translated store assets (a natural 1.11.0 scope).
- On-device watch smoke (pairing, push, reveal, remove) needs physical hardware.
