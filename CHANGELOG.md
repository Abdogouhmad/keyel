# Changelog

All notable changes to Keyel are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
