# Changelog

All notable changes to Keyel are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-11-28

Major release focused on reliable sync merging and dependable same-Wi-Fi device
discovery. **No vault schema change.** Offline/fail-closed security, unlock and
reveal-generation guards, EN/FR parity, RTL and 200% text-scale collapse remain
green. Discovery is still a convenience only; `KYSYNC1-…` remains the sole trust
root and manual pairing always works.

### Fixed

- Paired devices now refresh every vault view immediately after `Sync now`, so
  logins merged from the shared folder appear without locking the app or
  restarting. A regression test covers two paired vaults merging distinct login
  bodies and both passwords.
- A stale disabled sync configuration no longer blocks Create group/Join group.
  Replacing it now zeroizes the old sync key first; an active group is still
  refused.
- Same-Wi-Fi discovery no longer depends on two devices scanning in the same
  narrow window. An unlocked device sends a small, bounded, secret-free beacon
  every two seconds; pressing Find nearby only has to listen. The beacon uses an
  outbound-only ephemeral socket, so no listening/server entitlement is needed.
- Discovery accepts normal private LAN ranges beyond an inferred `/24` (for
  example `10.0.0.0/8` and `172.16.0.0/12`), repeats its probe during a scan, and
  still rejects public, loopback, oversize and pairing-code-shaped datagrams.
  Nothing in discovery carries `sync_id`, `sync_key`, a pairing code or vault
  data.
- Presence stops when the vault locks or the app backgrounds, keeping discovery
  foreground-only and aligned with the unlock guard.

### Changed

- The sync screen explains that pairing creates the encryption group but does
  not transfer data: both devices must use the same synced folder and tap
  `Sync now` on each one.
- Preserving a self blob's highest sequence across restores remains explicit;
  a restored vault cannot republish an older blob under a reused sequence.

## [1.14.0] - 2026-11-26

Feature release focused on desktop responsiveness, especially the first-run
onboarding flow. **No vault schema change.** Offline/fail-closed security,
unlock and reveal-generation guards, EN/FR parity, RTL and 200% text-scale
collapse remain green.

### Fixed

- The global OTA banner no longer crashes the app with `No Overlay widget
  found.` on Linux desktop. It lives in `MaterialApp.builder`, above the
  Navigator's Overlay, so its dismiss action now uses semantics instead of a
  `Tooltip`/`OverlayPortal`.
- Onboarding, unlock, create-vault and recovery-key forms are centered again
  on wide desktop windows. Their width cap and centering now live inside the
  vertical scroll view instead of being defeated by its tight width constraints;
  RTL mirrors correctly instead of pinning the form to the physical left edge.
- Focused forms use responsive page margins and a text-scale-aware width cap:
  560 dp at 1x, growing with the text scaler so 200% text keeps the same line
  length. Welcome and finish steps still center vertically; longer steps stay
  top-aligned and scroll instead of clipping.
- Strength feedback and entropy text wrap instead of being ellipsized at 200%
  text scale, and the create-vault button uses the shared adaptive button so
  its label cannot be squeezed by a fixed 50 dp height.

### Added

- Desktop regression coverage pumps the real onboarding, unlock, create-vault
  and recovery screens at 1600 dp in LTR and RTL, at 200% text scale and on a
  400 dp phone, asserting the capped column is horizontally centered and free
  of overflow.

## [1.13.1] - 2026-11-26

Patch release: desktop builds now target the original x86-64 baseline, vault
storage creation is hardened, and sync room creation gains LocalSend-style
same-Wi-Fi discovery while keeping the one-time pairing code as the trust root.
**No vault schema change.**

### Fixed

- Linux release builds no longer emit ELF notes requiring `x86-64-v2`/`v3`,
  which made glibc reject the app with `CPU ISA level is lower than required` on
  older CPUs. The baseline is pinned in CMake and the Rust target flags, and
  every release artifact is checked before upload. Release CI also discards
  Rust artifacts cached before those flags were pinned and normalizes any
  runner-injected ISA note, so the published bundles are genuinely portable.
