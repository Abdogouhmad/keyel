# Keyel Roadmap: 0.1.0 → 1.0.0

Each phase is one version. Finish the **Definition of done**, then tag and move on.
Work order inside a phase: read the **Knowledge** section first (you only need the basics), then follow the **Todo** list top to bottom.

```bash
# at the end of every phase
git add -A && git commit -m "feat: <phase name>"
git tag v0.X.0 && git push --tags
```

**Rules for the whole project**
- Crypto code gets tests before it gets UI.
- Never log secrets. Never pass the vault key to Dart.
- One phase = one branch (`phase/0.3-vault-model`), merge when the definition of done is met.
- If a phase takes more than 2x your estimate, cut scope, not quality.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 0.1.0 | Foundation | 2-3 days | ☑ |
| 0.2.0 | Crypto core | 1 week | ☑ |
| 0.3.0 | Vault model and storage | 1 week | ☑ |
| 0.4.0 | Bridge and session | 3-4 days | ☑ |
| 0.5.0 | Adaptive shell and design system | 1 week | ☑ |
| 0.6.0 | Onboarding, unlock, auto-lock | 1 week | ☐ |
| 0.7.0 | Vault UI (CRUD) | 1.5 weeks | ☐ |
| 0.8.0 | Generator and TOTP | 1 week | ☐ |
| 0.9.0 | Security dashboard, backup, import | 1 week | ☐ |
| 0.10.0 | Autofill | 1.5 weeks | ☐ |
| 0.11.0 | Hardening and accessibility | 1 week | ☐ |
| 0.12.0 | Beta (dogfood and polish) | 2 weeks | ☐ |
| 1.0.0 | Release | 3-4 days | ☐ |

Estimates assume part-time work. Adjust to your pace.

> The vault, generator, security and settings screens already exist as
> design-system prototypes running on demo data. They are wired to the real
> vault in phases 0.3 and 0.4; do not treat the 0.5/0.7/0.8 rows as complete
> until that wiring lands.

---

## 0.1.0: Foundation

**Goal:** a Flutter app that calls a Rust function on a real Android device, with CI and theme tokens in place.

### Knowledge
- Rust basics: ownership, `Result`, modules, `cargo` workspaces (The Rust Book, chapters 1-10).
- How flutter_rust_bridge (FRB) works: Rust `pub fn` in `src/api/` → generated Dart bindings.
- Android NDK and Rust targets (`aarch64-linux-android`, etc.).
- Material 3 color roles and `ColorScheme.fromSeed`.

### Todo
1. Install toolchain: Flutter stable, Rust stable, Android Studio + NDK, `flutter_rust_bridge_codegen`, `cargo-ndk`.
2. `flutter_rust_bridge_codegen create keyel`, set the package id `dev.agouhmad.keyel`, app name "Keyel".
3. Create `crates/keyel_core` (pure Rust lib) and make the bridge crate depend on it (Cargo workspace).
4. Write `generate_password(len)` in `keyel_core` (simple version) and expose it via `rust/src/api/generator.rs`.
5. Run `flutter_rust_bridge_codegen generate`, call it from a test screen, confirm it works on a physical device.
6. Add the folder structure from the plan (empty folders with `.gitkeep`).
7. Add packages: `flutter_riverpod`, `go_router`, `dynamic_color`. Add lints (`very_good_analysis`).
8. Create `ui/theme/` with light/dark `ColorScheme` from the design spec hex values, typography (bundle Roboto Flex and JetBrains Mono), and shape tokens.
9. Install the icon: copy `keyel-icon/res/` into `android/app/src/main/res/`.
10. In the manifest: `allowBackup=false`, remove `INTERNET` permission from release/profile manifests, enable `enableOnBackInvokedCallback`.
11. GitHub Actions: `cargo fmt`, `clippy -D warnings`, `cargo test`, `flutter analyze`, `flutter test`.
12. Write README (what it is, how to build) and pick a license.

### Definition of done
- App launches with the Keyel icon and themed UI; the test screen shows a Rust-generated string.
- CI is green on push.

**Tag:** `v0.1.0`

---

## 0.2.0: Crypto core

**Goal:** a tested Rust library that can create, encrypt, lock and unlock a vault blob. No UI.

