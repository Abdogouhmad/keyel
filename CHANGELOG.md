# Changelog

All notable changes to Keyel are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.5] - 2026-11-20

Update notifications and a beta channel, plus three fixes to 1.8.2. No vault
schema change; one new opt-in Android permission (`POST_NOTIFICATIONS`).

### Added

- **Automatic update checks with notifications.** Keyel quietly checks the
  selected release channel when it opens, on resume, and while it is in the
  foreground (no background service). A new release raises an Android OS
  notification — once per version — and a dismissible banner at the top of the
  app that opens *Software Update*. Checks are throttled and persisted, can be
  turned off, and never upload vault data. Android 13+ asks for
  `POST_NOTIFICATIONS` once; declining still shows the in-app banner.
- **Stable and beta release channels.** *Software Update* lets you switch
  between the verified stable manifest and a separate beta manifest. Beta
  builds are manual GitHub prereleases with their own SHA-256-verified APK
  manifest, so opting in never changes what stable users receive.

### Changed

- **Clearer dark / light / system switcher.** The Appearance screen now uses
  self-explaining radio cards with a short description for each mode and a
  badge showing the current system brightness, instead of an unlabelled
  segmented control.

### Fixed

- **Black screenshots when protection was disabled.** The screenshot switch
  now reliably clears the native `FLAG_SECURE` when turned off, and re-applies
  it on every lock or background transition. Lock, unlock, autofill and passkey
  screens remain protected regardless of the switch; the autofill and passkey
  entrypoints set the flag natively before Flutter starts.
- **Spurious "copied an empty text" toast after clipboard wipe.** Wiping now
  uses Android's `clearPrimaryClip()` instead of copying an empty value, and
  empty fields no longer show a "copied" confirmation.
- Beta update detection no longer relies on a hash scraped from release notes;
  both channels use the same committed, checksum-verified manifest.

### Security

- Screenshot blocking still defaults to on and fails closed. Notification
  permission is opt-in, revocable in Android settings, and notification text
  contains only the version and channel — never vault contents.

## [1.8.2] - 2026-11-20

Three follow-ups to 1.8.0. No vault schema change and no new permission.

### Added

- **Screenshot protection switch** in Settings → Security & Access. Turning it
  off lets you capture in-app screens (for example to share a design). The
  preference is persisted and reported honestly on the security dashboard.
  Lock, unlock and first-run screens and the autofill/passkey entrypoints keep
  blocking screenshots regardless of the switch.
- **Live theme preview** on the Appearance screen, rendered with the selected
  palette and mode, plus a dark-surface sample that shows exactly what the
  AMOLED switch changes. Theme-mode captions now say what each option does.
- **Return path from "Review settings"**: the security dashboard switches to
  the Settings tab through the shell and Settings shows a labelled back arrow
  to Security for that entry.

### Security

- Screenshot blocking defaults to on and fails closed: a missing preference
  value keeps it enabled, and every lock restores it.

## [1.8.0] - 2026-11-20

A quality release: faster hot screens, stronger secret handling, and a more
informative security dashboard. No new permissions, account, vault schema
change, or change to the offline-by-default promise.

### Added

- **Vault posture card** on the security dashboard: four state-bearing seals
  (auto-lock, clipboard wipe, screenshot protection, breach opt-in) with
  semantics labels, a restrained staggered reveal, and a single *Review
  settings* action. Reads the same non-secret state as the features themselves.
- **Local help sheet** in Settings replaces the placeholder snackbar with
  accurate, offline topics on the security model, shortcuts and recovery.
- **Unsaved-changes guard** on the entry editor: leaving with edits asks for
  confirmation, and a successful save exits without prompting.

### Changed

- Hot surfaces now subscribe to individual session fields with `select`, so an
  unrelated session change no longer rebuilds static subtrees.
- Vault search is debounced by 200 ms, stale list loads are discarded, and
  selection pruning uses one visible-id `Set`.
- The AMOLED theme now applies the resolved black scheme to every component
  theme, not just the colour scheme.
- Keyboard `Ctrl/⌘+F` focuses vault search; the medium navigation rail no
  longer overflows its 76 dp width.
