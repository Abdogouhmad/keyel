# Keyel

**Keyel** = *key* + *-el* (as in pixel, voxel). An **offline-first, privacy-first password manager for Android**, with a Rust crypto core and a Flutter UI.

- No network permission: data leaves your device only when you export it.
- All crypto and storage in a pure Rust core (`crates/keyel_core`), bridged to Flutter with [flutter_rust_bridge](https://flutter_rust_bridge.dev).
- Material 3 / Pixel-styled adaptive UI (phone, foldable, tablet).

**Status:** 1.0.0 — stable. English-only for now; localization is deferred. See
[`docs/roadmap.md`](docs/roadmap.md),
[`docs/crypto-design.md`](docs/crypto-design.md) and
[`docs/vault-model.md`](docs/vault-model.md).

## Using Keyel

### Quick start

1. Install the app (a signed APK from Releases, or `flutter run` for a dev
   build — see below).
2. On first launch, **create a vault** and choose a strong master password.
   Write it down: it is never stored on the device and never sent anywhere.
3. **Save the recovery key** when it is shown. It is displayed once and is the
   only way back into the vault if you forget the master password.
4. Optionally enable **biometric unlock**.
5. Add entries — logins, payment cards and secure notes — and use the built-in
   **password generator** and **TOTP** (2FA codes) as needed.
6. Lock the vault with the lock button, or let **auto-lock** close it when the
   app goes to the background. Copied secrets are wiped from the clipboard
   after the timeout you set.

### FAQ

**What if I forget my master password?**
On the unlock screen, choose *Use recovery key* and enter the key you saved at
setup. You can then set a new master password. If you have lost **both** the
master password and the recovery key, the vault **cannot** be recovered — there
is no server, no backdoor and no reset. Restore from an encrypted backup if you
have one.

**Does Keyel send my data anywhere?**
No. Release builds have no `INTERNET` permission. Data leaves the device only
when you explicitly export it or share the diagnostics file from *Report a
problem* (which contains no secrets — see below).

**Where is my data stored?**
In a single encrypted `vault.keyel` file in the app's private storage. The key
that decrypts it exists only in memory, and only while the vault is unlocked.
Cloud/device backups are excluded for the vault file.

**What is "Report a problem"?**
*Settings → Report a problem* shares a redacted diagnostics file: app version,
device model and OS, and non-secret settings. It never includes vault contents,
entry titles, passwords, the recovery key or key material.

**Is the CSV export encrypted?**
No. The plain CSV export is unencrypted and readable by anyone who gets the
file. Use the **encrypted backup** for anything you intend to keep.

### Backups

- Use *Settings → Backup & import → Encrypted backup*. The backup password is
  independent of your master password.
- Keep at least one copy **offline and separate** from the device (an encrypted
  USB drive, or the printed recovery key in a safe).
- **Test a restore** before you rely on the backup.
- The recovery key is a second, independent way in — store it offline too.
- Never keep the plain CSV export on a shared or cloud drive.

## Build & run

### Prerequisites

- Flutter (stable) + Dart
- Rust stable (rustup) with Android targets:
  ```bash
  rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
  ```
- Android SDK (API 36) + NDK, and an Android device or emulator.
- `flutter_rust_bridge_codegen` (v2), `cargo-ndk`:
  ```bash
  cargo install flutter_rust_bridge_codegen cargo-ndk
  ```

### Run on a device

```bash
flutter devices          # pick your device/emulator
flutter run              # debug build: builds Rust via cargokit automatically
```

The first Rust build takes a few minutes (FRB codegen + NDK toolchain).

### Regenerate the bridge after editing `rust/src/api/**`

```bash
flutter_rust_bridge_codegen generate
```

### Tests

```bash
cargo test                          # Rust core (crypto, generator, ...)
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --check
flutter analyze
flutter test
```

### Fuzz the vault parser

```bash
cd crates/keyel_core
cargo +nightly fuzz run parse_vault -- -max_total_time=600
```

The fuzz target exercises the file parser and AEAD opener with a fixed vault
key, so it does not spend every iteration in Argon2. See
[`docs/crypto-design.md`](docs/crypto-design.md).

## Repository layout

See [`docs/plan.md §5`](docs/plan.md) for the full structure. Quick tour:

| Path | What |
|---|---|
| `crates/keyel_core/` | Pure Rust core: crypto, vault format, generator (fully tested, no UI deps) |
| `rust/` | FRB bridge crate — the *only* surface exposed to Dart |
| `lib/` | Flutter app (features, ui, data, core) |
| `docs/` | plan, design spec, crypto spec, roadmap, decision log |
| `design/` | App icon, Stitch screens |

## Security posture

- No `INTERNET` permission in release builds.
- `allowBackup=false`; cloud/device backups excluded via `dataExtractionRules`.
- Secrets live in Rust (`zeroize`/`secrecy`); Dart only ever receives what a user explicitly reveals.
- See [`docs/crypto-design.md`](docs/crypto-design.md) (published in phase 0.2.0).

## License

GPL-3.0-or-later — see [`LICENSE`](LICENSE).
