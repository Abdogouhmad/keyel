# Keyel — Decision Log

Requests to change/interpret the plan, design or roadmap are recorded here
(date, decision, reason). Priority when documents conflict: roadmap > plan >
design (docs/roadmap.md header).

## 2026-11-15

- **Accessibility is implemented in the theme layer, not per screen.** High
  contrast is a `ThemeData` transform (`KeyelTheme.highContrast`) installed once
  in `MaterialApp.builder` (`KeyelTheme.highContrastBuilder`), and reduce motion
  is a single helper (`KeyelMotion.resolve`) called at each animated site. Keyel
  never derives its palette from the wallpaper, so there is no platform
  high-contrast *scheme* to adopt; instead the low-emphasis roles that carry
  text and boundaries (`onSurfaceVariant`, `outline`, `outlineVariant`) are
  promoted to full-contrast values and the hairline borders become solid rules.
  This keeps the change reviewable and testable in one place
  (`test/accessibility_test.dart`) rather than scattered across screens.

- **Reduce motion snaps, it does not merely shorten.** When
  `MediaQuery.disableAnimationsOf` is true, `PressableScale` skips the pressed
  scale entirely instead of animating it quickly, and every `AnimatedContainer`
  / `AnimatedSwitcher` duration collapses to zero. Motion is decoration, never
  information, so nothing is lost when it is removed.

- **TalkBack labels come from `tooltip` on icon-only buttons.** Material's
  `IconButton` announces its `tooltip` as the button label; the password reveal
  toggles in onboarding, create-vault, recovery-reset and unlock were the only
  icon buttons without one and now match the rest of the design system.

- **Large text scales reflow grids instead of clipping them.** The
  vulnerability-summary tiles used a fixed `childAspectRatio`, so at 200 % text
  scale the `IssueCard` column overflowed its tile. The grid now grows its row
  extent with `MediaQuery.textScalerOf` and relaxes to a single column past
  1.4×; `VaultRow` likewise grows its height with the text scale. This is the
  general pattern to follow for any fixed-height tile in the vault screens. The
  entry detail and edit screens are scrollable, so they reflow rather than clip.

- **Phase 0.11 is closed with two conscious carry-overs.** (1) Localization
  (EN/FR/AR + RTL, roadmap 0.11 item 11) is **not** being done at this time, at
  the user's explicit request; it is recorded here and in the checklist rather
  than silently dropped. (2) The on-device checks — storage dump, `logcat`
  sweep, release-APK functional test, TalkBack sweep, scroll-fps and cold-unlock
  timing — cannot be run in this environment and stay marked **device-pending**.
  Per the roadmap legend, a phase whose code is complete but whose on-device
  verification is pending closes at `◐` with tag `v0.11.0`, exactly as 0.10 did.
  Phase 0.12 (Beta) starts on a new branch, `phase/0.12-beta`.

## 2026-11-14

- **Phase 0.11 (Hardening and accessibility) is scoped to security hardening
  first.** The user chose the security slice explicitly. Accessibility,
  localization (EN/FR/AR + RTL) and the 5,000-entry performance benchmark are
  deferred to later commits in the phase. The roadmap 0.11 row and section now
  carry a `Status (2026-11-14)` block; the item-by-item truth lives in
  `docs/hardening-checklist.md`.

- **R8/minify is already on; we did not set `isMinifyEnabled` by hand.**
  Flutter's Gradle plugin (`FlutterPluginUtils.shouldShrinkResources`) enables
  `isMinifyEnabled` and `isShrinkResources` for release and adds
  `proguard-android-optimize.txt`, the Flutter embedding rules and
  `proguard-rules.pro`. Setting `isMinifyEnabled = true` in `build.gradle.kts`
  would turn R8 on *without* Flutter's rule files (the plugin only adds them
  inside that branch), so instead we left the flag to Flutter, documented it,
  and added `android/app/proguard-rules.pro` to pin the autofill components and
  the native-method surface. Verified by the release build's R8 `mapping.txt`.