- The import/export sheets are split into focused libraries, and UI text
  scale / reduced-motion coverage is expanded across the new surfaces.

### Security

- Copied secrets are wiped on vault lock and on app backgrounding even when
  the timed clipboard wipe preference is "Never"; that preference now controls
  only the timed wipe while the app stays unlocked and foregrounded.
- Reveals auto-hide after 15 s everywhere, including card/CVV, notes and
  custom fields; `KeyelPasswordField` re-masks after 15 s and generation never
  auto-reveals.
- Autofill no longer falls through to web-domain matching when an app package
  is present but has no `androidapp://` match, closing a WebView spoofing path.
- OTA updates fail closed: a missing or malformed SHA-256 checksum means the
  release is not offered, downloaded or installed, and a failed verification
  deletes the partial download.
- Auto-lock is active in the autofill and passkey entrypoints as well as the
  main app; Android marks sensitive copies with `EXTRA_IS_SENSITIVE`.
- Secret DTOs now have redacted `Debug` implementations, and CI mechanically
  rejects unapproved `print`/`debugPrint`/Rust log calls.

### Tests

- Added coverage for clipboard lock/background wiping, autofill spoofing, OTA
  checksums, reveal hygiene, password-field re-masking, redacted DTOs, private
  CSV export, rebuild narrowing, posture-card states, the help sheet, search
  debounce/stale loads, and the editor's unsaved-changes guard.

## [1.7.0] - 2026-11-20

### Added

- **Opt-in password breach check.** A *Security Health* action checks saved
  login passwords against Have I Been Pwned. It is off by default, requires an
  explicit disclosure and opt-in, and only runs when you tap *Check now* with
  the vault unlocked. Results show entry titles and breach counts.
- **Local k-anonymity matching.** Rust computes SHA-1 and sends only the first
  five hex characters of the digest over HTTPS. Dart never sees a password or
  full hash; the range responses are compared in Rust.

### Security

- The opt-in flag is a non-secret preference; no hash, prefix, password or
  breach response is stored, logged, or added to diagnostics.
- Pending digests are `Zeroizing`, kept only in a bridge-local check, and wiped
  on completion, cancellation, error, and vault lock. The endpoint is
  hard-coded HTTPS and the prefix is validated before it becomes part of a URL.
- The threat model records the narrowed network promise and the residual
  k-anonymity metadata exposure (T15/A8).

### Tests

- Core SHA-1 known-answer, prefix/suffix and response-parser tests; Dart tests
  for the endpoint/client, opt-in disclosure, unlocked gating, error cleanup,
  and secret-free results.

## [1.5.0] - 2026-11-19

### Added

- **Opt-in cross-device sync (E2EE).** A new Sync settings page lets you enable
  or disable sync, choose a folder, pair a second device with a one-time code,
  see status/last-sync/device id, and run a manual foreground sync. No Keyel
  server or account: your own sync tool (Syncthing, Nextcloud, cloud drive, USB)
  moves the encrypted files. No new network permission is used.
- **Sync wire format and pairing.** Versioned `KYS1` blobs use XChaCha20-Poly1305
  under a random 256-bit sync key; the authenticated header binds sync id, writer
  device id and a monotonic sequence. Pairing uses a typo-detecting one-time code
  whose key is stored only inside each device's vault — never in Dart, logs or
  the backend.
- **Conflict-aware merge.** Per-item version vectors and tombstones produce
  deterministic merges with non-destructive, dated conflict copies (no silent
  overwrites), with idempotency and tamper/corruption fail-closed guarantees.
- **Schema v5.** Additive `sync_config`, per-item `sync_meta` and tombstones;
  v1–v4 vaults migrate forward losslessly. Sync setup survives encrypted backup.

### Security

- Sync key and pairing code follow the existing secret hygiene: `Zeroizing` in
  Rust, excluded from DTOs/summaries/search/diagnostics/logs, pairing code shown
  once with explicit acknowledgement and auto-clearing clipboard under
  `FLAG_SECURE`. Threat model extended with the untrusted-backend analysis.

### Tests

- New core/FRB/integration and Flutter widget tests for the envelope, pairing,
  version-vector merge (convergence and idempotency), corrupt/tampered remote
  abort, atomic folder I/O, and the sync settings flows.