### Knowledge
- Symmetric encryption and **AEAD** (what a nonce, tag and AAD are). Why nonces must never repeat.
- **KDFs:** why passwords need Argon2id (memory-hard) and what m/t/p mean (RFC 9106, OWASP Password Storage Cheat Sheet).
- **Key wrapping** and keyslots: the master password protects a random vault key, not the data directly.
- RustCrypto crates: `argon2`, `chacha20poly1305` (XChaCha20), `rand::OsRng`.
- `zeroize` and `secrecy`: wiping secrets from memory.
- Serialization with CBOR (`ciborium`) and why a version number goes in every file format.

### Todo
1. `crypto/kdf.rs`: `derive_kek(master, salt, params) -> Kek` using Argon2id. Wrap results in `Secret`/`Zeroizing`.
2. `crypto/aead.rs`: `seal(key, plaintext, aad) -> (nonce, ciphertext)` and `open(...)` with XChaCha20-Poly1305. Fresh random 24-byte nonce every call.
3. `crypto/keys.rs`: generate a random 32-byte `VaultKey`. `wrap(kek, vault_key)` and `unwrap(...)`.
4. `crypto/recovery.rs`: generate a 256-bit recovery key, encode as base32 groups (`XXXX-XXXX-...`), parse it back, derive a second KEK from it.
5. `format/header.rs`: define the header struct (magic `KYL1`, version, KDF params, salt, keyslots). Serialize it; use the serialized bytes as AAD for the body.
6. `format/codec.rs`: `encode(header, body_plaintext, vault_key) -> Vec<u8>` and `decode(bytes, unlock) -> Result<...>`.
7. Errors with `thiserror`: `WrongPassword`, `Corrupted`, `UnsupportedVersion`. Do not leak which step failed beyond that.
8. Tests:
   - round trip encrypt/decrypt
   - wrong password fails
   - flipping any single byte of header or body fails
   - two encryptions of the same data differ (nonce uniqueness)
   - master and recovery keyslot both unlock
   - re-wrapping the vault key (change master) leaves the body untouched
9. Benchmark Argon2 on your phone. Pick params that take about 500 ms and add a function to tune them.
10. Add a `cargo-fuzz` target `parse_vault` that feeds random bytes to `decode`; run it for 10 minutes.
11. Write `docs/crypto-design.md` (the file layout and flows from the plan).

### Definition of done
- All tests pass; fuzz target runs without panics.
- `docs/crypto-design.md` describes the format precisely enough for someone else to implement it.

**Tag:** `v0.2.0`

---

## 0.3.0: Vault model and storage

**Goal:** the vault data model with search, trash and safe saving to disk. Still no UI.

### Knowledge
- Rust structs/enums with `serde`; modeling `Login | Card | Note` as an enum.
- UUID v7 (time-ordered IDs).
- **Atomic writes:** write temp file → `fsync` → rename. Why this prevents corruption.
- In-memory indexing for search; case-insensitive and diacritic-friendly matching.
- Interior mutability for global state: `Mutex<Option<Session>>`.

### Todo
1. `vault/model.rs`: `Vault`, `Folder`, `Entry`, `EntryBody` (Login, Card, Note), `TotpConfig`, timestamps, `deleted_at`.
2. `vault/store.rs`: `Session` holds `VaultKey`, decrypted `Vault`, and file path. Functions: `create`, `open`, `save`, `lock`.
3. Atomic save with `.tmp` file, `fsync`, rename, and keeping one `.bak` of the previous version.
4. `vault/index.rs`: search by title, username, URL, tags; filter by kind, folder, favorite, has_totp.
5. CRUD: add/update/delete (soft, to trash), restore, purge, purge-after-30-days on unlock.
6. Folders: create, rename, delete (entries move to "No folder"), reorder.
7. `vault/history.rs`: when a password changes, push the old one to `password_history` (cap at 10).
8. Summary DTOs that contain **no secrets**: `EntrySummary { id, kind, title, subtitle, favorite, folder_id, has_totp }`.
9. Format migration scaffold: `migrate(vault, from_version)` with a test for v1 → v1.
10. Tests: CRUD, search cases, trash lifecycle, atomic save under simulated crash (kill between tmp write and rename; vault still opens), password history cap, property test that serialize/deserialize is lossless.

