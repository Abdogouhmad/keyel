# Keyel: Project Plan (A to Z)

> **Keyel** = *key* + *-el* (as in pixel, voxel). An offline-first, privacy-first password manager for Android.
> Rust core for all crypto and storage. Flutter UI, adaptive across phones, foldables and tablets.
> Package id (change if you like): `com.freesoftware.keyel`

---

## 1. Vision and scope

**One line:** a vault that never leaves your device unless you decide it should, and looks like it belongs on a Pixel.

**Principles**
1. **Offline first.** No account, no server, no analytics, no network permission in v1.
2. **Secrets live in Rust.** Dart never holds the vault key or the master password longer than one call.
3. **Boring crypto.** Audited crates only. No custom primitives.
4. **Pixel philosophy.** Material 3 Expressive, Material You dynamic color, calm and helpful, large touch targets, fluid motion.
5. **Adaptive by default.** Every screen has compact, medium and expanded layouts from day one.

**v1 features**
- Master password + recovery key, biometric unlock
- Entries: Login, Card, Secure note (TOTP inside Login)
- Folders, favorites, trash (30 days), search
- Password and passphrase generator
- Security dashboard (weak, reused, old, missing 2FA)
- Android Autofill service
- Encrypted backup export/import, CSV import (Bitwarden, Chrome)
- Auto-lock, clipboard auto-clear, screenshot blocking

**Non-goals for v1:** cloud sync, browser extension, iOS, sharing, passkeys (stretch, see section 15).

---

## 2. Threat model (short)

| Threat | Mitigation |
|---|---|
| Stolen phone, device locked | Vault file encrypted at rest (XChaCha20-Poly1305), key wrapped by Argon2id-derived KEK |
| Stolen phone, device unlocked | App auto-lock, master password or biometric to open |
| Brute-force of vault file | Argon2id with tuned cost (target about 500 ms on a mid-range phone) |
| Malicious app reading clipboard | Mark clip as sensitive (Android 13+), auto-clear after 30 s |
| Screenshots / screen recording / recents | `FLAG_SECURE`, blank recents thumbnail |
| Cloud backup leaking vault | `allowBackup=false`, data-extraction rules exclude vault |
| Memory scraping | `zeroize` + `secrecy`, key held only in Rust, locked on background timeout |
| Malicious autofill target | Match by verified package + web domain (Digital Asset Links), confirm on mismatch |

Out of scope: rooted device with a live attacker, malware with accessibility permission, hardware attacks.

---

## 3. Architecture

```
+---------------------------- Flutter (Dart) ----------------------------+
|  UI (adaptive)  ->  Riverpod providers  ->  Repository (thin)           |
+-------------------------------|-----------------------------------------+
                                | flutter_rust_bridge (FRB v2)
+-------------------------------v-----------------------------------------+
|  Rust core: keyel_core                                                  |
|  api/ (exposed)  ->  vault (state, locking)  ->  crypto, storage, totp  |
+-------------------------------|-----------------------------------------+
                                | file I/O
                      app-private storage: vault.keyel (encrypted blob)

Android side (Kotlin): AutofillService, clipboard flags, FLAG_SECURE,
Keystore-bound biometric key (via biometric_storage), quick tile (optional)
```

**Key rule:** Rust exposes *commands* and returns *display models*. Passwords are returned only when the user reveals or copies them (`reveal_password(id)`), never in list calls.

---

## 4. Tech stack and packages

