# Keyel Roadmap: 1.9.0 — one-tap lock, Linux AppImage and everyday UX

This phase delivers the "one-tap lock / quick access" idea that the earlier
roadmaps reserved as 1.6.0. It is now shipped as **1.9.0** because the releases
in between already took those version numbers. The phase also makes Linux
releases double-clickable and spends a focused pass on the states and controls
users meet every day.

No vault schema change, no Keyel account/server, and no weakening of lock,
unlock, clipboard or OTA verification. The offline-by-default promise is
unchanged: one-tap lock is local-only, and the AppImage is built by CI from the
same release bundle already published as a tarball.

Version numbering note: `docs/roadmap_1.7.0.md` and `docs/roadmap_1.8.0.md`
mark 1.6.0 as reserved and not started. This document closes that item.

As before, the release is CI-driven: bump `pubspec.yaml`, add a `CHANGELOG.md`
section, merge to `main`, and let the workflow cut `v1.9.0`. **Never push tags
by hand.** Beta stays a manual `workflow_dispatch` prerelease.

**Rules for this phase**
- The Rust session stays the source of truth for "locked". A native flag alone
  must never be treated as a lock: the existing `VaultSessionNotifier.lock()`
  path (Rust session drop, clipboard wipe, reveal hiding, secure flag) is the
  only way to lock.
- Clipboard secrets are wiped natively on a lock request, before Flutter is
  involved, and again by `SensitiveClipboard.clearOnLock()`.
- UI work reuses `KeyelTheme` / `KeyelMotion` and existing design-system
  widgets. No new colour literals, no new theme, and no per-screen rebrand.
- Every new or changed widget must be readable at 200 % text scale and respect
  reduced motion. Semantic labels describe the action ("Back", not the page
  title).
- Docs, changelog and version bump come last, after the full verification suite
  is green.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 1.6.0 | One-tap lock / quick access (reserved) | — | superseded by 1.9.0 |
| 1.9.0 | One-tap lock, AppImage, everyday UX | 1–1.5 weeks | ◐ |

Legend: ☐ todo · ◐ in progress · ☑ done

---

## 1.9.0 — One-tap lock

**Goal:** let the user lock the vault in one tap from Android, without navigating
through Settings, while keeping the same lock guarantees as the in-app button.

### Definition of done
- A static launcher shortcut (**Lock vault**) and a Quick Settings tile both
  request a lock with one tap.
- Both routes clear the clipboard natively, then run the unchanged
  `VaultSessionNotifier.lock()` path — cold start via an initial-action read,
  warm app via a lock-request method call.
- The tile does not start a background service, register a receiver, or add an
  Android permission. It delegates to `MainActivity`, so there is no
  "engine dead but Rust session alive" hole.
- Locking still requires the master password / biometric to unlock; unlock
  throttling, `FLAG_SECURE` and reveal hiding are untouched.
- Tests cover the launch-action read (including fail-closed missing channel),
  the warm lock-request handler, and that a real missing entry still renders
  "not found" rather than a load error.

### Knowledge
- `MainActivity` is `singleTop`: handle the lock action in both `onCreate` and
  `onNewIntent` (`android/app/src/main/AndroidManifest.xml`).
- `VaultSessionNotifier.lock()` (`lib/data/vault_session_provider.dart`) already
  drops the Rust session, wipes the clipboard, hides reveals and sets the
  locked status; the router guard redirects `locked` to `/unlock`.
- `SensitiveClipboard` (`lib/core/platform/sensitive_clipboard.dart`) already
  owns `clearOnLock()`; native `clearPrimaryClip()` needs an API 26/27 fallback.
- The tile and shortcut share one action constant and one native clipboard
  helper. No new MethodChannel name is needed for the cold path: extend
  `keyel/platform` with `getInitialAction`, and use `keyel/lock` for the warm
  native-to-Dart request.
- Test patterns: channel mocks in `test/sensitive_clipboard_test.dart`; provider
  overrides and controller fakes in `test/vault_session_provider_test.dart`.

### Risks and mitigations
- **A native flag is not a lock.** Mitigation: never persist a "locked" marker;
  always call the Dart/Rust `lock()` path.
