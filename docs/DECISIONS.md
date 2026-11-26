# Keyel — Decision Log

Requests to change/interpret the plan, design or roadmap are recorded here
(date, decision, reason). Priority when documents conflict: roadmap > plan >
design (docs/roadmap.md header).

## 2026-11-26

- **1.14.0 focuses on desktop responsiveness and fixes the Linux startup
  crash.** The OTA banner sits in `MaterialApp.builder`, above the Navigator's
  Overlay, so a `Tooltip`'s `OverlayPortal` asserted with `No Overlay widget
  found.`. Its dismiss action is now exposed through semantics instead. The
  focused first-run/unlock forms moved to a shared `KeyelFocusedBody` that puts
  both the width cap and the centering inside the vertical scroll view; this
  fixes left-pinned forms on wide windows and mirrors correctly in RTL. The cap
  grows with the text scaler so 200% text keeps readable line lengths, and
  viewport-height centering never clips taller forms.

- **Desktop builds pin the original x86-64 baseline instead of trusting the
  runner.** The 1.12.0/1.13.0 CI-built Linux ELFs advertised
  `x86-64-v2`/`x86-64-v3` and glibc refused to start them on older CPUs with
  `CPU ISA level is lower than required`. `linux/CMakeLists.txt` appends
  `-march=x86-64 -mtune=generic`, `.cargo/config.toml` pins
  `-C target-cpu=x86-64` for every desktop x86-64 Rust target, and release/CI
  jobs run `tool/check_cpu_baseline.sh` so a hostile `-march=x86-64-v3`
  environment can no longer ship an unusable artifact. A local hostile-flags
  build now emits only `x86-64-baseline`. Release CI additionally hashes
  `.cargo/config.toml` into the Rust cache key (a restored pre-flag `target/`
  could still hold v2 objects) and runs `tool/normalize_cpu_baseline.sh` before
  the guard, because a runner's startup objects can add an ISA note that our
  own compile flags cannot remove.

- **Vault storage creation is hardened without a schema change.** A `vault.keyel.bak`
  now counts as an existing vault everywhere (open, unlock, recovery and create)
  so first-run onboarding cannot overwrite the only recoverable copy; factory
  reset removes the main file, `.bak` and `.tmp`. New vault/backup files are
  forced to `0600` on Unix, `settings.json` saves are serialized and atomic,
  legacy migration picks the newest candidate via temp+rename and carries
  preferences forward, and the one-time recovery key survives a biometric
  setup error. A hidden user-home fallback keeps the bridge initialized if the
  platform support directory cannot be resolved.

- **Sync room creation uses LocalSend-style same-network discovery as a
  convenience, not as authentication.** Discovery enumerates non-loopback
  interfaces, probes the LocalSend multicast group/broadcast target with a
  small bounded secret-free payload, accepts only same-subnet answers, and
  requires explicit user selection. It adds no new permission (`INTERNET`
  already exists) and no sync server; the folder backend and the one-time
  `KYSYNC1-…` pairing code remain the trust root. Manual code entry is always
  available. This narrows the 1.5.0 "no discovery" non-goal to "no discovery as
  a transport or trust signal".

## 2026-11-17

- **OTA updates are in, and with them the `INTERNET` permission.** The user
  chose the full self-updater, which needs to reach a release source and install
  a downloaded APK. This reverses the earlier "Keyel must never request network
  access" rule: the main manifest now declares `INTERNET` and
  `REQUEST_INSTALL_PACKAGES`, and `build.sh`'s `verify_policy` no longer fails a
  release that carries `INTERNET`. The offline-only promise is replaced by a
  narrower one: the app contacts the release source only to check for and fetch
  an update, and no vault data is ever transmitted. The APK is verified by
  SHA-256 before it is handed to the system installer.

- **Entry icons live in the vault payload at schema v2, not in a side file.**
  `Entry.icon` is an optional string slug (`#[serde(default)]`), so the vault
  file format is untouched and the frozen v1 byte fixture still pins it. Bumping
  `VAULT_SCHEMA_VERSION` to 2 with a no-op v1→v2 migration keeps the version
  honest while old vaults open unchanged. A sidecar icon map would have needed
  its own atomic write path and could drift from the vault; keeping icons inside
  the entry means one source of truth and no new on-disk artifact.

- **Windows and macOS become real targets, superseding the 2026-11-16
  decision.** That entry said "desktop" meant large windows on the Linux target
  only, and that new OS targets were a separate, unmade decision. The user has
  now made it: `windows/` and `macos/` are generated and wired, so the phrase
  "desktop" in the design docs means the adaptive layout on Windows, macOS and
  Linux alike. Windows and macOS cannot be built or run on this Linux host, so
  their runners are code-complete but unverified here.