### Flutter / Dart
| Purpose | Package |
|---|---|
| Rust bridge | `flutter_rust_bridge` |
| State management | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` |
| Routing | `go_router` |
| Dynamic color | `dynamic_color` |
| Biometrics + Keystore-bound storage | `biometric_storage` (fallback: `local_auth` + `flutter_secure_storage`) |
| QR scan (TOTP) | `mobile_scanner` |
| Share / export | `share_plus`, `file_picker`, `path_provider` |
| Haptics, clipboard | built-in `HapticFeedback`, platform channel for sensitive-clip flag |
| Localization | `flutter_localizations`, `intl` (ARB files) |
| Testing | `flutter_test`, `integration_test`, `mocktail`, `golden_toolkit` (or built-in goldens) |
| Lints | `flutter_lints` or `very_good_analysis` |

Fonts (bundled, no network): **Roboto Flex** (UI), **JetBrains Mono** (passwords, codes).
Material 3 Expressive: check current Flutter support. If a component is missing (button groups, wavy progress, shape morphing), build it yourself in `ui/design_system/`.

### Rust crates (`keyel_core`)
| Purpose | Crate |
|---|---|
| KDF | `argon2` (Argon2id) |
| AEAD | `chacha20poly1305` (XChaCha20-Poly1305) |
| Key derivation helpers | `hkdf`, `sha2` |
| RNG | `rand` (`OsRng`) |
| Memory hygiene | `zeroize`, `secrecy` |
| Serialization | `serde`, `ciborium` (CBOR) or `postcard` |
| Errors | `thiserror` |
| IDs, time | `uuid` (v7), `time` |
| TOTP | `totp-rs` (with `otpauth` feature) or `hmac` + `sha1` + `data-encoding` |
| Password strength | `zxcvbn` |
| Sync primitives | `parking_lot` (Mutex/RwLock), `once_cell` |
| Bridge | `flutter_rust_bridge` |
| Dev | `proptest`, `criterion` (optional), `cargo-fuzz` for the parser |

**Storage decision:** a single encrypted vault file (not SQLCipher). SQLCipher needs OpenSSL cross-compilation on Android, which is painful, and a personal vault of a few thousand entries loads instantly in memory. Search runs on the decrypted in-memory index.

---

## 5. Folder structure

```
keyel/
├── README.md
├── LICENSE
├── pubspec.yaml
├── flutter_rust_bridge.yaml
├── analysis_options.yaml
├── .github/workflows/ci.yml
├── docs/
│   ├── plan.md                 # this file
│   ├── design.md               # for Google Stitch
│   ├── crypto-design.md        # public spec of the vault format
│   └── threat-model.md
├── rust/                       # Rust workspace root for the bridge crate
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── frb_generated.rs    # generated
│       └── api/                # ONLY these are exposed to Dart
│           ├── mod.rs
│           ├── session.rs      # create, unlock, lock, change_master
│           ├── entries.rs      # CRUD, search, trash, favorites
│           ├── generator.rs    # passwords and passphrases
│           ├── totp.rs
│           ├── health.rs       # security dashboard
│           ├── backup.rs       # export/import, CSV import
│           └── models.rs       # DTOs sent to Dart
├── crates/
│   └── keyel_core/             # pure Rust, no FRB, fully unit-tested
│       ├── Cargo.toml
│       ├── src/
│       │   ├── lib.rs
│       │   ├── crypto/         # kdf.rs, aead.rs, keys.rs, recovery.rs
│       │   ├── format/         # header.rs, codec.rs, migrate.rs
│       │   ├── vault/          # model.rs, store.rs, index.rs, history.rs
│       │   ├── totp.rs
│       │   ├── generator.rs
│       │   ├── health.rs
│       │   ├── import/         # bitwarden.rs, chrome_csv.rs
│       │   └── error.rs
│       ├── tests/              # integration + known-answer tests
│       └── fuzz/               # cargo-fuzz targets
├── lib/
│   ├── main.dart
│   ├── app.dart                # MaterialApp.router, theme, locale
│   ├── core/
│   │   ├── router/             # go_router config, guards (locked -> unlock)
│   │   ├── platform/           # MethodChannel wrappers (clipboard, secure flag)
│   │   ├── security/           # auto-lock controller, lifecycle observer
│   │   └── utils/
│   ├── src/rust/               # generated FRB bindings
│   ├── data/
│   │   ├── vault_repository.dart
│   │   └── settings_repository.dart   # SharedPreferences-free: small JSON in app dir
│   ├── features/
│   │   ├── onboarding/
│   │   ├── unlock/
│   │   ├── vault/              # list, search, filters, selection
│   │   ├── entry/              # detail, edit, types (login/card/note)
│   │   ├── generator/
│   │   ├── folders/
│   │   ├── trash/
│   │   ├── security_dashboard/
│   │   ├── totp/
│   │   ├── import_export/
│   │   ├── autofill_picker/    # UI launched by the AutofillService
│   │   └── settings/
│   ├── ui/
│   │   ├── theme/              # color schemes, typography, shapes, motion tokens
│   │   ├── adaptive/           # window size classes, scaffold, panes
│   │   └── design_system/      # buttons, fields, list tiles, sheets, chips
│   └── l10n/                   # app_en.arb, app_fr.arb, app_ar.arb
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/com/freesoftware/keyel/
│       │   ├── MainActivity.kt
│       │   ├── PlatformChannels.kt     # clipboard sensitive flag, FLAG_SECURE
│       │   └── autofill/
│       │       ├── KeyelAutofillService.kt
│       │       ├── FieldParser.kt      # AssistStructure -> fields
│       │       ├── DomainMatcher.kt
│       │       └── AuthActivity.kt     # hosts the Flutter picker
│       └── res/                        # adaptive + themed + monochrome icon, xml/
├── test/                       # unit + widget + golden
└── integration_test/
```

---

## 6. Data model (Rust, serialized in the vault)

```
Vault {
  version: u16,
  created_at, modified_at,
  folders: Vec<Folder>,
  entries: Vec<Entry>,
  settings: VaultSettings   // generator defaults, auto-lock, etc.
}