### Definition of done
- A Rust-only CLI test (or integration test) can create a vault, add 1,000 entries, lock, reopen, search and get identical data.
- Corrupting the main file falls back to `.bak`.

**Tag:** `v0.3.0`

---

## 0.4.0: Bridge and session

**Goal:** Dart can create/unlock/lock a real vault through FRB. Minimal debug UI.

### Knowledge
- FRB v2 features: structs/enums as DTOs, `Result` → Dart exceptions, `#[frb(sync)]`, `StreamSink`.
- Riverpod basics: `Provider`, `AsyncNotifier`, `ref.watch`.
- Android app-private storage via `path_provider` (`getApplicationSupportDirectory`).
- Why secrets stay in Rust: Dart strings are immutable and can't be reliably wiped.

### Todo
1. `rust/src/api/session.rs`: `create_vault`, `unlock_with_master`, `unlock_with_recovery`, `lock`, `is_unlocked`, `change_master`.
2. `rust/src/api/entries.rs`: `list_entries`, `get_entry`, `upsert_entry`, `delete_entry`, `restore_entry`, `reveal_field`.
3. `rust/src/api/models.rs`: DTOs mirrored for Dart (`EntrySummary`, `EntryDetail` with masked secrets, `EntryDraft`).
4. Pass the vault path from Dart into `init(path)` on startup.
5. A `lock_events` stream from Rust → Dart (fires when Rust locks itself).
6. Dart: `VaultRepository` wrapping the generated API; `vaultSessionProvider` with states `noVault | locked | unlocked`.
7. Temporary debug screen: create vault, unlock, add entry, list, lock.
8. Regenerate bindings in CI and fail if the generated files are out of date.
9. Test on a physical device: kill the app, relaunch, unlock, data is still there.

### Definition of done
- On a device, you can create a vault with a password, add a few entries, kill the app, reopen, unlock and see them.
- No Rust function returns a password except `reveal_field`.

**Tag:** `v0.4.0`

---

## 0.5.0: Adaptive shell and design system

**Goal:** the navigation, theme and reusable components that every screen will use, adapting to window size.

### Knowledge
- Material 3 Expressive: shape tokens, tonal surfaces, motion (springs, container transform).
- **Window size classes** (Compact < 600, Medium 600-839, Expanded 840-1199, Large 1200+) and canonical layouts (list-detail, supporting pane).
- `MediaQuery.sizeOf`, `LayoutBuilder`, `NavigationBar`, `NavigationRail`, `NavigationDrawer`.
- `go_router` shell routes and redirect guards.
- Edge-to-edge and predictive back on Android 13+.
- `MediaQuery.displayFeatures` for foldable hinges.

### Todo
1. `ui/adaptive/window_size.dart`: `WindowSizeClass` enum + helper `context.windowSize`.
2. `ui/adaptive/adaptive_scaffold.dart`: bottom bar (compact) / rail (medium) / labeled rail (expanded) / drawer (large). Destinations: Vault, Generator, Security, Settings.
3. `ui/adaptive/list_detail.dart`: list pane + detail pane widget; pushes a route on compact, shows side by side on wider screens. Include an empty-detail placeholder.
4. Hinge-aware layout: avoid `DisplayFeature` areas, split panes along the fold.
5. `core/router/`: shell route with the four destinations, plus a guard: locked → `/unlock`, no vault → `/onboarding`.
6. `ui/theme/`: light/dark schemes, dynamic color via `dynamic_color` (fallback to brand scheme), text styles, shape and motion tokens.
7. `ui/design_system/`: `KeyelTextField`, `PasswordField` (reveal), `EntryTile` with shape-avatar, `StrengthMeter`, `SectionCard`, `ActionButtonGroup`, `SnackbarHelper`, `ConfirmDialog`, `AdaptiveSheet` (bottom sheet ↔ side sheet).
8. Entry avatar shapes (cookie, squircle, diamond, circle) chosen by hash of the entry id.
9. Edge-to-edge setup, predictive back opt-in, keyboard shortcuts scaffold (`Shortcuts` + `Actions`).
10. Placeholder screens for all four destinations that respect the three layouts.
11. Widget + golden tests at widths 400, 700 and 1000 dp, in light and dark.
12. Test on: small phone, large phone, foldable emulator (open/closed), tablet emulator.

