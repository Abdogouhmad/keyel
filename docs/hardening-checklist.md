# Keyel hardening checklist — status

Phase 0.11.0 audit, opened 2026-11-14, extended 2026-11-15 with the
accessibility chunk and **closed on 2026-11-15**. This maps the plan's security
checklist (`docs/plan.md` §11) and the roadmap's 0.11 todos
(`docs/roadmap.md`) to what is actually implemented, with evidence and what is
still open. Items that need a physical device are marked **device-pending** and
are not claimed as done; the phase is closed with those device checks and
localization (item 11) explicitly carried past it.

Legend: ✅ done · 🟡 partial · ⏳ open · 📱 device-pending.

## Plan §11 checklist

| # | Item | Status | Evidence / notes |
|---|---|---|---|
| 1 | `FLAG_SECURE` on secret screens | ✅ 📱 | `MainActivity.kt` `setSecure`; enabled at startup in `lib/main.dart` and `lib/main_autofill.dart`. Always-on rather than a setting (stronger); per-screen verification is device-pending. |
| 2 | Recents thumbnail hidden when locked | ✅ 📱 | `FLAG_SECURE` blanks the Recents thumbnail; verify on device. |
| 3 | Sensitive clipboard flag + auto-clear | ✅ | `lib/core/platform/sensitive_clipboard.dart` flags the clip sensitive on Android 13+ and clears after the delay from `AppPreferences.clipboardClearDelay`. The user picks 15 s / 30 s / 1 min / never in Settings (`settings_screen.dart`); the choice is persisted in `settings.json`. |
| 4 | Wrong attempts: exponential delay (not a wipe) | ✅ | `lib/core/security/unlock_throttle.dart`: 3 free tries, then 1/2/4/8/16 s capped at 30 s, persisted in `settings.json` and applied to password and biometric unlock; `UnlockPasswordForm` shows a countdown. Never wipes. See `docs/threat-model.md` T9. |
| 5 | Biometric requires `BIOMETRIC_STRONG` | ✅ | `BiometricAuth._isStrong` rejects Class-2 modalities; the OS `BiometricPrompt` performs the check. |
| 6 | No secrets in logs; release strips prints | ✅ | No `println!`/`eprintln!`/`dbg!`/`log::` in Rust; the only Dart log is `lib/main.dart:41` (a storage error, no secret). Release can strip Dart symbols with `build.sh --obfuscate`. |
| 7 | R8 minify + ProGuard rules for FRB | ✅ | Flutter enables R8 + resource shrinking for release; `android/app/proguard-rules.pro` pins the autofill components and the native surface. See `docs/DECISIONS.md` (2026-11-14). |
| 8 | `cargo audit` + `cargo deny` in CI | ✅ | `security` job in `.github/workflows/ci.yml`; `deny.toml` allow-lists licences. |
| 9 | Reproducible Rust build | ✅ | `Cargo.lock` is committed and used; `rust-toolchain.toml` pins the compiler to 1.97.0 (with `rustfmt` + `clippy`), and CI installs the matching `dtolnay/rust-toolchain@1.97.0`. The fuzz crate overrides the pin with nightly. |
| 10 | Constant-time comparisons where relevant | ✅ | Secret comparisons happen inside the audited AEAD (constant-time tag check). Keyel's own equality checks compare non-secret user input only. |
| 11 | Vault parser fuzzed 1 h+ nightly | ✅ | `.github/workflows/fuzz.yml` runs `cargo fuzz run parse_vault -- -max_total_time=3600` nightly. |
| 12 | Independent review of crypto design before 1.0 | ⏳ | Not done; scheduled before 1.0. |

## Roadmap 0.11 todos

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Walk the hardening checklist | ✅ | This document. |
| 2 | Verify no secrets in logs | 🟡 📱 | Source audit done (item 6); `adb logcat` sweep on device pending. |
| 3 | Check memory handling / `zeroize` on lock | ✅ | Audited; bridge secret params now wrapped in `Zeroizing`; `zeroize_secrets` test added. See `docs/threat-model.md` T4. |
| 4 | Dump private storage via `adb run-as` | 📱 | Needs a device. |
| 5 | Confirm `allowBackup=false`, `adb backup` empty | 🟡 📱 | Manifest sets `allowBackup="false"`; `build.sh` enforces it on every release APK. Device test pending. |
| 6 | R8 + release build, test release APK | 🟡 📱 | Release APK builds with R8 on; keep rules added. Full functional test on device pending. |
| 7 | `cargo audit` + `cargo deny` in CI | ✅ | See plan item 8. |
| 8 | Run the parser fuzzer 1 h+ | ✅ | Nightly workflow. A local multi-hour soak is still worthwhile. |
| 9 | TalkBack pass on every screen | 🟡 📱 | Code-level pass done (2026-11-15): every icon button now carries a `tooltip`/`semanticLabel` (password reveal toggles in onboarding, create-vault, recovery-reset and unlock previously announced as unlabelled buttons); nav destinations and pressable surfaces expose `Semantics`; secret fields stay `obscureText` so TalkBack never reads the value. The screen-by-screen TalkBack sweep still needs a device. |
| 10 | 200 % font scale, high contrast, reduce motion | 🟡 | High contrast and reduce motion done (2026-11-15): `KeyelTheme.highContrast`/`highContrastBuilder` honour `MediaQuery.highContrastOf` on every route and sheet, and `KeyelMotion.resolve` collapses every animation to instant when `MediaQuery.disableAnimationsOf` is set. 200 % font scale: the vulnerability-summary grid no longer clips its own tiles (it relaxes to one column past 1.4× and grows the tile extent with the text scale), and `VaultRow` grows with the text scale instead of clipping its title/subtitle. Regression tests assert no overflow on the security dashboard, the adaptive shell, the autofill picker/save, the import/export screen and the vault list; the entry detail/edit screens are scrollable and reflow. Remaining: the visual sweep on a real device at 200 %. |
| 11 | RTL (Arabic) pass + `app_ar.arb`/`app_fr.arb` | ⏳ | Deferred past 0.11 at the user's request (see `docs/DECISIONS.md`, 2026-11-15); `lib/l10n/` is empty and no `flutter_localizations`/`.arb` scaffolding exists yet. |
| 12 | Performance: 5,000-entry vault benchmark | ✅ 📱 | Rust: `five_thousand_entry_vault_stays_within_budget` (`crates/keyel_core/tests/vault_model.rs`) builds/saves/opens/searches/filters 5,000 entries under loose ceilings that catch O(n²). Dart: `test/vault_list_perf_test.dart` proves `VaultEntryList` stays lazy (the `SliverList.list` → `SliverList.builder` fix in `lib/features/vault/widgets/vault_entry_list.dart`). On-device scroll fps and cold-unlock timing pending. |
| 13 | Review crypto-design + threat-model docs | 🟡 | `docs/threat-model.md` written; external review pending. |