Folder { id: Uuid, name, icon, color?, sort }

Entry {
  id: Uuid, kind: Login | Card | Note,
  title, folder_id?, favorite: bool,
  created_at, modified_at, deleted_at?,
  notes: String,
  tags: Vec<String>,
  body: EntryBody
}

Login    { username, password, urls: Vec<String>, android_apps: Vec<String>,
           totp: Option<TotpConfig>, password_history: Vec<(Secret, time)> }
Card     { holder, number, expiry, cvv, pin?, brand }
Note     { }  // content is `notes`

TotpConfig { secret(base32), issuer, account, algo, digits, period }
```

DTOs sent to Dart in lists contain only: `id, kind, title, subtitle (username/last4), favorite, folder_id, has_totp, health_flags`. No secrets.

---

## 7. Cryptographic design

**File layout: `vault.keyel`**
```
magic "KYL1" | format_version u16
header (plaintext, authenticated as AAD):
  kdf: argon2id { m_kib, t, p, salt[16] }
  keyslots[]:
    - master:   nonce[24] + wrapped_vault_key[32+16]
    - recovery: salt/nonce + wrapped_vault_key
body: nonce[24] | ciphertext(CBOR(Vault)) | tag
```

**Flows**
- **Create:** random 32-byte `vault_key` → Argon2id(master, salt) = `KEK` → wrap vault_key. Generate a 256-bit **recovery key**, show once as 8 groups of base32, wrap vault_key in a second keyslot.
- **Unlock:** derive KEK → unwrap vault_key → decrypt body → hold `vault_key` + decrypted vault in a `Mutex<Option<Session>>` in Rust.
- **Save:** serialize → new random nonce → encrypt → write to `vault.keyel.tmp` → `fsync` → atomic rename. Keep one `.bak` of the previous version.
- **Change master password:** only re-wrap the vault_key. Body untouched.
- **Biometric:** a Keystore AES key (auth-bound, invalidated on new biometric enrollment) wraps the `vault_key`. Stored via `biometric_storage`. Master password is still required after a reboot, 3 failed biometric attempts, or every 72 h (configurable).
- **Argon2 params:** start at m=64 MiB, t=3, p=1. Benchmark on device at first setup and store tuned values in the header.
- **Lock:** `zeroize` session, drop decrypted vault.

Publish `docs/crypto-design.md` so others can review it.

---

## 8. Rust API surface (exposed to Dart)

```rust
// session.rs
create_vault(master: String) -> Result<RecoveryKey>
unlock_with_master(master: String) -> Result<()>
unlock_with_recovery(key: String, new_master: String) -> Result<()>
unlock_with_biometric_key(wrapped: Vec<u8>) -> Result<()>
export_biometric_wrap_material() -> Result<Vec<u8>>   // for Keystore wrapping
lock()
is_unlocked() -> bool
change_master(old: String, new: String) -> Result<()>

// entries.rs
list_entries(filter: EntryFilter) -> Vec<EntrySummary>
get_entry(id) -> EntryDetail                 // secrets masked
reveal_field(id, field: SecretField) -> String
upsert_entry(draft: EntryDraft) -> Uuid
delete_entry(id) / restore_entry(id) / purge_trash()
set_favorite(id, bool)
list_folders() / upsert_folder() / delete_folder()

// generator.rs
generate_password(opts) -> String
generate_passphrase(opts) -> String
estimate_strength(pw: String) -> Strength     // 0..4 + feedback

// totp.rs
current_code(id) -> TotpCode { code, seconds_left }
parse_otpauth(uri) -> TotpConfig