### Definition of done
- Resizing the emulator (or unfolding) switches between bottom bar, rail and list-detail without losing state.
- Goldens committed for 3 sizes × 2 themes.

**Tag:** `v0.5.0`

---

## 0.6.0: Onboarding, unlock, auto-lock

**Goal:** the full lock lifecycle. Users can create a vault, lock and unlock it with password or fingerprint, and recover access.

### Knowledge
- Android Keystore and **auth-bound keys**; why biometrics unlock a key, not "log you in".
- `biometric_storage` (or `local_auth` + `flutter_secure_storage`) and `BIOMETRIC_STRONG`.
- Flutter app lifecycle (`WidgetsBindingObserver`, `AppLifecycleState`).
- `FLAG_SECURE` and how Android builds the Recents thumbnail.
- Exponential back-off for failed attempts.
- Password strength estimation (`zxcvbn` score 0-4).

### Todo
1. Rust: `estimate_strength(pw) -> Strength` (score + feedback) using `zxcvbn`; expose through FRB.
2. Onboarding flow (4 steps from the design spec): Welcome → Master password → Recovery key → Quick unlock.
3. Master password step: strength meter, confirm field, passphrase suggestion, "Continue" enabled at Good+.
4. Recovery key step: show once, Copy / Save file / Share, "I saved it" checkbox gate.
5. Unlock screen: password field, biometric button, "Forgot password?" link, shake animation on error.
6. Failed attempts: delay doubles after 3 wrong tries (5 s, 10 s, 20 s...), countdown shown.
7. Biometric unlock: Keystore key wraps the vault key (Rust exports wrapped material, Dart stores via `biometric_storage`); invalidate on new fingerprint enrollment; require master password after reboot or every 72 h.
8. Recovery flow: enter recovery key → set new master password → success.
9. Auto-lock controller: timer on `paused` (default 1 min, options immediately/30 s/1/5/15 min), also lock when Rust fires `lock_events`.
10. Platform channel `keyel/platform`: `setSecure(bool)` for `FLAG_SECURE`; hide Recents thumbnail when locked.
11. Lock overlay and "lock now" action in the top bar.
12. Change master password screen.
13. Tests: onboarding widget tests, wrong-password flow, auto-lock timer (fake clock), recovery round trip.

### Definition of done
- Fresh install → onboarding → add entry → background app 2 min → return and find it locked → unlock by fingerprint and by password → forgot-password flow works with the recovery key.
- Recents thumbnail is blank and screenshots are blocked while secure.

**Tag:** `v0.6.0`

---

## 0.7.0: Vault UI (CRUD)

**Goal:** a daily-usable password manager (without generator, 2FA, autofill yet).

### Knowledge
- Riverpod families (`entryDetailProvider(id)`), `AsyncValue` handling.
- Sliver lists, sticky headers, fast scroll for long lists.
- Form validation patterns; unsaved-changes guards (`PopScope`).
- Clipboard on Android 13+: `ClipDescription.EXTRA_IS_SENSITIVE`, auto-clear timers.
- `url_launcher` for opening websites.

### Todo
1. Vault home: large app bar, search bar, filter chips, grouped list (Favorites, then A-Z), swipe actions (copy, favorite), long-press selection mode.
2. Search view with highlighted matches, recent searches (in memory only).
3. Entry detail: Login (credentials card, masked password with Reveal/Copy button group, URL open, notes, details), Card (flip-card visual), Note.
4. Reveal behavior: shows for 15 s then re-masks; mono font with colored characters.
5. Add/Edit forms for Login, Card, Note, with the kind selector, folder picker, favorite, validation and discard dialog.
6. Platform channel: `copySensitive(text)` + auto-clear timer (setting: 15 s / 30 s / 1 min / never) with snackbar "Copied. Clears in 30 s."
7. Folders screen: list, create/rename/delete, filter vault by folder.
8. Favorites filter and Trash screen (restore, delete forever, empty trash, 30-day notice).
9. Selection mode actions: favorite, move to folder, delete.
10. Empty states, no-results states, shimmer loading, error states (from the design spec).
11. Adaptive: list-detail on medium+, two-column edit form on expanded, keyboard shortcuts (Ctrl+F, Ctrl+N, Ctrl+C).
12. Undo snackbar on delete.
13. Tests: widget tests for list/detail/edit at three widths; integration test for add → search → edit → delete → restore.