## [1.4.3] - 2026-11-19

### Fixed

- **CI/release build** — resolved the analyzer and clippy failures that blocked
  the 1.4.x passkeys release: required named parameters now precede optional
  ones in the custom-fields editor, the PASSKEY RP lookup helpers no longer sit
  after the test module, and the base64url padding check uses the idiomatic
  integer API.
- **Dependency security** — upgraded the P-256/RustCrypto stack (`p256` 0.14,
  `crypto-bigint` 0.7.11) to clear RUSTSEC-2026-0387 without suppressing the
  advisory; private-key generation/signing semantics are unchanged.

## [1.4.2] - 2026-11-19

### Fixed

- **Passkey handler RP context parsing (Android)** — hardened RP ID extraction
  in the Credential Manager passkey handler to ignore blank values and avoid
  nullability issues when deriving request context for in-app unlock/selection.

## [1.4.1] - 2026-11-19

### Changed

- **Passkey provider candidate surfacing (Android)** — refined Credential
  Manager system-picker entries to be request/RP-contextual (for example
  showing the relying party for passkey save/use actions) and to reduce
  redundant actions when a direct passkey flow can be offered.
- **Ceremony handoff context** — provider-to-handler passkey requests now carry
  non-secret request/RP context so the in-app unlock/selection flow can present
  the correct relying-party context consistently.

### Security

- Candidate surfacing remains metadata-only and secret-free. Individual passkey
  account details stay inside the encrypted vault and are enumerated only after
  user authentication/unlock inside Keyel; no private key material or secrets are
  exposed to the provider process, system picker, logs, or diagnostics.

## [1.4.0] - 2026-11-19

### Added

- **Passkeys (WebAuthn / Credential Manager, Android)** — initial passkey
  support on supported devices (Android 14+/API 34 where the system provider
  capability is available). Keyel can be surfaced as a credential provider to
  create and use passkeys for relying parties.
- **Vault-stored passkey credentials** — new passkey entry type storing
  relying-party, user, credential, public-key, and (secret) private-key
  material encrypted at rest in the local vault. Passkey entries appear in the
  vault with secret-safe details and management actions.
- **In-Rust WebAuthn ceremonies** — ES256 (P-256) key generation, attestation
  (`fmt = "none"`), and assertion signing/response construction run inside the
  Rust/session boundary; private key material and signing never leave Rust or
  the encrypted vault and are never exposed to Dart/UI, diagnostics, or logs.
- **Passkey create & sign-in flows** — unlock-gated, explicit-confirmation UI to
  save a passkey or select/assert a matching passkey for a request, with
  relying-party/account context shown to the user.
- **Provider integration hooks** — Android Credential Manager provider
  service/handler wiring, capability detection, and settings access for the
  system credential provider configuration.

### Changed

- **Vault payload schema v4** — entries may now store passkey data (including
  signature counter and usage metadata). Existing v1–v3 vaults migrate in place
  on open (defaulting prior entries to no passkey body) and persist as v4;
  unknown/future schema versions remain rejected.
- **Search and matching** — passkey entries are matched by relying-party/user
  metadata for management and ceremony selection; private key material and other
  secrets remain excluded from search/indexing and summaries.
- **Import/export behavior** — encrypted backups round-trip passkey entries with
  the vault payload. Passkeys are not representable in Bitwarden/Chrome CSV and
  are therefore not included in CSV export to avoid leaking credential material.

### Security

- Passkey private keys and ceremony signing operations are confined to
  Rust/session boundaries and stored only inside the encrypted vault; only
  secret-free metadata is surfaced to UI/DTOs.
- Create/get ceremonies are request-driven with relying-party context and
  explicit user intent (unlock/confirmation/selection) before credential use;
  provider paths fail closed on malformed or unsupported requests.
- Signature counters and last-used timestamps are updated on successful
  assertions and persisted with the vault.

### Notes

- Passkey provider support depends on device/OS capabilities and configuration;
  on unsupported devices Keyel reports the limitation gracefully.
- This release provides a functional initial ceremony flow; broader
  app/browser/device compatibility may be refined in follow-up updates based on
  real-device behavior.