- Synced vaults whose main file is missing but whose `vault.keyel.bak` is intact
  are now detected as existing: onboarding no longer offers to overwrite them,
  unlock/recovery accept the backup path, and factory reset removes both.
- New vault and backup files are created with `0600` permissions on Unix even
  under a permissive umask; older vault backups are tightened on write.
- One-time recovery keys remain visible if optional biometric setup fails.
- Legacy vault migration picks the newest candidate, writes via temp+rename,
  and carries `settings.json` forward.
- `settings.json` writes are serialized and atomic, so concurrent fire-and-
  forget saves cannot truncate fail-closed preferences.

### Added

- Sync room creation checks the local network using the same LocalSend-style
  discovery approach and shows nearby Keyel devices before the existing
  manual pairing code flow. Same-Wi-Fi presence is a convenience, not
  authentication: the code remains a bearer secret and is always required to
  join. If discovery is unavailable, manual code entry still works.

## [1.13.0] - 2026-11-25

Feature release: the quick-actions palette is now a keyboard-first, fuzzy-ranked
command palette. **No vault schema change.** Ranking sees only secret-free
summaries, and EN/FR parity, RTL, 200% text scale and the offline/fail-closed
security contract remain intact.

### Added

- Fuzzy ranking over entry titles and subtitles: matching is case- and
  accent-insensitive and token-based, exact/prefix hits outrank mid-word hits,
  and loose subsequences still find entries. Favourites and recently opened
  entries break equal-score ties. With an empty query the six static actions
  keep their 1.12.0 order above the entry results.
- Keyboard navigation in the palette: `↑`/`↓` move and scroll the selected row
  into view, `Enter` runs it, and `Esc` / `Ctrl/Cmd+K` still close it. The
  selection is exposed to platform semantics and works without a pointer.
- Recency persistence: the last eight entry ids opened from the palette are
  kept in `settings.json` as opaque, non-secret UI preferences, with corrupt
  values rejected without affecting any fail-closed default.
- EN/FR keyboard-help copy and regression tests for ranking, keyboard nav,
  recency, RTL and 200% text scale.

## [1.12.0] - 2026-11-24

Feature release: the vault selection lives in the URL, master/detail panes are
resizable, and one quick-actions palette works on phone and desktop. **No vault
schema change.** EN/FR parity, RTL, 200% text scale and the offline/fail-closed
security contract remain intact.

### Added

- `/vault/entry/:id` is now a canonical, shareable route. Cold deep links and
  the legacy `/entry/:id` form open the requested entry; locked deep links are
  preserved through the unlock guard. Compact windows show a full-screen detail
  page, wide windows show master/detail, and closing the detail returns to
  `/vault` without leaving the tab.
- Resizable master/detail panes on wide windows. The divider is keyboard
  reachable, clamped to 28–50% with a 320 dp floor, persisted in
  `AppPreferences`, mirrored in RTL, and ignored when two panes no longer fit
  (including at 200% text scale).
- Quick actions: a searchable palette of six static actions (open entry, new
  entry, lock now, generator, settings, updates) plus secret-free entry results.
  Open it from the vault top bar on mobile or with `Ctrl/Cmd+K` on desktop; a
  second shortcut press or `Escape` closes it. Entry results navigate through
  the canonical route so the URL and selection stay in sync.

### Fixed

- Legacy settings files without the 1.11 autofill policy stamp now correctly
  force the fail-closed verified-only default instead of honouring the old
  explicit `false`.
- The note-card reveal button no longer requests infinite width inside its
  heading row.
- TOTP rollover tests use an injectable clock so period boundaries are
  deterministic; an HTTPS download redirected to HTTP is drained and rejected
  without a stream-cast error.

## [1.11.0] - 2026-11-21

Major maintenance release: security hardening, real multi-window layouts and
codebase simplification. **No vault schema change.** EN/FR only — Arabic stays
out of scope — with RTL layout and 200% text-scale correctness preserved. The
offline/fail-closed contract, clipboard wipe, screenshot blocking, passkey
flows and OTA checksum verification are unchanged or strengthened.

### Security