### Definition of done
- You can use Keyel to store your real accounts (as a test copy) for a few days without hitting a blocker.
- Detail pane updates without navigation on tablet.

**Tag:** `v0.7.0`

---

## 0.8.0: Generator and TOTP

**Goal:** a good password/passphrase generator and working two-factor codes.

### Knowledge
- Secure random generation: use `OsRng`, avoid modulo bias (use rejection sampling).
- Passphrases and wordlists (EFF long wordlist, 7776 words), entropy = words × log2(7776).
- TOTP (RFC 6238) and HOTP (RFC 4226): HMAC-SHA1/256/512, 30 s period, 6-8 digits, base32 secrets.
- `otpauth://` URI format.
- `mobile_scanner` for QR scanning on Android and camera permissions.

### Todo
1. Rust `generator.rs`: password options (length 8-64, upper/lower/digits/symbols, exclude ambiguous, minimum digits/symbols) with bias-free selection; passphrase options (3-10 words, separator, capitalize, add number). Bundle the EFF wordlist.
2. Unit tests: length, charset guarantees, minimum counts, no ambiguous chars when excluded, statistical sanity test.
3. Rust `totp.rs`: parse `otpauth://`, generate codes, `seconds_left`. Test with RFC 6238 vectors.
4. Expose `generate_password`, `generate_passphrase`, `current_code`, `parse_otpauth`.
5. Generator tab UI: result card, regenerate, copy, mode toggle, length slider, switches, strength meter. Remember last options.
6. Generator as bottom sheet inside Add/Edit ("Use this password"); on expanded layouts show it as the supporting pane.
7. TOTP UI: live code with countdown ring on entry detail; Copy button; code refresh via ticker (not polling Rust every frame).
8. QR scan screen with permission rationale, flashlight toggle, error state, manual-entry fallback.
9. Add 2FA field to the Login form (scan or type base32 key, validate).
10. Tests: generator widget tests, TOTP ticker test with fake time, scan flow with mocked scanner.

### Definition of done
- Adding a real 2FA account by QR produces codes that your real login accepts.
- Generator output is covered by tests and options persist.

**Tag:** `v0.8.0`

---

## 0.9.0: Security dashboard, backup, import

**Goal:** vault health insights and the ability to move data in and out safely.

### Knowledge
- Password health heuristics: weak (zxcvbn ≤ 1), reused (same hash across entries, compared in Rust only), old (> 12 months), missing 2FA on common sites, `http://` URLs.
- Encrypted backup design: reuse the vault format with a *separate* backup password.
- CSV parsing quirks (quotes, commas, UTF-8 BOM); Bitwarden export formats; Chrome password CSV.
- Android Storage Access Framework (`file_picker`, `share_plus`) instead of broad storage permissions.

### Todo
1. Rust `health.rs`: `analyze()` returns weak, reused, old, no-2FA, insecure-URL lists. Reused detection compares salted hashes in memory, never exposes passwords.
2. Security dashboard UI: score ring, 2×2 (or 4×1) issue cards, filtered lists with a "Fix" action that opens edit with the generator.
3. Perfect-score state.
4. Rust `backup.rs`: `export_encrypted(path, password)` and `import_encrypted(path, password, Merge | Replace)`.
5. Export UI with password + strength meter, success sheet with Share.
6. CSV import for Bitwarden and Chrome: parse, map fields, preview counts, de-duplicate (same title + username + URL), Merge/Replace option, import report.
7. Optional: unencrypted CSV export behind a red warning dialog and explicit confirmation. Delete the temp file after sharing.
8. Tests: health analysis fixtures, backup round trip, import of a 1,000-row CSV, malformed CSV handling, duplicate detection.

### Definition of done
- Export → wipe app data → import restores every field exactly.
- Importing your real Bitwarden/Chrome export works and the dashboard shows sensible numbers.

**Tag:** `v0.9.0`

---

## 0.10.0: Autofill

**Goal:** Keyel can fill credentials in other apps and Chrome. This is the hardest phase; take it slowly.