- **The Rust FFI plugin gains Windows and macOS glue.** `rust_builder` already
  carried `android/` and `linux/`; it now also has `windows/CMakeLists.txt` and
  a macOS podspec so cargokit builds `rust_lib_keyel` on those hosts. Because
  this Flutter version defaults macOS to Swift Package Manager and cargokit
  needs CocoaPods, a `macos/Podfile` is added to enable the pod path alongside
  SPM.

- **The icon catalog is a curated list, not every Material glyph.** It grew from
  ~68 to 188 icons across nine categories (adding a Crypto category), chosen for
  services people actually store logins for and verified to exist in the pinned
  Flutter SDK. `test/entry_icon_test.dart` now asserts a floor of 150 icons and
  that every category is populated, so a future SDK or edit cannot silently
  shrink the picker.

- **Desktop builds run on their own OS in CI, not from one host.** Flutter only
  registers the *host* desktop build target (`flutter build windows` on Linux
  fails with "only supported on Windows hosts", and `macos` is not even a
  subcommand there), so a `desktop-build` matrix in
  `.github/workflows/ci.yml` builds Linux on `ubuntu-latest`, Windows on
  `windows-latest` and macOS on `macos-latest`. cargokit installs the Rust
  target it needs, and macOS uses ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`),
  so no certificate is required.

- **The macOS runner needs two entitlements and a podspec license fix.** A
  sandboxed macOS app cannot use the keychain without `keychain-access-groups`
  (required by `flutter_secure_storage`) or reach the network without
  `com.apple.security.network.client` (the OTA update check); both are now in
  `DebugProfile.entitlements` and `Release.entitlements`. The Rust podspec's
  `:file => '../LICENSE'` resolved to a nonexistent `rust_builder/LICENSE`; it
  now points at the repo `LICENSE` (`../../LICENSE`).

- **CI pins Flutter and matches `build.sh`'s FRB invocation.** Several failures
  that predate the desktop work were fixed so the pipeline can go green. (1) The
  `flutter` job regenerated bindings with `--no-web`, but the committed bindings
  include the web module (generated by `build.sh`, which passes no such flag);
  the flag was removed so CI checks what is actually committed. (2) CI tracked
  `channel: stable`, which had drifted from the 3.47.9 that last ran green to
  3.50.0. Flutter 3.50.0 requires Android Gradle Plugin 9.1.1 (the project pins
  the 3.47.x template default of 9.1.0) and broke cargokit's Rust build on
  Windows, so CI is pinned via `FLUTTER_VERSION: 3.47.9`. Flutter and AGP should
  be upgraded together. (3) The Linux desktop job was missing `libsecret-1-dev`
  (needed by `flutter_secure_storage_linux`). (4)
  `passphrase_default_separator_is_hyphen` and
  `passphrase_custom_and_empty_separator` failed intermittently because the
  wordlist contained the hyphenated word "so-called"; it is replaced with
  "sober", and a guard test now rejects entries that are not plain ASCII
  letters.

- **The nightly parser fuzz pins the host target explicitly.** `taiki-e/install-action`
  does not support `cargo-fuzz` and falls back to `cargo-binstall`, which
  installs a musl-linked `cargo-fuzz`. `cargo fuzz` defaults its build target
  to the triple the `cargo-fuzz` binary was built for, so the job tried to
  build for `x86_64-unknown-linux-musl`: the nightly toolchain only ships the
  gnu host target (`E0463: can't find crate for core`) and ASan rejects musl's
  static libc, so the run aborted in about 20 seconds without fuzzing anything.
  `.github/workflows/fuzz.yml` now passes `--target x86_64-unknown-linux-gnu`.

- **The Windows desktop build failed on a relative-path bug in our CMake
  scaffold, not on the runner image.** `rust_builder/windows/CMakeLists.txt`
  passed cargokit `../../rust`, copied from the Linux template. Flutter builds
  the plugin through the symlink
  `windows/flutter/ephemeral/.plugin_symlinks/rust_lib_keyel/windows/`, and
  Windows collapses `..` *lexically*, before following that symlink — POSIX
  resolves the symlink first, which is exactly why Linux and macOS were fine.
  So `.../rust_lib_keyel/windows/../../rust` collapsed to the nonexistent
  `.plugin_symlinks/rust`, and cargokit died with
  `PathNotFoundException ... Cargo.toml`, visible only as an opaque
  `MSB8066 ... exited with code -1` because `flutter build windows` filters
  MSBuild's log (flutter/flutter#194906). The manifest path is now the six
  levels the flutter_rust_bridge Windows template uses
  (`../../../../../../rust`); the Linux/macOS `../../rust` is unchanged. This
  supersedes the earlier reading of this failure as a Visual Studio 2026 /
  CMake 4 problem: the identical error reproduced on `windows-2022` (VS 2022,
  v170).

