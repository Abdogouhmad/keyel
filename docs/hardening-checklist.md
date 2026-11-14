# Keyel hardening checklist — status

Phase 0.11.0 audit, dated 2026-11-14. This maps the plan's security checklist
(`docs/plan.md` §11) and the roadmap's 0.11 todos (`docs/roadmap.md`) to what is
actually implemented, with evidence and what is still open. Items that need a
physical device are marked **device-pending** and are not claimed as done.

Legend: ✅ done · 🟡 partial · ⏳ open · 📱 device-pending.

## Plan §11 checklist

| # | Item | Status | Evidence / notes |
|---|---|---|---|
| 1 | `FLAG_SECURE` on secret screens | ✅ 📱 | `MainActivity.kt` `setSecure`; enabled at startup in `lib/main.dart` and `lib/main_autofill.dart`. Always-on rather than a setting (stronger); per-screen verification is device-pending. |
| 2 | Recents thumbnail hidden when locked | ✅ 📱 | `FLAG_SECURE` blanks the Recents thumbnail; verify on device. |
| 3 | Sensitive clipboard flag + auto-clear | 🟡 | `lib/core/platform/sensitive_clipboard.dart` flags the clip sensitive on Android 13+ and clears after a timeout (default 30 s). The 15 s / 1 min / never options are **not** wired to a setting yet. |
| 4 | Wrong attempts: exponential delay (not a wipe) | ⏳ | **Not implemented.** `unlockWithMaster` reports a wrong password immediately. See `docs/threat-model.md` T9. |
| 5 | Biometric requires `BIOMETRIC_STRONG` | ✅ | `BiometricAuth._isStrong` rejects Class-2 modalities; the OS `BiometricPrompt` performs the check. |
| 6 | No secrets in logs; release strips prints | ✅ | No `println!`/`eprintln!`/`dbg!`/`log::` in Rust; the only Dart log is `lib/main.dart:41` (a storage error, no secret). Release can strip Dart symbols with `build.sh --obfuscate`. |
| 7 | R8 minify + ProGuard rules for FRB | ✅ | Flutter enables R8 + resource shrinking for release; `android/app/proguard-rules.pro` pins the autofill components and the native surface. See `docs/DECISIONS.md` (2026-11-14). |
| 8 | `cargo audit` + `cargo deny` in CI | ✅ | `security` job in `.github/workflows/ci.yml`; `deny.toml` allow-lists licences. |
| 9 | Reproducible Rust build | 🟡 | `Cargo.lock` is committed and used. An exact toolchain pin is **not** in place (no `rust-toolchain.toml`); CI follows `stable`. |
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
| 9 | TalkBack pass on every screen | ⏳ 📱 | Accessibility chunk not started (deferred by scope). |
| 10 | 200 % font scale, high contrast, reduce motion | ⏳ | Deferred. |
| 11 | RTL (Arabic) pass + `app_ar.arb`/`app_fr.arb` | ⏳ | l10n not started; `lib/l10n/` is empty. |
| 12 | Performance: 5,000-entry vault benchmark | ⏳ | Not started. |
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

## Recommended next hardening steps

1. Wrong-attempt exponential delay (T9): a small, testable Dart throttle plus a
   persisted `failedAttempts`/`lockedUntil` in `settings.json`, wired into
   `UnlockPasswordForm`.
2. Clipboard-timeout setting (15 s / 30 s / 1 min / never) in Settings.
3. Exact Rust toolchain pin (`rust-toolchain.toml`) once a version is chosen.
4. On-device verification sweep (items 2, 4, 5, 6, 9).