- **`cargo audit` and `cargo deny` run in a dedicated CI `security` job** using
  prebuilt binaries (`taiki-e/install-action`) so PRs stay fast. The vault
  parser fuzzes nightly for one hour in a separate `fuzz.yml` workflow rather
  than on every PR, because a useful fuzz run is far longer than a PR check.

- **Bridge password arguments are wiped with `Zeroizing`.** `create_vault`,
  `unlock_with_master`, `unlock_with_recovery`, `verify_master`,
  `reset_master_with_recovery`, `change_master`, `export_backup` and
  `import_backup` now wrap the owned secret `String` so the Rust heap buffer is
  cleared on return. `EntryDraft` DTO secrets are *not* wrapped: adding `Drop`
  to the DTO would forbid moving fields out of it, and the exposure is a single
  bridge call. This residual risk is recorded in `docs/threat-model.md` (T4).

- **The Rust toolchain is pinned to 1.97.0 (`rust-toolchain.toml`).** An
  earlier note in this same entry deferred the pin because rustup would fetch a
  second toolchain on every machine. That cost is now accepted, deliberately:
  the compiler is pinned so a local `cargo build`/`cargo test` and CI agree
  exactly (plan §11 item 9). CI installs the matching
  `dtolnay/rust-toolchain@1.97.0` ref in every job that needs Rust, and
  `Cargo.lock` continues to cover dependency reproducibility. The fuzz crate
  overrides the pin with an unpinned nightly
  (`crates/keyel_core/fuzz/rust-toolchain.toml`) because `cargo fuzz` requires
  nightly and fuzzing wants a recent compiler; the fuzz workflow also sets
  `RUSTUP_TOOLCHAIN=nightly` so the root pin cannot leak into the cache step.
  Bumping the pin means editing the channel and the CI refs together.

- **`docs/threat-model.md` and `docs/hardening-checklist.md` added.** The threat
  model names each mitigation's code and each open item; the checklist maps the
  plan §11 and roadmap 0.11 items to done / partial / open / device-pending.

- **Wrong-attempt delay is a pure-Dart exponential throttle, never a wipe.**
  Plan §11 item 4 asks for an exponential delay on repeated wrong master
  passwords. `UnlockThrottle` (`lib/core/security/unlock_throttle.dart`) allows
  three free attempts, then doubles from 1s and caps at 30s. It is deliberately
  a plain Dart class with an injectable "now", not a Rust or platform feature,
  so the schedule is unit-testable without a device or clock mocking. State is
  persisted as `unlockFailures`/`unlockLockedUntilMs` in `settings.json` (both
  non-secret) so closing the app does not reset the clock, and the throttle is
  enforced inside `VaultSessionNotifier.unlockWithMaster`, which covers the
  biometric path too because it re-opens with the stored master. We never wipe
  the vault: a destructive response punishes the legitimate owner and rewards a
  thief who wants deniability, and the recovery key already covers a real
  lockout. Argon2id remains the primary per-guess cost.

- **The clipboard-clear timeout is a user setting, stored as an integer
  number of seconds with `0` meaning never.** Plan §11 item 3 asks for
  15 s / 30 s / 1 min / never options. `SensitiveClipboard.copy` reads
  `AppPreferences.clipboardClearDelay` (a `Duration?`, `null` for never) rather
  than hard-coding 30 s, so every copy site honours the choice without passing
  it. `0`/`null` is used for "never" instead of a nullable JSON field because a
  nullable field cannot be distinguished from an absent one on load without a
  `containsKey` check; an integer sentinel keeps `load` simple and total.

- **The 5,000-entry performance work is a regression guard, not a
  micro-benchmark.** Roadmap item 12 asks for a 5,000-entry vault benchmark. The
  one real defect found was in the UI, not the core: `VaultEntryList` used
  `SliverList.list`, which builds every child eagerly, so a large vault inflated
  every row (and a gap) on first paint. It now uses `SliverList.builder`, and
  `test/vault_list_perf_test.dart` asserts that only a window of rows exists
  before and after a scroll. The Rust test
  (`five_thousand_entry_vault_stays_within_budget`) uses deliberately loose
  ceilings (seconds, not milliseconds) because a shared CI runner is slow and
  the goal is to catch an accidental O(n²) in save/open/search/filter, not to
  pin a number; it prints its timings so a human can watch the trend. True
  device budgets (scroll fps, cold unlock) still need a phone, so the checklist
  item stays device-pending.