- Secrets are masked by default and re-masked when the app backgrounds or
  locks, including when an editor is pushed on top and when a decryption that
  started before the lock finishes afterwards. TOTP codes clear on
  failure/background, are dropped at period rollover and can never be copied
  after expiry; attached notes use the same gated reveal path as secure-note
  bodies.
- Autofill fails closed: `autofillVerifiedOnly` defaults to `true`, and legacy
  settings files are migrated to that default on upgrade because 1.10.2 wrote
  an explicit `false` even when the user never changed the setting. Missing or
  corrupt settings also restore the fail-closed defaults. Exact/strict mode
  drops text-search hits instead of silently widening matches. "Never for this
  site" persists.
- OTA downloads require HTTPS plus a valid SHA-256, including after redirects,
  and are re-verified immediately before install; a tampered file is deleted.
  Local APK installs require an explicit unverified warning confirmation.
- `FLAG_SECURE` is applied natively before the first frame on every entrypoint,
  and biometric prompts no longer survive backgrounding.
- Rust lock events now fan out to every live subscriber, so all open sessions
  observe a lock rather than only the first listener.
- Wear OS is audited and enforced in CI: the watch listener is a GMS-bound,
  path-scoped message handler — no boot receiver, foreground service,
  clipboard, screenshots, vault or other credentials on the watch
  (`tool/check_wear_isolation.sh`).

### Layout

- Button metrics use fixed dp values with bounded, text-scale-aware padding
  instead of scaling with window width.
- New shared primitives for effective layout capacity (window width minus nav
  chrome and margins, adjusted for text scale), direction-aware arrows/alignment
  and adaptive bottom/side sheets with RTL-correct corners and slide direction.
- Settings, security dashboard, import/export, generator and entry detail use
  real two-column compositions when effective capacity allows, collapsing to
  one column on phones or at 200% text scale.
- A responsive test matrix covers 360–2560 dp at 1.0/1.4/2.0 text scale in both
  LTR and RTL and in both English and French, and the screen-level tests exercise
  real two-column compositions inside the shell's effective-layout scope.

### Codebase

- Removed dead widgets/helpers, unused localization keys and the misleading
  "offline vault" setting; settings dialogs and formatters are consolidated.
- Primary-secret copying has one resolver with a documented password/card-number
  first, username-fallback precedence.
- Preference loading and vault deletion use async file I/O; hot `AppPreferences`
  reads on the settings, security, autofill and vault paths use reactive
  providers, and all three entrypoints derive theme/locale from them.

## [1.10.2] - 2026-11-21

Follow-up fixes to 1.10.0. No vault schema change and no weakening of the lock,
autofill, clipboard, screenshot or OTA guarantees.

### Fixed

- **Wear OS screen has a back arrow.** Settings → Wear OS now opens the page as
  a pushed sub-route with the shared top bar, so the back action returns to
  Settings instead of leaving the page without a title-bar control.
- **Security dashboard tracks auto-lock and clipboard changes.** Both values
  are now exposed through a reactive provider watched by Settings and the
  vault-posture card. Changing either one updates security health immediately
  instead of leaving the last built value on screen.

### Changed

- **Login entry detail polish.** Credential fields gained leading glyphs, a
  revealed password is subtly tinted, and the password-health card now sits
  directly below the credentials so strength feedback appears as soon as the
  secret is revealed. All copy, reveal and open actions are unchanged.

## [1.10.0] - 2026-11-21

English/French localization with RTL-ready layouts, the three autofill gaps
carried over from 0.10, and Android quick-access shortcuts. No vault schema
change, no new permission, and no weakening of the offline, lock or autofill
guarantees.

### Added

- **English/French localization.** System / English / Français can be chosen in
  Settings → Appearance and takes effect without a restart. The ARB template
  and its complete French translation are checked in with generated classes,
  and both CI jobs fail on stale regeneration. RTL layout correctness is
  smoke-tested at 200 % text scale even though Arabic translation is deferred.
  All user-facing screens are migrated; debug-only copy, brand names and
  technical identifiers stay literal. README/store copy remains English.