## What this chunk changed

- `rust/src/api/session.rs`, `rust/src/api/import_export.rs`: master password,
  recovery key and backup password arguments are wiped with `Zeroizing`.
- `crates/keyel_core/src/vault/model.rs`: test proving `zeroize_secrets` clears
  every secret field (password, history, TOTP, card number/CVV, note).
- `android/app/proguard-rules.pro`: R8 keep rules; documented that Flutter
  drives `isMinifyEnabled`/`isShrinkResources`.
- `.github/workflows/ci.yml`: new `security` job (`cargo audit`, `cargo deny`).
- `.github/workflows/fuzz.yml`: nightly one-hour parser fuzz.
- `docs/threat-model.md`: initial threat model.
- Wrong-attempt exponential delay (plan item 4 / T9):
  `lib/core/security/unlock_throttle.dart`; persisted `unlockFailures` /
  `unlockLockedUntilMs` in `lib/data/app_preferences.dart`; enforced in
  `VaultSessionNotifier.unlockWithMaster`; countdown in
  `lib/features/vault/widgets/unlock_password_form.dart`; tests in
  `test/unlock_throttle_test.dart`, `test/vault_session_provider_test.dart`
  and `test/app_preferences_test.dart`.
- Clipboard-timeout setting (plan item 3): persisted
  `clipboardClearSeconds` in `lib/data/app_preferences.dart`; `SensitiveClipboard`
  honours it; Settings offers 15 s / 30 s / 1 min / never; tests in
  `test/sensitive_clipboard_test.dart` and `test/app_preferences_test.dart`.
- Performance (roadmap item 12): `VaultEntryList` switched from eager
  `SliverList.list` to lazy `SliverList.builder`
  (`lib/features/vault/widgets/vault_entry_list.dart`), so a 5,000-entry vault
  no longer inflates every row on first paint; `test/vault_list_perf_test.dart`
  asserts only a window of rows is built. Rust adds a 5,000-entry regression
  test with generous ceilings (guards O(n²)) and an ignored production-KDF
  timing test.
- Reproducible toolchain (plan item 9): `rust-toolchain.toml` pins Rust 1.97.0
  (`rustfmt` + `clippy`); CI installs the matching
  `dtolnay/rust-toolchain@1.97.0`; the fuzz crate overrides the pin with nightly
  (`crates/keyel_core/fuzz/rust-toolchain.toml`).

### Accessibility chunk (2026-11-15)

- `lib/ui/theme/keyel_theme.dart`: `KeyelMotion.resolve` returns
  `Duration.zero` when the platform asks for reduced motion, and
  `KeyelTheme.highContrast` / `KeyelTheme.highContrastBuilder` raise the
  low-emphasis text, outline and divider roles when
  `MediaQuery.highContrastOf` is set. `lib/main.dart` and
  `lib/main_autofill.dart` install the builder in `MaterialApp.builder` so
  every route, dialog and sheet inherits it.
- Reduce motion is applied at every animated site: `PressableScale`, the
  navigation shell (`keyel_shell.dart`), chips, the search field, the action
  button group, the unlock view switcher and the onboarding transitions.
- Icon-button labels for TalkBack: password reveal toggles in
  `master_password_step.dart`, `create_vault_view.dart`,
  `recovery_reset_view.dart` and `unlock_password_form.dart` now carry a
  `tooltip` (announced as the button's label), matching the design system's
  other icon buttons.
- `test/accessibility_test.dart`: unit + widget coverage for
  `KeyelMotion.resolve`, `KeyelTheme.highContrast`, the builder and
  `PressableScale` under both motion settings.
- 200 % font scale: `VulnerabilitySummarySection` replaced its fixed
  `childAspectRatio` grid with a `mainAxisExtent` grid that grows with the text
  scale and drops to a single column past 1.4×, fixing a real `IssueCard`
  overflow; `IssueCard` titles now ellipsize at two lines; `VaultRow` grows its
  height with the text scale instead of clipping its title/subtitle. New
  no-overflow regression tests in `test/security_screen_layout_test.dart`,
  `test/adaptive_shell_test.dart`, `test/autofill_picker_screen_test.dart`,
  `test/autofill_save_screen_test.dart`, `test/import_export_screen_test.dart`
  and `test/vault_list_perf_test.dart`.
- `pubspec.yaml`: version bumped to `0.11.0+1` for the phase.

## Recommended next hardening steps

1. On-device verification sweep (items 2, 4, 5, 6, 9, 12).