## 2026-11-13

- **Phase 0.10 (Autofill) is implemented on
  `phase/0.8-0.9-generator-totp-security`.** Fill works in other apps and
  Chrome; saving a new login works; a look-alike domain mismatch is warned
  about rather than silently filled.
  - **Matching lives in Rust, not in a Kotlin `DomainMatcher`.** Roadmap item
    0.10.3 names a `DomainMatcher.kt`, but a second matcher in Kotlin would be
    a second source of truth for the most security-sensitive rule in the app.
    `keyel_core::autofill::find_matches` is authoritative and the Kotlin
    service only forwards the Android package / WebView `webDomain` it read
    from the `AssistStructure`. The stale `DomainMatcher` comments in the
    manifest and `autofill_service_config.xml` were removed, along with an
    unused `<queries>` VIEW-https entry nothing consumed.
  - **Matching is conservative on purpose.** Apps match on the exact Android
    package, stored as `androidapp://<package>` (Bitwarden convention) or as a
    bare package URL. Web matches only the same host (ignoring `www.` and
    case) or a subdomain relationship on a label boundary, so
    `login.example.com` matches `example.com` but `evil-paypal.com` and
    `paypal.com.evil.net` never match `paypal.com`. There is **no public
    suffix list yet**, so matching never collapses to an eTLD+1 guess; weaker
    text hits are surfaced only through the explicit search box and reported
    as `MatchQuality::Search` so the picker shows a mismatch banner.
  - **A separate Flutter entrypoint hosts the picker.** `mainAutofill`
    (`lib/main_autofill.dart`, `@pragma('vm:entry-point')`) is launched by
    `AuthActivity` in a dedicated translucent activity. It talks to Kotlin
    over `MethodChannel('keyel/autofill')` (`getAutofillArgs`,
    `returnCredentials`, `saveCompleted`, `cancel`). The picker fetches a
    password with `revealField` only after the user taps a row, and hands the
    credentials straight back to the service, which builds the autofill
    `Dataset`. Settings uses `MethodChannel('keyel/platform')`
    (`isAutofillEnabled`, `openAutofillSettings`).
  - **The save flow is owned by Keyel, not the framework.**
    `KeyelAutofillService.onSaveRequest` reads the submitted values via
    `FieldParser.extractSaveCredentials`, launches `AuthActivity` in save mode
    (`ACTION_SAVE`) with the captured username/password, and calls
    `SaveCallback.onSuccess()` because Keyel presents its own confirmation
    screen. `AutofillSaveScreen` writes the login through Rust `upsertEntry`
    only after the user taps **Save login**, keyed to `https://<domain>` or
    `androidapp://<package>` so future fills match. The `autofillAskToSave`
    preference is honoured before the screen is shown.
  - **Preferences:** `autofillAskToSave` (default on) and `autofillMatchMode`
    (`domain` default | `exact`) persist in `settings.json`. `exact` hides
    same-site (subdomain) results in the picker.
  - **Tests:** 11 Rust `autofill` unit tests (host parsing incl. IPv6/ports,
    www/case folding, subdomain boundary, look-alike rejection, package vs
    web separation, query ordering, trashed/non-login filtering); 12 new Dart
    widget tests drive the picker (exact/same-site/search, mismatch banner,
    strict mode, locked, empty, tap → `AutofillSelection`, search debounce)
    and the save screen (prefill, web/app URL, decline, empty-name guard) with
    fake repositories.
  - **Deferred from 0.10:** inline keyboard suggestions (Android 11+),
    Digital Asset Links verification, a persisted "Never for this site" list,
    the picker's "Create new login" action (currently dismisses autofill; it
    should deep-link into the main app's new-entry screen), and the manual
    device test matrix (Chrome + 3 native apps + WebView + split screen).
    These need a physical device and are tracked in the roadmap tracker.
