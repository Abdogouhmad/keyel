# Changelog

All notable changes to Keyel are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.12.0] - 2026-11-16

Beta: daily-use polish, self-service diagnostics and a responsive UI reform.

### Added

- **Report a problem** in Settings: writes a redacted `keyel-diagnostics.txt`
  (app version, platform and non-secret settings only) and opens the share
  sheet so it can be attached to a bug report. Secrets and recent searches are
  excluded by construction.
- `ISSUES.md`, a running friction log for the beta with a severity scale.
- User documentation in the README: quick start, an FAQ (forgotten master
  password, where data lives, what the diagnostics file contains) and backup
  advice.

### Changed

- **Responsive UI reform.** Every screen body now shares one adaptive content
  helper that centers content in a width-capped column (560 / 720 / 1000 dp)
  with window-dependent page margins (16 / 24 / 32 dp). The generator, folders,
  trash, import/export, entry detail and entry editor were previously
  edge-to-edge on tablet and desktop windows.
- The vault master/detail two-pane layout now activates at 840 dp (the design
  spec breakpoint) instead of 720 dp, and the list pane scales between 320 and
  420 dp instead of a fixed 380 dp.
- The "Clears in …" clipboard snackbar now reflects the configured clear delay
  instead of a hardcoded 30 seconds; copying a secret also gives a light haptic.
- Release builds use the provisioned keystore when `android/key.properties`
  exists and fall back to the debug key only on a fresh clone; `build.sh`
  refuses to publish a debug-signed APK.

### Fixed

- The open-source licenses page no longer shows a stale application version.

### Security

- The v1 vault file layout is frozen behind a byte-exact test fixture, so any
  format change that would strand existing vaults fails CI before it ships.

## [0.11.0] - 2026-11-15

Accessibility pass: a high-contrast theme, reduced-motion support, larger touch
targets and TalkBack labels across the app.

## [0.4.0] - 2026-11-08

Initial vault core: encrypted on-disk format, unlock and biometric quick
unlock, the credential list and the entry editor.