// health.rs
analyze() -> HealthReport { weak, reused, old, no_2fa, insecure_urls }

// backup.rs
export_encrypted(path, password) -> Result<()>
import_encrypted(path, password, mode: Merge | Replace)
import_csv(path, source: Bitwarden | Chrome) -> ImportReport

// autofill (called from picker feature)
find_matches(package: String, web_domain: Option<String>) -> Vec<EntrySummary>
```

Streams (FRB `StreamSink`): `lock_events` (auto-lock fired), `totp_ticks`.

---

## 9. Flutter architecture

- **Riverpod** providers per feature: `vaultSessionProvider` (locked/unlocked), `entriesProvider(filter)`, `entryDetailProvider(id)`, `settingsProvider`.
- **Router guard:** any route except onboarding/unlock redirects to `/unlock` when locked.
- **Auto-lock controller:** `WidgetsBindingObserver`; on `paused` start a timer (default 1 min, options: immediately, 30 s, 1, 5, 15 min); on timeout call `lock()` and navigate to unlock.
- **Platform channel `keyel/platform`:** `setSecure(bool)`, `copySensitive(text)`, `clearClipboard()`.
- **Settings** stored as a small JSON file in app-private dir (not in the encrypted vault, so the unlock screen can read theme and timeouts). No secrets in settings.

### Adaptive layer (`ui/adaptive/`)
- `WindowSizeClass` from `MediaQuery.sizeOf`: **Compact < 600 dp**, **Medium 600-839**, **Expanded 840-1199**, **Large 1200+**.
- `AdaptiveScaffold`: Compact = bottom navigation bar; Medium = navigation rail; Expanded/Large = rail with labels (or permanent drawer at Large).
- **List-detail** (canonical layout) for the vault: Compact = pushed route; Medium+ = list pane (about 360-400 dp) + detail pane side by side. Selecting an entry never navigates away on wide screens.
- **Supporting pane** for the generator on Expanded: sits beside the edit form.
- Foldables: read `MediaQuery.displayFeatures`; never place content under a hinge, split panes along it.
- Edge-to-edge with `SystemUiMode.edgeToEdge`, correct insets.
- Predictive back (`android:enableOnBackInvokedCallback="true"`).
- Keyboard and mouse: shortcuts for tablets/ChromeOS (Ctrl+F search, Ctrl+N new, Ctrl+C copy password, Esc back).
- Orientation: all enabled, no locking.
- Text scaling up to 200 % without clipping; RTL supported (Arabic locale).

---

## 10. Android integration

**Manifest**
- No `INTERNET` permission in v1.
- `android:allowBackup="false"`, `dataExtractionRules` excluding everything.
- `android:enableOnBackInvokedCallback="true"`.
- `USE_BIOMETRIC`.
- Autofill service declaration with `BIND_AUTOFILL_SERVICE` and `autofill_service_config.xml`.

**Autofill flow**
1. `KeyelAutofillService.onFillRequest` parses the `AssistStructure` for username/password fields, package name and web domain.
2. Returns a `FillResponse` with an **authentication intent** to `AuthActivity` (vault is locked or needs confirmation).
3. `AuthActivity` launches the Flutter `autofill_picker` route: biometric/master unlock → matching entries (from `find_matches`) → user picks one.
4. Activity returns the `Dataset` with the chosen credentials.
5. Save requests: `onSaveRequest` opens the picker in "save new login" mode.
Matching: exact package for apps, registrable domain for web, warn on mismatch.

**Icons:** adaptive icon with foreground, background and **monochrome** layer (themed icons).

**Optional later:** Quick Settings tile "Lock vault", app shortcut "Generate password", Credential Manager passkey provider.

---

## 11. Security hardening checklist

- [ ] `FLAG_SECURE` on all screens showing secrets (toggle in settings)
- [ ] Recents thumbnail hidden when locked
- [ ] Sensitive clipboard flag + auto-clear (15 s, 30 s, 1 min, never)
- [ ] Wrong master attempts: exponential delay (not a wipe)
- [ ] Biometric requires `BIOMETRIC_STRONG`
- [ ] No secrets in logs; release builds strip `println!`/`debugPrint`
- [ ] R8 minify, ProGuard rules for FRB
- [ ] `cargo audit` and `cargo deny` in CI
- [ ] Reproducible Rust build (`Cargo.lock` committed, pinned toolchain)
- [ ] Constant-time comparisons where relevant (`subtle`)
- [ ] Vault parser fuzzed for 1 h+ in CI nightly
- [ ] Independent review of `docs/crypto-design.md` before 1.0

---

## 12. Testing strategy

**Rust (`keyel_core`)**
- Unit tests: encrypt/decrypt round trip, wrong password fails, tampered header/body fails, nonce uniqueness, keyslot re-wrap, recovery flow.
- Property tests (`proptest`): any vault serializes and deserializes identically; format migration is lossless.
- Known-answer tests for TOTP (RFC 6238 vectors).
- Fuzz: `cargo fuzz run parse_vault`.

**Flutter**
- Widget tests for each screen at 3 window sizes (400, 700, 1000 dp wide).
- Golden tests for key screens in light, dark, and large font scale.
- Integration tests: onboarding → add entry → lock → unlock → search → delete → restore.
- Manual matrix: small phone, Pixel 9-class, foldable (open/closed/tabletop), 10" tablet, Android 10 through current.

---

## 13. CI/CD (GitHub Actions)

1. `rust`: `cargo fmt --check`, `clippy -D warnings`, `cargo test`, `cargo audit`.
2. `flutter`: `flutter analyze`, `flutter test`, golden check.
3. `android-build`: build APK with `cargo-ndk` (via FRB template), upload artifact.
4. `release` (tag): signed AAB/APK, checksums, changelog.

---

## 14. Roadmap (A to Z)

| Phase | Goal | Done when |
|---|---|---|
| **0. Foundation** | Repo, FRB template, CI, theme tokens | `generate_password` works end to end on a device |
| **1. Crypto core** | `keyel_core` crypto + format + tests | Create, lock, unlock round trip passes tests; fuzz target runs |
| **2. Vault model** | Entries, folders, search, trash, history | All CRUD covered by tests |
| **3. Adaptive shell** | Window classes, nav, list-detail, theme, dynamic color | Placeholder screens adapt on phone/foldable/tablet |
| **4. Onboarding + unlock** | Create vault, recovery key, biometrics, auto-lock | Full lock/unlock lifecycle on device |
| **5. Vault UI** | List, detail, edit (3 types), folders, favorites, trash | Daily-usable manual vault |
| **6. Generator + TOTP** | Generator sheet, strength meter, QR scan, live codes | Add 2FA by QR and copy a valid code |
| **7. Security dashboard** | Weak/reused/old/no-2FA report | Report matches test fixtures |
| **8. Backup + import** | Encrypted export/import, Bitwarden/Chrome CSV | Round trip import of 1,000 entries |
| **9. Autofill** | Service, picker, save flow, matching | Fills in Chrome and 3 native apps |
| **10. Hardening** | Checklist, fuzzing, R8, accessibility pass | Checklist complete, TalkBack usable |
| **11. Beta** | Dogfood, fix, localization (EN/FR/AR) | 2 weeks daily use with no data loss |
| **12. Release** | Signing, store listing, F-Droid metadata, docs | v1.0 tag |

**Later (v2):** E2EE sync with a Rust server (ties into your Walt/notes plan), passkeys via Credential Manager, Wear OS quick-copy for TOTP, desktop build (Rust core is reusable).

---

## 15. Stretch and open decisions

- **License:** GPL-3.0 / AGPL-3.0 (strong copyleft, common for password managers) or MIT.
- **Breach check:** optional HIBP k-anonymity range query. It needs the `INTERNET` permission, so keep it a separate opt-in build flavor or a clearly explained opt-in. Shipped in **1.7.0** as a clearly explained, revocable opt-in (no separate build flavor); see `docs/roadmap_1.7.0.md`.
- **Passkeys:** Credential Manager provider API on Android 14+.
- **Wipe after N attempts:** off by default (risky), opt-in only.
- **Name check:** search the Play Store and trademark databases for "Keyel" before committing. Alternatives: *Pinlock, Vaultel, Keybit*.

---

## 16. First commands

```bash
flutter_rust_bridge_codegen create keyel
cd keyel
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
cargo install cargo-ndk cargo-audit cargo-deny
mkdir -p crates && cargo new --lib crates/keyel_core
flutter_rust_bridge_codegen generate --watch
flutter run
```

Build **Phase 1 in `keyel_core` with tests first**, before touching UI.