## [1.3.0] - 2026-11-19

### Added

- **Custom fields for entries** — add ordered extra fields to any login, card,
  or secure note. Each field has a label, value, and type (`text`, `hidden`, or
  `url`) and can be added, removed, or reordered in the editor.
- **Secret-safe custom-field handling** — hidden custom-field values are treated
  as secrets: masked in entry details, revealed/copied only on demand (with
  auto-hide), excluded from search/indexing, diagnostics, and logs, and wiped
  from memory alongside other secrets.
- **Custom-field import/export** — CSV export includes custom fields in a
  Bitwarden-compatible `fields` column; Bitwarden-style custom fields are mapped
  into typed fields on import while preserving backward compatibility for legacy
  field text. Encrypted backups round-trip custom fields with the vault payload.

### Changed

- **Vault payload schema v3** — entries now store ordered `custom_fields`.
  Existing v1/v2 vaults migrate in place on open (defaulting to no custom
  fields) and persist as v3; unknown/future schema versions remain rejected.
- **Search** — custom-field labels and non-secret (`text`/`url`) values are
  searchable; hidden custom-field values are never matched.

### Security

- Hidden custom-field secrets are never exposed in summaries or detail DTOs and
  are only retrievable through an explicit reveal path for the requested field.

## [1.2.0] - 2026-11-18

### Added

- **Appearance settings** — a dedicated Appearance screen in Settings with
  selectable color palettes, a pure-black AMOLED option for dark mode, and
  toggles for in-app animations and haptic feedback.
- **Theme controls** — choose system, light, or dark appearance and pick from
  multiple accent palettes while keeping security/status colors consistent.

### Changed

- **Project structure** — reorganized and cleaned the Flutter codebase into a
  leaner, more consistent layout with slimmer feature screens and extracted
  widgets.
- **Settings organization** — settings are split into focused sub-screens and
  reusable components for easier maintenance and a clearer UI.
- **Performance and polish** — reduced unnecessary UI work, respected
  animation/haptic preferences across interactions, and tightened diagnostics to
  include only non-secret preference data.

### Security

- **Preference hardening** — appearance and interaction preferences are stored
  locally as non-secret settings and kept out of sensitive diagnostic flows.

## [1.1.2] - 2026-11-17

Identity update: the application id is now project-owned
(`com.freesoftware.keyel`) instead of carrying a personal handle, and the README
is a proper product page.

### Changed

- **New application id `com.freesoftware.keyel`** (was `dev.agouhmad.keyel`) on
  every platform — the Android `namespace`/`applicationId` (with the Kotlin
  sources moved to `com/freesoftware/keyel/`), the Linux `APPLICATION_ID`, the
  macOS bundle identifier, and the Windows/macOS publisher metadata.
- **README** rewritten as a product page: hero icon, platform install table,
  grouped feature list, security summary and FAQ.

### Notes

- **Android installs do not upgrade in place across this change.** Android keys
  an app by its application id, so `com.freesoftware.keyel` installs as a
  separate app next to an existing `dev.agouhmad.keyel` build; the old app and
  its vault are left untouched. Uninstall the old one once the new one is set up.
- The macOS app is ad-hoc signed, so Gatekeeper warns on first launch.

## [1.1.1] - 2026-11-17

Installer release: Windows now ships a real `.exe` installer and macOS ships a
`.dmg`, so every desktop platform has a native way to install Keyel instead of
only a zipped bundle.

### Added

- **Windows installer (`.exe`)** — `keyel-v<version>-windows-x64-setup.exe` is a
  standard double-click installer built with Inno Setup. It installs per user
  (no administrator prompt), adds Start-menu entries and an optional desktop
  shortcut, registers an uninstaller in *Apps & features*, and can launch Keyel
  when it finishes. The portable `.zip` is still published for people who prefer
  not to install.
- **macOS disk image (`.dmg`)** — `keyel-v<version>-macos-universal.dmg` opens as
  a normal drag-to-*Applications* volume. The `.app` `.zip` remains available as
  well.

### Changed

- **Desktop artifact names are explicit about their contents.** The macOS build
  is a universal `x86_64` + `arm64` binary, so its assets are named
  `…-macos-universal` rather than `…-macos-arm64`.