- **"Never for this site".** The autofill picker and save sheet can permanently
  decline a target. The choice is stored as a canonical, non-secret package or
  host key in app-private settings and is checked natively before any unlock
  prompt or save flow. Saved choices can be removed from Settings.
- **Verified sites only.** An opt-in autofill setting narrows suggestions to
  exact package/host matches — an offline substitute for Digital Asset Links
  that never fetches a network statement and can only reduce what is offered.
- **Android 11+ inline suggestions.** A static "Fill with Keyel" chip appears in
  compatible keyboards and reuses the existing authentication flow; no
  credential text is placed on the keyboard surface. Unsupported IMEs keep the
  normal dropdown.
- **Generator shortcut and widget.** Long-press the app icon for *Generate*, or
  add the *Keyel quick actions* home-screen widget (Open / Generate / Lock).
  These open existing screens; they never generate, copy or read a secret, and
  only lock wipes the clipboard. No background service or new permission.
- **Opt-in Wear OS TOTP companion.** A standalone watch app (separate APK)
  shows one-time codes for entries you explicitly send from an unlocked phone. It
  holds no vault, password or other credential, encrypts seeds at rest with a
  Keystore-backed key, blocks screenshots, never uses the clipboard, and masks
  codes when you leave the app. The phone can revoke one seed or all of them.
  Codes are generated on the watch, so no phone connection is needed to read
  them. A physically compromised unlocked watch remains a residual risk; see
  `docs/threat-model.md`.

### Changed

- The Android autofill dropdown label is localized, with French strings in
  `values-fr/strings.xml`.

### Security

- Autofill deny choices and verified-only matching only narrow the offered set;
  both keep the unlock/auth gate. No domain is logged or exported.
- Inline suggestions are unpinned and carry only static copy, so the
  authenticated dataset still replaces them.

## [1.9.0] - 2026-11-21

One-tap lock, a runnable Linux AppImage, and a consistency pass over everyday
screens. No vault schema change, no new Android permission, and no change to the
offline-by-default promise.

### Added

- **One-tap lock on Android.** Long-press the app icon for *Lock vault*, or add
  the *Lock Keyel* Quick Settings tile. Both wipe the clipboard natively and
  then take the existing lock path: the Rust session key is dropped, revealed
  secrets are hidden, and the app returns to the unlock screen. No new
  permission, broadcast receiver or background service is introduced.
- **Linux `.AppImage`.** Releases now include a single runnable
  `keyel-v1.9.0-linux-x64.AppImage` alongside the portable `.tar.gz`. It needs
  FUSE2 to double-click, or can be run with `--appimage-extract-and-run`. It is
  built in CI from the same bundle as the tarball and listed in `checksums.txt`.

### Changed

- **Consistent loading, empty and error states.** A single shared state message
  now backs the vault, item detail, folders, trash, autofill, passkeys, and the
  security dashboard. Failed loads keep an inline retry instead of briefly
  looking like an empty vault.
- **"Not found" is no longer an error.** A missing item gets its own screen; a
  failed read shows the underlying error with a retry. Back and Close controls
  on secondary screens now have clear labels, and *Software Update* uses the
  shared top bar.
- **Accessibility coverage extended.** New and changed screens are checked at
  200 % text scale and with reduced motion enabled.
- Roadmap and decision notes record the reserved 1.6.0 lock idea shipping as
  1.9.0 and the new release artifact.

### Fixed

- Starting a passkey ceremony for a different relying party no longer leaves
  matches from the previous site on screen.

### Security

- One-tap lock never writes a native "locked" flag: the Rust session stays the
  only source of truth, and unlocking still requires the master secret or
  biometrics with the existing throttle. Screenshot-blocking defaults,
  clipboard wipe and fail-closed OTA checksum verification are unchanged.

## [1.8.6] - 2026-11-20

A small Appearance cleanup. No vault, security or permission changes.

### Changed

- Removed the "Page / Card" dark-surface sample from the Pure black (AMOLED)
  setting on the Appearance screen. The AMOLED switch itself is unchanged; the
  live theme preview at the top of the screen still reflects the selection.

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