- **The Windows desktop job stays pinned to `windows-2022` as a precaution, and
  the failure-diagnostic step stays.** `windows-latest`/`windows-2025`
  currently serve the beta `windows-2025-vs2026` image (Visual Studio 18,
  CMake 4.x; actions/runner-images#14004). That image is *not* what broke this
  build, but pinning keeps the job on the stable, verified VS 2022 toolchain
  while the VS 2026 image settles. A `failure()`-only step re-runs the Windows
  build with `-v` and greps the cargokit lines so a future regression is
  diagnosable from CI alone; it is what made this root cause visible.

- **Releases publish like Walt's: build/sign on a version bump, then tag +
  `gh release` with checksums and a committed OTA manifest.**
  `.github/workflows/release.yml` triggers on a push to `main` that touches
  `pubspec.yaml` or `CHANGELOG.md` (plus `workflow_dispatch`), runs the existing
  `./build.sh` (keystore provisioning, split-ABI + universal APKs,
  `checksums.txt`, apksigner and password-manager policy verification, and the
  `## [<version>]` CHANGELOG notes), creates/replaces the `v<version>` tag and
  GitHub release, then rewrites and commits `update_manifest.json`. The trigger
  is narrowed to the files a version bump touches so a docs-only commit cannot
  rebuild and replace a signed release; Walt releases on every push to `main`,
  which is the one place this deliberately deviates.

- **The release is multi-platform: Android + Linux + Windows + macOS, all from
  one trigger, with the CHANGELOG section as the release notes.**
  `.github/workflows/release.yml` has three jobs. `android` (ubuntu) builds the
  signed split-ABI + universal APKs via `./build.sh`. `desktop` is a matrix that
  builds each host target on its own runner (Linux `tar.gz`, Windows `zip`,
  macOS `ditto`-zipped `Keyel.app`) because Flutter registers only the host
  desktop target. `publish` (needs both) downloads every artifact into one
  `dist/`, writes a single `checksums.txt` over all of them, creates the tag +
  GitHub release with `--notes-file dist/notes.md` — the `## [<version>]`
  section of CHANGELOG.md, used verbatim as the release notes and copied into
  the manifest's `releaseNotes` — then rewrites/commits `update_manifest.json`.
  macOS bundles are ad-hoc signed (no certificate), so Gatekeeper warns on first
  launch; that matches what CI verifies today. The macOS app is a **universal**
  x86_64 + arm64 binary (Flutter builds `ARCHS_STANDARD`, and cargokit's Rust
  framework is built for both archs too), so the artifact is named
  `…-macos-universal.zip` and runs natively on Intel and Apple Silicon alike.

- **Windows ships a real `.exe` installer and macOS a `.dmg`, alongside the
  portable archives.** A zipped bundle is not something a Windows user can
  double-click to install (the first 1.1.0 report was literally "I don't see
  .exe for windows"), so the `desktop` job builds
  `keyel-v<version>-windows-x64-setup.exe` with **Inno Setup**, which is
  preinstalled on the `windows-2022` runner image (6.7.1). The script lives at
  `packaging/windows/keyel.iss` and takes `/DKeyelVersion`, `/DKeyelBundle`
  (absolute path to the built `Release\` dir) and `/DKeyelOut`; the AppId GUID is
  fixed so upgrades and the uninstaller keep working, and `PrivilegesRequired=lowest`
  installs per user with no UAC prompt. The macOS job also produces
  `…-macos-universal.dmg` via the native `hdiutil` (the `.app` plus an
  `/Applications` symlink, so it is a drag-to-install volume). The portable
  `.zip`s stay published for people who would rather not install. `publish`
  requires at least one `*setup.exe` and one `*.dmg` and attaches them to the
  release.

- **Desktop builds run on pull requests only in CI; the release owns them on
  `main`.** GitHub's macOS arm64 hosted runners are capacity-constrained, and a
  version-bump push to `main` fires `ci.yml` *and* `release.yml` at the same
  time, so both would queue a macOS job and the second was repeatedly cancelled
  in the queue before it ever started. `ci.yml`'s `desktop-build` matrix is now
  gated to `pull_request`; the release workflow builds and validates the desktop
  bundles on `main`, so nothing is lost and the release no longer competes for
  the same runner pool. If a macOS job is still cancelled by capacity, re-run
  the failed jobs (`gh run rerun <id> --failed`) — the successful Android /
  Linux / Windows artifacts are reused.

- **Builds are cached aggressively so a release is dominated by the real
  compiles.** Flutter SDK (`subosito/flutter-action` `cache: true`), the pub
  cache, Gradle caches, the Rust target dir (`Swatinem/rust-cache`, one
  `shared-key` per target), and the compiled `flutter_rust_bridge_codegen`
  binary (`actions/cache` keyed on its version + OS + arch, so the slow
  `cargo install` runs only on the first release or a version bump) are all
  restored between runs. `cargo-audit` comes from `taiki-e/install-action`
  (prebuilt). The same caches were added to the CI `flutter`,
  `flutter-android-build` and `desktop-build` jobs.

- **The release tag is created server-side, not pushed from the checkout.** The
  first 1.1.0 publish built, signed and staged all three APKs correctly but died
  in `Publish GitHub release`: after the pre-existing `v1.1.0` tag (pushed by
  hand, no release) was deleted, `git push origin v1.1.0` from the runner's full
  clone was rejected with `! [remote rejected] v1.1.0 -> v1.1.0 (missing
  necessary objects)`. The workflow now lets GitHub create the ref itself with
  `gh release create --target "$GITHUB_SHA"`, which points at a commit the
  server already has, so no objects cross the wire and the tag is created
  atomically with the release. A stray tag is removed first with
  `gh api -X DELETE repos/<repo>/git/refs/tags/<tag>`, and a previous release is
  replaced via `gh release delete --cleanup-tag`; both tolerate "not found", so
  re-running the same version is safe.

- **The in-app updater now reads `update_manifest.json`, not the release body.**
  The manifest is the only source that carries the universal APK's `sha256`, so
  the updater can actually verify the download. The old GitHub-API path only
  scraped a 64-hex hash out of the release notes, which the notes never
  contained, so verification silently no-op'd and any download was installed
  unchecked. The stable channel fetches the raw manifest (with a cache-busting
  `?ts=` because `raw.githubusercontent.com`'s CDN can serve a stale copy for
  minutes after a release); the beta channel still uses the GitHub Releases API
  so pre-releases keep working, and a `customManifestUrl` overrides both. The
  schema follows Walt's (`latestVersionName`, `latestVersionCode`, `apkUrl`,
  `sha256`, `releaseNotes`, `publishedAt`) plus a `size` key so the UI can show
  the download size before it starts.

- **The release job cannot publish until the `KEYEL_*` secrets exist.**
  `build.sh` refuses to ship an unsigned or debug-signed APK, so
  `.github/workflows/release.yml` fails fast until `KEYEL_KEYSTORE_BASE64`,
  `KEYEL_KEYSTORE_PASSWORD`, `KEYEL_KEY_ALIAS` and `KEYEL_KEY_PASSWORD` are
  configured on the repository. The committed `update_manifest.json` is seeded
  for the current version and rewritten on the first signed release.

## 2026-11-15

- **Phase 0.12 (Beta) starts on `phase/0.12-beta`; localization is deferred.**
  Per the user's request, no l10n work happens now, so the beta ships English
  only and item 10's store descriptions are English. The phase is code-first:
  the parts that need a device or testers (daily use, multi-device matrix,
  recruiting) are tracked as open, not silently claimed.

- **Diagnostics are redacted by construction, not by filtering.** The "Report a
  problem" bundle is built from an explicit allow-list of fields
  (`buildDebugBundle`) rather than by dumping `AppPreferences` and stripping
  secrets afterwards. `recentSearches` holds site names (user data) and is the
  obvious leak, so it is simply never read; `test/debug_bundle_test.dart` pins
  that. This mirrors the Rust side's secret-free DTO rule.

- **The app version is a compile-time constant, not a plugin read.** Rather than
  adding `package_info_plus`, `build.sh` passes
  `--dart-define=KEYEL_VERSION="$VERSION"` and `AppInfo.version` falls back to
  `dev` in debug runs. This keeps the release build honest (the bundle version
  cannot drift from `pubspec.yaml`) with no new dependency and no platform
  channel.

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

- **The on-disk vault format is frozen and guarded by a byte-exact fixture.**
  Because the beta is about not losing data, `format::codec::tests` pins a
  complete v1 `vault.keyel` file assembled from fixed inputs. Any change to the
  magic, version, header CBOR, slot AAD or body layout fails CI immediately;
  regenerating the fixture to make the test pass is explicitly the wrong move —
  it means existing vaults would stop opening, so a migration and a
  `docs/crypto-design.md` update are required instead. This is the code-level
  half of the upgrade-path check (item 6); the device half still needs an older
  APK installed over a newer one.

## 2026-11-16

- **The responsive reform uses one shared content helper, not per-screen
  widths.** Screen bodies each picked their own `ConstrainedBox` max width, or
  had none and stretched edge-to-edge. They now share `KeyelContent` +
  `KeyelWindowSpacing` (`lib/ui/adaptive/content.dart`), so phone / tablet /
  desktop behaviour is defined once, named (`form` 560 / `reading` 720 /
  `page` 1000 dp) and testable, instead of a scattering of magic numbers.

- **"Desktop" means large windows and the Linux target, not new OS targets.**
  The app ships `android/` and `linux/` only. The responsive work tunes the
  existing `WindowSizeClass` layouts for wide windows (and therefore the Linux
  desktop build); it does not add Windows, macOS or web targets. Adding those is
  a separate, larger decision that has not been made.

- **The vault list-detail split moves from 720 dp to the design-spec 840 dp.**
  At 720–839 dp the medium nav rail already takes 76 dp, leaving too little room
  for a 380 dp list plus a usable detail pane. The split now follows
  `WindowSizeClass.supportsListDetail` (>= 840 dp) in both `VaultLayout` and
  `VaultListPane`, and the list pane scales between 320 and 420 dp instead of a
  fixed 380 dp.

- **The changelog starts at 1.0.0; the 0.x pre-release history is discarded.**
  Per the user's request, `CHANGELOG.md` carries a single `[1.0.0]` entry
  describing the first stable release, and `pubspec.yaml` is bumped to
  `1.0.0+1`. This means the versionCode becomes 10000
  (`major*10000 + minor*100 + patch`) and `build.sh --release-notes` extracts the
  `[1.0.0]` section. The 0.4.0 / 0.11.0 / 0.12.0 entries were dropped rather than
  kept below, so the public changelog reads as a first release. The roadmap's
  0.12 (Beta) work is folded into this 1.0.0 release.

- **Pushed sub-pages keep the shell chrome via `KeyelSubShell`, not nested
  shell routes.** Folders, trash, import/export, the entry editor and entry
  detail are top-level `GoRoute`s, so on a tablet/desktop they used to cover the
  nav rail. Rather than restructure them into the `StatefulShellRoute` branches
  (which would change their back-stack semantics and the route table), each is
  wrapped in a small `KeyelSubShell` that reuses the existing rail/drawer chrome
  and is a pass-through on compact phones. The rail's selected index comes from
  a `KeyelTab` constant (vault for the entry routes, settings for
  folders/trash/import-export); tapping a rail item does `context.go` to that
  tab. The autofill picker and `/debug` stay top-level — the picker is a
  separate Flutter entrypoint and `/debug` must be reachable while locked.

- **Dead adaptive code is deleted, not kept "for later".** `KeyelListDetail` /
  `KeyelEmptyDetail` (`lib/ui/adaptive/list_detail.dart`) and the foldable-hinge
  helpers (`lib/ui/adaptive/hinge.dart`) were only referenced by each other and
  the `ui/keyel.dart` barrel; `VaultLayout` had already stopped using them, so
  there was no dedicated foldable-hinge layout. `UnlockPlaceholderScreen` was
  likewise unreferenced. All three files and their barrel exports are removed so
  the adaptive surface reflects what actually ships.

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

- **App name set to "Keyel"** (label) and applicationId `com.freesoftware.keyel`
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

- **The application id is `com.freesoftware.keyel` (was `dev.agouhmad.keyel`).**
  The original id embedded a personal handle; the shipped id is now
  project-owned and identical in spirit on every platform: the Android
  `namespace`/`applicationId` (with the Kotlin sources moved to
  `android/app/src/main/kotlin/com/freesoftware/keyel/`), the Linux
  `APPLICATION_ID`, the macOS `PRODUCT_BUNDLE_IDENTIFIER` (and its
  `RunnerTests`), and the Windows `CompanyName`/`LegalCopyright`. Android keys
  an app by its `applicationId`, so a build with the new id installs *next to*
  (rather than upgrading) an existing `dev.agouhmad.keyel` install; at 1.1.x
  that is an acceptable one-time break, and every later release upgrades
  cleanly from here.

## 2026-11-20

- **Version 1.7.0 is the opt-in breach check; 1.6.0 is reserved.** The user
  chose to skip the one-tap lock/quick-access idea for now and build the HIBP
  k-anonymity check next. Scope is in `docs/roadmap_1.7.0.md`; the stale "1.4"
  row in the old roadmap now points there.

- **The offline promise is narrowed, not removed.** Keyel stays local and
  offline by default. With explicit, revocable opt-in, the app may contact one
  additional HTTPS endpoint — `https://api.pwnedpasswords.com/range/` — and
  only when the user taps **Check now** with the vault unlocked. This extends
  the 2026-11-17 OTA decision; no Keyel account or server is introduced.

- **SHA-1 is protocol compatibility, not password storage.** Rust hashes each
  active login password and sends only the first five hex characters. Dart
  never sees a password or full digest, has no configurable endpoint, and only
  returns raw range bodies to Rust for comparison. Full digests are `Zeroizing`
  and live only in a pending check that is wiped on finish, cancel, error and
  lock. This keeps the "secrets live in Rust" rule intact.

- **No new Android permission, no vault schema change.** `INTERNET` already
  exists for OTA; the opt-in flag is a non-secret `settings.json` preference,
  so v1–v5 vaults and 1.5.0 sync payloads are unaffected.

- **The release remains CI-driven.** Bump `pubspec.yaml` and `CHANGELOG.md`,
  merge to `main`, and let the workflow cut `v1.7.0`; never push a tag by hand.

## 2026-11-20 (1.8.0 kickoff)

- **Version 1.8.0 is a quality release across three tracks:** codebase
  optimisation, security hardening and UI polish. Scope is in
  `docs/roadmap_1.8.0.md`. 1.6.0 (one-tap lock / quick access) stays reserved.

- **"Never clear clipboard" no longer survives a lock.** The preference now
  controls only the timed wipe while the vault is unlocked and the app is
  foregrounded. Locking, backgrounding, or a Rust-side lock event always wipes
  immediately (`SensitiveClipboard.clearOnLock`). This closes the residual in
  T5; the settings dialog was updated to say so.

- **Every secret copy goes through one clipboard path.** Generator, recovery-key
  and vault-row copies now all call `SensitiveClipboard`, so the timed wipe and
  the lock/background wipe apply uniformly. On Android 13+ the native channel
  sets `ClipDescription.EXTRA_IS_SENSITIVE`, keeping the value out of clipboard
  history and suggestions; other platforms fall back to Flutter's clipboard.

- **Reveals are temporary by default.** Card/CVV/note reveals share the 15-second
  password timer and `EntryDetailController.hideAll()` clears all reveals on a
  lock/background session change; `KeyelPasswordField` re-masks a manual reveal
  after 15 s and never auto-reveals a generated password. A focus-loss based
  re-mask was tried and dropped: Flutter moves focus to the trailing toggle on
  an explicit reveal, so "focus left" cannot distinguish an intentional toggle
  from leaving the field. A timer is unambiguous and strictly stronger.

- **Autofill web domains are only trusted from a browser.** A `packageName`
  without an `androidapp://` match no longer falls through to domain matching;
  an arbitrary app hosting a site in a WebView cannot claim that domain. Only an
  allowlisted browser (or a request with no package) may match a web domain.

- **OTA updates fail closed on a missing or malformed checksum.** A release
  without a 64-hex SHA-256 is not offered, downloaded or installed, and a failed
  verification deletes the partial download. Silent no-op verification in the
  beta channel was the security defect being closed.

- **Redacted `Debug` is now a general rule, not a few special cases.** All DTOs
  that carry a password, digest, private key, TOTP secret or decrypted field
  implement a manual redacted `Debug`, and `tool/check_no_secret_logs.sh`
  mechanically enforces the "no printing calls" rule in both CI and release.
  The only allow-listed calls are a benchmark timing print and one startup
  filesystem-path error, each justified at the call site.

- **Transient secret buffers are wrapped in `Zeroizing`.** `GeneratedPasskey`,
  recovery-key and pairing-code normalized/encoded buffers, and CSV export and
  import buffers now wipe themselves on drop. Plaintext CSV files are created
  with `create_new` + mode `0600` on Unix so a umask or a symlink cannot widen
  access to them.

## 2026-11-20 (stable + beta OTA channels)

- **Two OTA channels, two manifests.** `update_manifest.json` stays the stable
  manifest and `update_manifest_beta.json` is the new beta manifest. Both carry
  `channel` and `isPrerelease`; the CI computes sha256/size from the universal
  APK of the run that publishes them and verifies the released APK against the
  manifest of that channel. Only the manifest that changed is committed back.
  The beta manifest is seeded with an empty version/hash and a "no beta yet"
  note, so the updater fails closed and finds no candidate until a beta ships.

- **Beta is a manual prerelease, stable is push-driven.** A push to `main`
  touching `pubspec.yaml`/`CHANGELOG.md` is always stable. Beta only exists via
  `workflow_dispatch` with `channel=beta`, `beta_version` (semver, e.g.
  `1.9.0-beta.1`) and optional `beta_notes`; the workflow fails fast when the
  version is missing or malformed. Beta does not bump `pubspec.yaml` or
  `CHANGELOG.md`, is never auto-published on push, and its GitHub release is
  marked `--prerelease`. Stable keeps its exact original release path.

- **The version override is CI-only and does not weaken the build.** `build.sh`
  honors `KEYEL_RELEASE_VERSION` solely for the beta dispatch; stable still
  derives from `pubspec.yaml`. `versionCode` is computed from the semver core
  (`1.9.0-beta.1` -> `10900`) because a prerelease suffix is not a numeric
  component. Operator-supplied `KEYEL_RELEASE_NOTES` replace the CHANGELOG
  requirement for beta; stable keeps strict CHANGELOG extraction. Signing,
  apksigner verification and the password-manager policy checks run unchanged
  for both channels, and no tag is ever pushed from a local checkout.

## 2026-11-20 (automatic update notifications)

- **Foreground-only checks, no background service.** An `OtaCheckHost` wraps the root
  app and checks the selected channel's manifest on mount, on every resume, and on a
  30-minute timer while the app is visible. Silent checks are throttled with a persisted
  `otaLastCheckedMs`, never surface network errors, and never interfere with a download
  in progress. No alarm, service or receiver is registered: an update is detected the next
  time the user opens Keyel, which preserves the "no background network" promise.

- **Both an OS notification and a global in-app banner.** A successful silent check
  posts a native Android notification through `keyel/notifications` (one per discovered
  version, tracked by `otaLastNotifiedVersion`) and surfaces a dismissible top banner in
  `MaterialApp.builder`, above every route. The banner is not a snackbar or dialog, so it
  does not interrupt the user; dismissing hides only the currently offered version. The
  banner animates with `KeyelMotion` and respects reduced motion and 200% text scale.

- **Notifications are opt-in and honest.** `POST_NOTIFICATIONS` is requested once on the
  first automatic check (remembered by `otaNotificationPromptShown`) and can be revoked in
  Android settings. The updater screen shows the current permission state and an explicit
  "Enable update notifications" action; declining never blocks the in-app banner or the
  manual check. The notification contains only the version and channel — no vault data.


## 2026-11-21 (1.9.0: one-tap lock, AppImage, everyday UX)

- **The reserved 1.6.0 one-tap lock idea ships as 1.9.0.** 1.7.0 and 1.8.x already
  took the intervening version numbers. `docs/roadmap_1.9.0.md` supersedes the
  old 1.6.0 reservation; scope is one-tap lock, a Linux AppImage and a bounded
  UI/UX consistency pass. No schema or threat-model change.

- **One-tap lock always goes through the existing Dart/Rust lock path.** Both a
  static launcher shortcut and a Quick Settings tile send a single
  `com.freesoftware.keyel.action.LOCK` action to `MainActivity`. Cold starts
  read it with `getInitialAction`; warm apps receive a `keyel/lock`
  `lockRequested` call. The clipboard is wiped natively first, then
  `VaultSessionNotifier.lock()` drops the Rust session, hides reveals and sets
  the locked state. A native "locked" flag is deliberately *not* persisted: a
  flag cannot zeroize the Rust key and could be clobbered by a Dart save.

- **The tile delegates to the activity instead of holding an engine.** A
  `TileService` has no `FlutterEngine`, so a tile that locked directly would
  leave the Rust session alive whenever the engine was destroyed but the
  process survived. The tile clears the clipboard and sends a `PendingIntent`
  to `MainActivity` from a user tap (an allowed background-launch exception);
  no receiver, background service, new permission or headless engine is added.
  The accepted tradeoff is that the unlock screen briefly appears.

- **Linux releases carry a FUSE-free `.AppImage` alongside the tarball.**
  `tool/build_linux_appimage.sh` assembles an AppDir from the unmodified Flutter
  bundle, downloads `appimagetool` in CI, and uses `--appimage-extract` so the
  runner needs no FUSE2. The app id stays `com.freesoftware.keyel`; OTA
  manifests remain APK-only and desktop verification is unchanged. The tarball
  stays as the portable fallback.

- **The UX pass is token-driven, not a rebrand.** A single `KeyelStateMessage`
  replaces ad-hoc loading/empty/error widgets, load errors are kept distinct
  from "not found", passkey lookups clear stale matches on failure, and Back /
  Close controls use `KeyelTopBar.iconTooltip` (including OTA, now off
  `AppBar`). Existing `KeyelTheme` / `KeyelMotion` tokens are reused; no new
  colour literals, schema or data-model changes.


## 2026-11-21 (1.10.0: EN/FR localization, autofill completeness, quick access)

- **English is the template locale; French is a complete translation of the
  checked-in ARB template.** `lib/l10n/app_en.arb` and `app_fr.arb` are the
  source of truth, generated classes live in `lib/l10n/generated` and are
  committed. Both CI jobs run `flutter gen-l10n` and fail on a diff, so no
  local-only generation step is required to analyze or test. `l10n.yaml` no
  longer sets `synthetic-package` (Flutter 3.50 ignores it). Arabic stays
  deferred: the RTL smoke test forces `TextDirection.rtl` without shipping an
  untranslated locale.

- **A locale choice never touches crypto, storage or matching.** The language
  id is a plain non-secret preference; `MaterialApp` receives the resolved
  `Locale` and delegates. `l10nOf(context)` falls back to the English template
  when no delegate is mounted, which keeps isolated widget tests resilient.
  Rust matching and all secret handling remain locale-independent.

- **"Never for this site" stores only canonical, non-secret identities.** The
  Dart picker/save flow writes `host:<lower-host>` for trusted browsers (or no
  package) and `package:<lower-package>` for arbitrary apps — the same trust
  rule the Rust matcher uses. `NeverForSites.kt` reads that app-private JSON
  from `filesDir/keyel/settings.json` and gates both fill and save *before* the
  auth prompt. Malformed or wildcard entries are discarded on load; a parse
  failure simply makes the choice unavailable, never widens matching. No
  domain is logged or included in the diagnostics bundle.

- **Digital Asset Links verification is intentionally offline.** Real DAL
  checks need a network fetch, which conflicts with the offline-by-default
  promise. Instead, an opt-in `Verified sites only` preference passes
  `require_verified: true` to `find_matches`, which drops same-site and text
  hits and returns only exact package/host matches. This can only *narrow* the
  offered set; it never adds a match and never bypasses unlock/auth. Online
  statement verification remains a tracked follow-up, not a hidden runtime
  dependency.

- **Android 11+ inline suggestions carry static copy only.** The service
  advertises `supportsInlineSuggestions`, and `InlineSuggestionHelper` attaches
  an unpinned `InlinePresentation` using the IME's V1 spec and the *same*
  mutable auth `PendingIntent` as the dropdown dataset. If the IME has no
  compatible spec or allows no suggestions, no chip is shown and the normal
  dropdown still works. No credential text is ever placed on the keyboard
  surface; tapping the chip still runs `AuthActivity`.

- **The generator shortcut and widget reuse the lock plumbing.** A
  `com.freesoftware.keyel.action.GENERATE` action reaches `MainActivity` from
  a static launcher shortcut or an immutable widget `PendingIntent`. Cold
  starts set `initialRouteProvider`; warm apps get a `keyel/generate`
  `generateRequested` method call. The host only navigates to `/generator` —
  it never generates, copies or reads a secret, and no clipboard wipe runs for
  this action (only lock wipes). The widget has `updatePeriodMillis=0`, no
  service, no new permission and no vault data in its `RemoteViews`.

- **Verification uses the CI-pinned Flutter, not just the local default.** The
  3.50.1 toolchain on this machine accepts a newer AGP and rewrites some
  generated output, so a local green run was provisional. A detached worktree of
  the Flutter SDK at tag `3.47.9` is used for format/analyze/test/gen-l10n and
  both debug builds; all results match CI's pinned version. `pubspec.lock` is
  kept at the 3.47.9 resolution (`test_api 0.7.12`) because that is what CI
  installs.

- **The Wear OS companion ships as a separate APK.** AGP 9 removed the
  `wearApp(...)` bundling DSL, so `android/` still builds the handheld app
  unchanged and `wear/` is built with `./gradlew :wear:assembleRelease`. CI
  runs the watch unit tests and uploads `keyel-wear-apk` as a build artifact.
  Publishing it as a release asset is a follow-up; the phone↔watch channel
  works with either installation method.