- **Background activity launch restrictions.** Mitigation: the tile sends a
  `PendingIntent` from a user tap, which is an allowed user-initiated launch;
  no `startActivity` from a service callback.
- **Tile briefly opens the unlock screen.** Accepted tradeoff for a
  fail-closed design. A headless lock engine would avoid the visible frame but
  would need on-device proof that the Rust session is dropped in every
  process-lifecycle case; it is deliberately out of scope here.
- **API 26/27 clipboard fallback.** Mitigation: guarded native helper, tested on
  device later (CI builds cannot exercise clipboard behaviour).

---

## 1.9.0 — Linux AppImage

**Goal:** a Linux user can download one executable file and run Keyel without
unpacking a tarball; the tarball stays as a portable fallback.

### Definition of done
- `release.yml` produces `keyel-v<version>-linux-x64.AppImage` in the Linux
  matrix leg and attaches it to the GitHub release and `checksums.txt`.
- The AppDir contains a valid `.desktop` file, an `AppRun`, the app icon and the
  unmodified Flutter bundle under `usr/bin` (preserving `$ORIGIN/lib`).
- `appimagetool` is downloaded in CI and extracted before use, so the runner
  needs no FUSE2 and no binary is vendored into the repo.
- The OTA manifests remain APK-only; desktop verification is unchanged.
- README and the decision log document the new artifact and FUSE2 runtime note.

### Knowledge
- `tool/build_linux_appimage.sh` is the single helper; CI installs `file`,
  `squashfs-tools` and `desktop-file-utils` for it.
- The app id is `com.freesoftware.keyel` (`linux/CMakeLists.txt`), used as
  `StartupWMClass`; the icon comes from `design/icon/play_store_512.png`.
- Publish assertions must require one `.AppImage`; `sha256sum keyel-*` already
  covers it.

---

## 1.9.0 — Everyday UX pass

**Goal:** the same states and navigation cues everywhere, without changing the
visual identity.

### Definition of done
- One shared `KeyelStateMessage` primitive backs loading and error states in
  the vault, entry detail, folders, trash, autofill, passkey and security
  dashboard flows, and the empty states in folders, trash and passkeys. The
  vault keeps its richer custom empty state (clear filters / add item) but uses
  the same tokens.
- A repository error is never shown as "not found"; affected screens offer an
  inline retry where a retry callback already exists.
- Secondary screens use `KeyelTopBar.iconTooltip` for Back/Close, including the
  OTA screen (migrated off `AppBar`).
- New widget tests cover the shared primitive, detail error vs. missing,
  passkey stale-match clearing, back/close semantics, and 200 % text scale for
  folders, trash and OTA.

### Knowledge
- Existing best example: `lib/features/security_dashboard/security_screen.dart`
  uses `AsyncValue` with an inline retry — extend this pattern rather than
  inventing a new one.
- Design system: `lib/ui/design_system/keyel_surfaces.dart`, `keyel_buttons.dart`,
  `keyel_top_bar.dart`, `keyel_snackbar.dart`, all exported by `lib/ui/keyel.dart`.
- The debug screens stay deliberately plain and are out of scope.

### Risks and mitigations
- **Behaviour regressions from replacing spinners.** Mitigation: keep observable
  text and callbacks, assert them in widget tests, and run the full suite.
- **Fixed-height rows at 200 %.** Mitigation: use `Flexible`/`Expanded`/`Wrap`
  and run new scale tests on every changed screen.

---

## Verification and sequencing

1. Lock flow first (security), with tests before behaviour changes where
   practical; then AppImage packaging; then the UI pass.
2. Run the full suite before the version bump: `dart format`, `flutter analyze`,
   `flutter test`, `cargo fmt --all --check`,
   `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test
   --workspace`, `./tool/check_no_secret_logs.sh`, FRB regeneration idempotency,
   and both debug builds. Smoke-test the AppImage helper locally.
3. Bump `pubspec.yaml` to `1.9.0+1` and add the `## [1.9.0]` changelog section
   last, then merge to `main` and monitor both CI workflows.
