# Keyel

**Keyel** = *key* + *-el* (as in pixel, voxel). An **offline-first, privacy-first password manager for Android**, with a Rust crypto core and a Flutter UI.

- No network permission: data leaves your device only when you export it.
- All crypto and storage in a pure Rust core (`crates/keyel_core`), bridged to Flutter with [flutter_rust_bridge](https://flutter_rust_bridge.dev).
- Material 3 / Pixel-styled adaptive UI (phone, foldable, tablet).

**Status:** phase 0.2.0 — Crypto core. See [`docs/roadmap.md`](docs/roadmap.md)
and [`docs/crypto-design.md`](docs/crypto-design.md).

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