### Knowledge
- Android Autofill Framework: `AutofillService`, `AssistStructure`, `ViewNode`, `FillResponse`, `Dataset`, authentication intents, `SaveInfo`.
- Autofill hints (`AUTOFILL_HINT_USERNAME`, `_PASSWORD`), `inputType` and HTML attributes for web.
- Package and **web domain** matching, Digital Asset Links, why matching by title or loose substring is dangerous.
- Activities launched from a service and returning results via `setResult`.
- Running Flutter in a second `FlutterActivity` / cached engine for the picker.

### Todo
1. Manifest: declare `KeyelAutofillService` with `BIND_AUTOFILL_SERVICE` and `autofill_service_config.xml`.
2. `FieldParser.kt`: walk the `AssistStructure`, find username/password/email fields, collect `packageName` and `webDomain`.
3. `DomainMatcher.kt`: match by exact package for apps; by registrable domain (public suffix list) for web; flag mismatches.
4. Locked or any-match flow: return a `FillResponse` with an authentication `IntentSender` pointing to `AuthActivity`.
5. `AuthActivity` hosts the Flutter `autofill_picker` route (separate Flutter entrypoint): unlock (biometric/master) → matches → user picks → return a `Dataset`.
6. Rust `find_matches(package, web_domain)` and expose through FRB.
7. Picker UI (design spec 8.20): bottom-sheet style, target app/site header, entry list, "Search vault", "Create new login", mismatch warning banner.
8. Save flow: `SaveInfo` + `onSaveRequest` opens the picker in "Save new login" mode with prefilled fields; "Never for this site" list.
9. Settings screen "Autofill": status card, button that opens `ACTION_REQUEST_SET_AUTOFILL_SERVICE`, toggles for ask-to-save and match mode.
10. Handle edge cases: fields not detected, apps that block autofill, multiple accounts, compat mode for browsers.
11. Optional: inline suggestions for the keyboard (Android 11+).
12. Manual test matrix: Chrome, Firefox, 3 native apps (e.g. social, banking-style login, a game), a WebView app, split screen.

### Definition of done
- Fill works in Chrome and at least 3 native apps; saving a new login works; a phishing-style domain mismatch shows the warning.

**Tag:** `v0.10.0`

---

## 0.11.0: Hardening and accessibility

**Goal:** make it safe and usable for everyone before real users touch it.

### Knowledge
- OWASP MASVS (Mobile Application Security Verification Standard), storage and crypto sections.
- Android release build: R8/ProGuard, signing, `minifyEnabled`, keep rules for FRB.
- `cargo audit`, `cargo deny`, reproducible builds with `Cargo.lock`.
- TalkBack basics: semantics labels, focus order, `Semantics` widget.
- Text scaling, contrast, RTL layout in Flutter.

### Todo
1. Walk through the **hardening checklist** in the plan; tick every item or document why not.
2. Verify no secrets appear in logs: grep for `print`, `debugPrint`, `println!`; use `adb logcat` while exercising every flow.
3. Check memory handling: confirm `zeroize` on lock; review all `.clone()` and `String` copies of secrets in Rust.
4. Dump the app's private storage via `adb run-as` (debug build) and confirm there's no plaintext anywhere, including settings and caches.
5. Confirm `allowBackup=false` and test that `adb backup` returns nothing.
6. R8 + release build; test the release APK fully (FRB and autofill often break only in release).
7. `cargo audit` and `cargo deny` in CI (fail on advisories). Pin dependencies.
8. Run the vault parser fuzzer for 1 hour+; add found crashes as regression tests.
9. TalkBack pass on every screen: labels on icon buttons, masked-password announcement, focus order.
10. Test at 200 % font scale; fix overflows. Test high-contrast theme and reduce-motion setting.
11. RTL pass (Arabic): Vault home, Entry detail, forms; add `app_ar.arb` and `app_fr.arb` strings.
12. Performance: 5,000-entry vault; list scroll at 60 fps, cold unlock under ~1.5 s on a mid-range phone.
13. Review `docs/crypto-design.md` and `docs/threat-model.md`; ask a security-minded friend or a public forum to review them.

### Definition of done
- Checklist complete, release build verified, TalkBack usable, no plaintext on disk, fuzzing clean.