### Notes

- The macOS app is ad-hoc signed (no Developer ID certificate), so Gatekeeper
  warns the first time it is opened; use *Open* from the right-click menu (or
  *System Settings → Privacy & Security → Open Anyway*) once.
- The installers are built and verified in CI; they have not been run on a
  physical Windows or macOS machine from this environment.

## [1.1.0] - 2026-11-17

Desktop release: Keyel now runs on Windows, macOS and Linux alongside Android,
with a built-in over-the-air updater and a custom entry-icon picker.

### Added

- **Over-the-air updates (Android)** — *Settings → Software update* checks a
  release channel (stable or beta) for a newer build, downloads the APK with a
  progress indicator, verifies its SHA-256 checksum against the published
  manifest, and hands it to the system package installer. An update can also be
  installed from a local APK file.
- **Custom entry icons** — a searchable icon picker with nine categories
  (brands, tech, finance, work, security, media, social, crypto, life) and 188
  icons. A chosen icon is stored with the entry and shown in lists and detail
  views; the picker also suggests icons from the entry title or URL.
- **Windows and macOS desktop targets** — real `windows/` and `macos/` builds
  next to the existing `linux/` target, all sharing the adaptive UI. Desktop
  windows open at a sensible size, enforce a phone-sized minimum, and carry the
  "Keyel" app name and title.

### Changed

- **The vault payload format is now schema v2.** Entries gained an optional
  `icon` field. Existing v1 vaults are migrated in place on unlock (a no-op for
  vaults without icons); the on-disk file format is unchanged, so the frozen v1
  fixture still pins the bytes.
- **Release builds now request the `INTERNET` permission.** This is required for
  the update checker and downloader and reverses the previous "offline only"
  posture. The app still sends nothing except update checks to the configured
  release source; no vault data ever leaves the device. `build.sh` no longer
  fails a release that has `INTERNET`.

### Notes

- The desktop targets and the update installer are code-complete and covered by
  tests, but have not been verified on a Windows or macOS machine or on a
  physical Android device from this environment.
- English-only. Localization (EN/FR/AR with RTL) is still deferred.

## [1.0.0] - 2026-11-16

First stable release: an offline-first, privacy-first password manager for
Android, with a pure Rust crypto core and a Flutter UI.

### Added

- **Encrypted vault** — a single `vault.keyel` file in the app's private
  storage, protected by an Argon2id-derived key and authenticated encryption.
  Cloud and device backups are excluded for the vault file.
- **Entries** — logins, payment cards and secure notes, organised with folders
  and favourites, with search and a soft-delete trash that can restore or
  permanently erase.
- **Password generator** — passwords and passphrases with configurable rules
  and a live strength meter.
- **TOTP (2FA)** — store and display time-based one-time codes.
- **Security dashboard** — a vault health score with weak, reused, old and
  insecure-URL findings, plus missing-2FA detection.
- **Import / export** — Bitwarden and generic CSV import, encrypted backup and
  restore, and a plain (unencrypted) CSV export.
- **Unlock options** — master password and optional biometric quick unlock,
  with a recovery key that can reset a forgotten master password.
- **Auto-lock** when the app leaves the foreground, and automatic clipboard
  clearing of copied secrets after a configurable timeout.
- **Android autofill** — the autofill service integration and its credential
  picker.
- **Adaptive UI** for phone, foldable, tablet and desktop windows, with a
  high-contrast theme, reduced-motion support and TalkBack labels.
- **Report a problem** — a redacted diagnostics file (app version, platform and
  non-secret settings) shared manually; it never includes vault contents,
  entry titles, passwords or key material.

### Security

- No `INTERNET` permission in release builds; data leaves the device only on an
  explicit export or share.
- All crypto and storage live in the Rust core (`crates/keyel_core`); secrets
  are zeroized and Dart only ever receives what the user explicitly reveals.
- The v1 vault file layout is frozen behind a byte-exact test fixture, so a
  format change that would strand existing vaults fails CI before it ships.

### Notes

- English-only. Localization (EN/FR/AR with RTL) is planned for a later
  release.