- **Release APKs no longer depend on a freshly regenerated plugin
  registrant.** Since Flutter 3.32, dev-dependency plugins such as
  `integration_test` are excluded from release builds, but the shared
  `GeneratedPluginRegistrant.java` is only rewritten for release mode when the
  Flutter tool's pre-generation step runs. That step is skipped for `--no-pub`
  and for IDE/direct Gradle builds, so a registrant left over from a debug
  build referenced `integration_test` while Gradle omitted it from the release
  classpath, failing `:app:compileReleaseJavaWithJavac`. This is
  [flutter/flutter#169336](https://github.com/flutter/flutter/issues/169336),
  still open. Rather than drop the on-device smoke test (the only test that
  exercises the real Rust FFI), `android/app/build.gradle.kts` registers
  `stripDevDependencyPluginsForRelease`, which removes registrations for
  plugins marked `dev_dependency: true` in `.flutter-plugins-dependencies`
  before any `compileRelease*JavaWithJavac` task. It is a no-op when the
  Flutter tool already generated a release-correct registrant, and never runs
  for debug builds. Verified with a full `flutter build apk --release` started
  from a stale debug registrant; the release APK contains no
  `integration_test` classes.

## 2026-11-12

- **Phase 0.9 is complete: encrypted backup, CSV import and CSV export.**
  This finishes roadmap 0.9.3–0.9.5, which the 2026-11-11 entry had deferred.
  - **Encrypted backup reuses the vault file format with a single master
    slot.** `format::seal_new(master, plaintext, params)` generates a fresh
    vault key wrapped by one Argon2id master slot and no recovery slot, so a
    backup only ever needs one password to open. `backup::read_encrypted`
    opens it with the existing `unlock_with_master`. A backup is therefore a
    complete `vault.keyel` file, not a bespoke container.
  - **Backup merge/replace de-duplicates by stable id, not by content.**
    Restoring the same backup twice is a no-op; entries the user edited on
    either side are never merged field-by-field. This is deliberately
    different from the CSV importer, which de-duplicates by
    `title + username + url` because third-party exports carry no ids.
  - **`backup::export_encrypted` writes atomically** (`.tmp` → `fsync` →
    rename), mirroring `vault::store`. `Vault` wipes its secrets on drop, so
    `replace` uses `std::mem::replace` and drops the old contents.
  - **CSV parsing is a small RFC 4180 reader in `keyel_core::csv`** (quotes,
    embedded commas/quotes/newlines, CRLF, UTF-8 BOM stripped by the caller's
    string decode). It is paired with `escape`/`write_row` for export. Two
    formats are recognised by header: Bitwarden (individual and organization
    `collections` variant) and Chrome. Cards and identities from Bitwarden
    map to secure notes, since the vault has no identity type yet.
  - **CSV export uses the Bitwarden column layout** so logins (with TOTP) and
    notes round-trip losslessly through our own importer; cards are written
    into the note column with their fields spelled out. It is unencrypted, so
    the UI guards it behind a red confirmation dialog.
  - **Rust owns all file I/O.** Dart passes paths from `file_picker` (or a
    temp directory) and never handles plaintext secrets: the bridge exposes
    `preview_import(path)`, `import_csv(path, mode)`, `export_backup(path,
    password)`, `import_backup(path, password, mode)` and `export_csv(path)`.
  - **The unencrypted export temp file is deleted on screen dispose**, and
    every export first clears the app's `keyel-export` temp directory so a
    stale plaintext file never lingers across sessions. (The roadmap says
    "delete after sharing"; deleting on dispose is safer because `share_plus`
    resolves before the receiving app has necessarily read the file.)
  - **New error variants** `EmptyImport`, `UnsupportedFormat`,
    `MalformedImport` map from `keyel_core::import::ImportError`.
  - **A `vaultRevisionProvider` counter** lets the import/export screen ask
    the (branch-resident) vault list to reload after a bulk mutation; it also
    invalidates `foldersProvider` and `healthProvider`.
  - **Tests:** Rust 92 core (incl. 1,000-row import, malformed CSV, duplicate
    detection, export round trip, backup round trip/wrong password/corrupt,
    merge vs replace) + 12 + 10; Dart 5 new widget tests drive the flows with
    a fake `FileTransferService`. `cargo fmt/clippy/test`, FRB idempotency,
    `flutter analyze` and `flutter test` are green.
  - **Deferred from 0.9:** Rust `zxcvbn` (the entropy heuristic is still the
    shared placeholder) and Bitwarden `.json` import.

## 2026-11-11

- **Phase 0.8 (generator + TOTP) is implemented on
  `phase/0.8-0.9-generator-totp-security`.** It supersedes the two stale
  generator notes dated 2026-11-05 below:
  - The bridge now exposes `length`, all four character classes,
    `exclude_ambiguous` and a passphrase `separator`; the UI no longer shows
    fake enforced rules.
  - Passphrase generation lives in Rust over a curated **1024-word** list
    (10 bits/word, matching the UI copy). The Dart strength estimate now
    accounts for ten bits per word instead of seven.
  - TOTP is hand-rolled in `crates/keyel_core/src/totp.rs` on `hmac` + `sha1`
    + `sha2` + `data-encoding`, with RFC 4226/6238 vectors. It is exposed as
    `current_code` (computes from the stored secret; the secret never reaches
    Dart) and `parse_otpauth` (validates a URI or bare base32 key). The one
    exception to "only `reveal_field` returns secrets" is `parse_otpauth`,
    which only echoes a secret the caller supplied.
  - Entry detail shows a live code (`EntryTotpCard`); the editor sets the
    secret via a validated manual-entry dialog. QR scanning is deferred.

- **Optional biometric during vault creation.** The separate onboarding
  quick-unlock step was replaced by an optional switch on the create-vault
  step; biometric is only offered when the device has an enrolled credential
  and defaults on. Field text colour is now the scheme's `onSurface`.

- **Phase 0.9 starts with the health analyser only (roadmap 0.9.1 + 0.9.2).**
  The backup, CSV import and file-picker work is deliberately deferred; the
  branch ships the read-only dashboard over the existing vault.
  - `keyel_core::health::analyze(vault, now)` is pure and deterministic (the
    clock is injected). It returns only ids and non-secret metadata — never a
    password. Reuse is detected by hashing each password with a **random
    16-byte salt generated per call**, so the comparison map is keyed by
    salted SHA-256 digests rather than plaintext.
  - Weak is the entropy heuristic (charset pool × length) below **50 bits**,
    mirroring the Dart `PasswordStrength.estimate`. This is a placeholder
    until the deferred Rust `zxcvbn` lands; it is documented as such.
  - Score = `100 × (1 − mean per-entry severity)`, severity weights weak
    `1.0`, reused `0.5`, insecure-URL `0.4`, old `0.2`, no-2FA `0.2`, capped
    at `1.0` per entry. An empty vault scores `100`.
  - Only non-deleted logins with a non-empty password are considered. "Old"
    means `updated_at` older than 365 days; "no-2FA" means a login with a
    password and no TOTP; "insecure" means the URL starts with `http://`.
  - The dashboard is wired to the real report with a typed `HealthCategory`
    enum, an all-clear state at a perfect score, and a bottom sheet whose
    "Fix" pops an entry id, navigates to `entryEdit(id)` and invalidates
    `healthProvider`.
  - **Still deferred from 0.9:** encrypted backup (`backup.rs`), Bitwarden /
    Chrome CSV import, `file_picker`/SAF, and the optional unencrypted CSV
    export. `docs/phase-0.8-0.9-plan.md` §6 open questions remain open.

## 2026-11-03

- **`keyel-design.md` is missing from the Desktop.**
  Errata: the Stitch export (`stitch_keyel_android_password_manager/keyel_vault/DESIGN.md`)
  is the full design-system spec (colors, typography, spacing, components).
  It was converted to **docs/design.md**; the original stays in
  `design/stitch/`. If a separate authored design doc exists, share it and we
  will reconcile.

- **License: GPL-3.0-or-later.**
  The plan offered GPL-3.0/AGPL-3.0 vs MIT. Copyleft is the norm for password
  managers (Bitwarden is GPL-compatible); picks GPL-3.0. Recorded so users of
  the crypto design can rely on it.

- **`INTERNET` permission removed from the profile manifest** (roadmap 0.1.0
  said "release/profile"). DevTools *performance profiling* may need to
  re-add it temporarily while using the inspector; this is a deliberate
  tradeoff. Debug builds keep it for hot reload; the release APK (the
  artifact users install) never gets `INTERNET`.

- **App name set to "Keyel"** (label) and applicationId `dev.agouhmad.keyel`
  per the plan §Package id.

- **Flutter template cleaned to Android-only:** `ios/`, `web/`, `macos/`,
  `windows/`, `linux/` platform folders and `rust_builder` sibling platforms
  were removed. Keeps the repo focused and the CI matrix honest.

- **Packages for 0.1.0:** flutter_riverpod 3.4, go_router 18.1, dynamic_color
  2.1, very_good_analysis 11. `dynamic_color`'s builder hands over a
  `material_ui` `ColorScheme` (transitive dep in the current ecosystem),
  which is not directly assignable to `ThemeData`; for Foundation we keep the
  brand schemes only and defer applying dynamic color to phase 0.5.0 with a
  conversion note.

- **Boring stack for crypto:** the audited RustCrypto crates (argon2,
  chacha20poly1305, ciborium, zxcvbn…) are added in the phases that use
  them (0.2.0+) so the `cargo audit` surface stays minimal today.

## 2026-11-05

- **The app uses a fixed brand palette; dynamic color is removed.**
  `dynamic_color` is gone from `pubspec.yaml` and `KeyelApp` no longer wraps
  the tree in `DynamicColorBuilder`. `KeyelColors.lightScheme` /
  `darkScheme` are explicit, role-by-role `ColorScheme` literals built from
  the Stitch export (`stitch_keyel_android_password_manager/keyel_vault/DESIGN.md`
  and the rendered screens), and `KeyelTheme.light()` / `dark()` only select
  one of them. Reason: security-critical surfaces (strength, warnings,
  TOTP countdown) must keep the same WCAG contrast and semantic meaning on
  every device; a wallpaper-derived palette cannot guarantee that. This
  supersedes the 2026-11-03 note that deferred dynamic color to 0.5.0.

- **Stitch hex values win over conflicting prose in `docs/design.md`.**
  For example the rendered light scheme uses primary `#293CA0`,
  primary-container `#4355B9`, secondary-container `#DCDEF7` and
  on-secondary-container `#5E6177`; `tertiary-container` is `#76546E` while
  `#FFD7F2` is `tertiary-fixed`. Where the prose summary disagreed, the
  exported token map was treated as authoritative.

- **Screens are presented with local demo data until storage lands.**
  `lib/features/vault/vault_entry.dart` contains ten sample entries and the
  vault, detail and editor screens read from it. Actions that need the
  encrypted vault (delete, move, duplicate, history, export/import) show an
  explanatory snackbar instead of pretending to persist. The demo layer is
  deliberately isolated so the storage phase can replace it without touching
  the design system.

- **Generator UI exposes only options the Rust API supports.**
  `rust/src/api/generator.rs` currently accepts `length` and
  `includeSymbols`; lowercase, uppercase, digits and ambiguous-character
  exclusion are always on. The screen shows those as enforced rules rather
  than passing fake toggles to the core.

- **Passphrase mode is a local placeholder.**
  It joins eight words from a bundled 128-word list using
  `Random.secure()`, roughly seven bits per word. A real passphrase
  generator (and its entropy accounting) is future Rust work; the UI and
  strength meter are already in place for it.

- **Design-system tokens are now enforced in code.**
  Radii (16/24/28/full pill), spacing, spring press scale `0.97` with
  `Cubic(0.34, 1.56, 0.64, 1)`, tonal surfaces and the Roboto Flex /
  JetBrains Mono split live in `lib/ui/theme/keyel_theme.dart` and are
  consumed through the `lib/ui/design_system/` widgets.

## 2026-11-07

- **Repository baseline repaired before phase 0.2.0.** The app/Rust tree was
  entirely untracked; it is now committed on `phase/0.1-foundation` (commit
  `chore: baseline foundation, adaptive UI and generator`). Release artifacts
  (`dist/`), Gradle/Kotlin scratch and the stale standalone `rust/Cargo.lock`
  are ignored or removed. The duplicated Stitch export at the repo root was
  deleted; `design/stitch/` remains the single source. The Android-only
  decision is enforced again by removing `linux/`, `rust_builder/linux` and
  the non-Android plugin platform declarations.

- **Phase 0.2.0 branch:** `phase/0.2.0-crypto-core`.

- **Body AAD is the stable header core, not the whole header.**
  The plan says the header is authenticated as AAD; the roadmap requires
  `change_master` to leave the body untouched. Those conflict. The body AAD is
  therefore `"KYL1" || format_version || vault_id`, while each keyslot's
  wrapped key is independently authenticated with its own kind and KDF
  parameters as AAD. Changing the master password rewrites only the master
  slot, and the body ciphertext/tag stay byte-for-byte identical.

- **Per-slot KDFs.** The master slot uses Argon2id (64 MiB / t=3 / p=1 by
  default, tuned on device in phase 0.6). The recovery slot uses HKDF-SHA256
  because the recovery key is already 256 bits of entropy. Each slot has its
  own 16-byte salt; there is no shared header-wide salt.

- **Recovery key display: 13 groups of 4 base32 characters.** 256 bits is 52
  base32 characters. The plan's "8 groups" does not divide evenly; the
  roadmap's `XXXX-XXXX-...` format is followed instead. Input parsing ignores
  case, spaces, hyphens and padding and treats `0`/`O` and `1`/`I` alike.

- **Canonical CBOR header check.** Readers re-serialize the decoded header and
  require it to match the stored bytes. Without this, a changed CBOR
  array-length marker can deserialize to the same struct and bypass the
  single-byte-tamper guarantee. The check also rejects unknown fields and
  non-canonical maps.

- **Argon2 bounds from untrusted headers are capped** at 256 MiB, t=16 and
  p=16, with `m >= 8p`, so a tampered file cannot force an unbounded
  allocation. The vault key is generated by `OsRng`; all key material is
  wrapped in `zeroize::Zeroizing`.

- **Fuzzing uses `unlock_with_vault_key`, not the password path** (fixed
  32-byte key). This exercises the parser and AEAD without spending every
  fuzz iteration in Argon2.

- **Phase 0.3.0 branch:** `phase/0.3-vault-model`.

- **Vault payload is CBOR with its own schema version.** The file format keeps
  `format_version`; the decrypted payload carries `schema_version`. This lets
  the data model evolve without changing the crypto container. New ids are
  UUID v7 so they sort by creation time.

- **Atomic save is temp + fsync + copy-to-backup + rename.** The previous file
  is copied to `vault.keyel.bak` before the rename. A crash before the rename
  leaves the main file untouched; a stale `.tmp` is ignored. The parent
  directory is fsynced best-effort for durability.

- **`.bak` fallback only on structural failure.** Bad magic, truncation,
  invalid header, unknown version or undecodable payload trigger the backup.
  `WrongPassword` does not, because a backup may predate a master-password
  change and would silently make the old password valid again. The tradeoff
  (a body bit-flip still shows "wrong password") is documented in
  `docs/vault-model.md`.

- **Trash is soft-delete with 30-day retention.** `Session::open` calls
  `purge_expired` so cleanup happens on unlock without a background job. The
  purge is persisted by the next save.

- **Search is metadata-only.** Title, tags, username, URL, cardholder and
  brand are matched; passwords, notes, card numbers, CVVs and TOTP secrets are
  excluded so search cannot be used as a secret oracle. Matching is
  NFD-normalized and lowercased for case/accent tolerance.

- **Password history is capped at 10.** `Vault::update_entry` records the old
  password only when it actually changed, newest first.

- **Secret-free summaries.** `EntrySummary` is the only list DTO: id, kind,
  title, subtitle, favorite, folder id, has-TOTP. Phase 0.4 will expose it over
  FRB; the vault key and full entries stay in Rust.

- **Best-effort plaintext wiping.** `Vault` wipes secret fields on drop and
  whenever an entry is replaced, purged or expired; create/save wrap the CBOR
  payload in `Zeroizing`. Caller-made `String` clones cannot be tracked, so
  the bridge must not hand secrets to Dart.