**Tag:** `v0.11.0`

---

## 0.12.0: Beta

**Goal:** prove it with real daily use and fix what hurts.

### Knowledge
- Play Console internal/closed testing tracks, or GitHub Releases + F-Droid metadata.
- Crash reporting without network: local log export that excludes secrets (user shares manually).
- Writing a good changelog and release notes.

### Todo
1. Migrate your **real** accounts into Keyel (keep your old manager until the end of the beta).
2. Use it as your daily manager for 2 weeks; write down every friction point in an `ISSUES.md`.
3. Add a "Report a problem" action that exports a redacted debug bundle (versions, device info, no secrets).
4. Fix all data-loss and crash bugs first, then UX issues, then polish.
5. Polish pass using the design spec: motion, haptics, empty states, copy text, icons.
6. Test upgrade path: install an older tag, create data, install the newer APK over it, confirm vault opens (format migration).
7. Test on at least 3 real devices and Android versions (e.g. 10, 13, latest) plus tablet and foldable emulators.
8. Recruit 3-5 testers (friends, open-source community); give them a short feedback form.
9. Write user docs: README quick start, FAQ ("What if I forget my master password?"), backup advice.
10. Prepare store assets: screenshots (phone, 7"/10" tablet), feature graphic, short and full descriptions (EN/FR/AR), privacy policy ("no data leaves your device").

### Definition of done
- Two weeks of daily use with **zero** data loss, no known crashes, and tester feedback addressed.

**Tag:** `v0.12.0` (and `v1.0.0-rc.1` when ready)

---

## 1.0.0: Release

**Goal:** ship it.

### Knowledge
- Android app signing (upload key vs app signing key), keeping the keystore safe and backed up (offline!).
- Play Console requirements (data safety form, target API level) or F-Droid inclusion process and reproducible builds.
- Semantic versioning, changelogs, security disclosure policy (`SECURITY.md`).

### Todo
1. Final dependency update and `cargo audit` / `flutter pub outdated` check.
2. Bump `version: 1.0.0+1` in `pubspec.yaml`; update `CHANGELOG.md`.
3. Generate the release signing key; back it up in two offline places. Never commit it.
4. Build signed AAB (Play) and APK (GitHub/F-Droid); publish SHA-256 checksums.
5. Add `SECURITY.md` (how to report vulnerabilities), `CONTRIBUTING.md`, license headers.
6. Publish `docs/crypto-design.md` and `docs/threat-model.md` in the repo.
7. Submit to your chosen channels (Play, GitHub Releases, F-Droid).
8. Tag `v1.0.0`, write the release notes, announce (portfolio, X/LinkedIn, r/androiddev, r/selfhosted).
9. Add the app to your portfolio and personal app store.

### Definition of done
- Signed release is installable from the chosen store/channel and passes a fresh-install smoke test.

**Tag:** `v1.0.0`

---

## After 1.0 (ideas, in rough order)

| Version | Idea |
|---|---|
| 1.1 | Quick Settings tile (lock), app shortcut (generator), widgets |
| 1.2 | Passkeys via Credential Manager (Android 14+) |
| 1.3 | Optional breach check (HIBP k-anonymity) behind explicit opt-in |
| 2.0 | End-to-end encrypted sync with a Rust server (reuse the vault format; server only stores ciphertext) |
| 2.1 | Wear OS companion for TOTP |
| 2.2 | Desktop client (the Rust core is reusable) |

---

## Appendix: learning resources (search by name)

- **Rust:** The Rust Book; Rust by Example; "Rustlings" exercises.
- **flutter_rust_bridge:** official documentation and the `create`/`integrate` quick start.
- **Crypto:** RustCrypto organization docs (`argon2`, `chacha20poly1305`); RFC 9106 (Argon2); OWASP Password Storage and Cryptographic Storage cheat sheets; Bitwarden Security Whitepaper (good real-world reference design).
- **TOTP:** RFC 4226, RFC 6238.
- **Android:** Autofill Framework guide on developer.android.com; Biometric and Keystore guides; Credential Manager docs.
- **Flutter:** Riverpod docs; go_router docs; Material 3 and Material 3 Expressive guidelines; Flutter adaptive/responsive design guide.
- **Security:** OWASP MASVS and MASTG.
