#!/usr/bin/env bash
#
# keyel — automated release build (Android, Flutter + Rust via flutter_rust_bridge).
#
# Builds the installable, SIGNED Android APKs and stages them flat under dist/:
#
#   Artifact                          Where it lands
#   ------------------------------------------------------------------------
#   split APKs (arm / arm64)          dist/keyel-v<ver>-{armeabi-v7a,arm64-v8a}.apk
#   universal fat APK (arm + arm64)   dist/keyel-v<ver>-universal.apk
#   app bundle (with --aab)           dist/keyel-v<ver>.aab
#   debug symbols (with --obfuscate)  dist/keyel-v<ver>-symbols.zip
#   sha256 checksums                  dist/checksums.txt
#
# What is different from a plain Flutter build (flutter_rust_bridge):
#   * The Rust Android targets must be installed (checked / added here).
#   * The generated FRB bindings must be in sync with the Rust API. In CI the
#     build FAILS if regenerating them changes anything (stale bindings are a
#     classic "works on my machine" release bug). Regeneration runs
#     `cargo expand`, which is SLOW (several minutes), so locally it can be
#     skipped with --skip-bindings (never skipped in CI).
#   * Rust fmt / clippy / tests / audit and Flutter analyze / test run first
#     (skip locally with --skip-checks; always run in CI).
#
# Keyel is a password manager, so the release is also POLICY-CHECKED: every
# APK must be signed, must NOT request the INTERNET permission, must NOT be
# debuggable, and must have android:allowBackup="false". The build fails
# rather than ship a release that breaks any of these.
#
# Release-signing: Android refuses to install an unsigned release APK and
# refuses a "signature update" over a differently-signed app, so every release
# is signed with the SAME stable keystore, provisioned here from the KEYEL_*
# secrets. In CI the keystore is REQUIRED. Locally, when no KEYEL_* env vars are
# set it reuses an existing android/key.properties, else it falls back to
# Android's debug key (see android/app/build.gradle.kts), enough for a local
# release run on a fresh clone. NEVER publish a debug-signed build.
#
# GitHub secrets:
#   KEYEL_KEYSTORE_BASE64   = base64 of the keyel-release.jks keystore
#   KEYEL_KEYSTORE_PASSWORD = keystore password
#   KEYEL_KEY_ALIAS         = signing key alias
#   KEYEL_KEY_PASSWORD      = signing key password
#
# Usage:
#   ./build.sh                       checks + bindings + keystore + build + stage + verify
#   ./build.sh --aab                 also build the Play Store app bundle
#   ./build.sh --obfuscate           obfuscate Dart code, keep symbols in dist/
#   ./build.sh --skip-checks         skip Rust/Flutter lint+test (local only)
#   ./build.sh --skip-bindings       skip FRB codegen regeneration (local only;
#                                    use when the Rust API has not changed)
#   ./build.sh --fast                quick LOCAL build: arm64 only, no universal
#                                    APK, no checks, no bindings regeneration
#   ./build.sh --detect-version      print tag= / version= / versionCode= lines
#                                    (append to $GITHUB_OUTPUT)
#   ./build.sh --release-notes       extract this version's CHANGELOG section
#                                    into dist/notes.md
#   ./build.sh --no-version-checksum skip the uncommitted-changes warning
#   ./build.sh -v                    verbose (kept for parity)
#
# Exit codes: 0 = success, 1 = failure (missing deps / secrets / policy / artifacts).

set -euo pipefail

cd "$(dirname "$0")"

# True when running on GitHub Actions / other CI.
CI_RUNNER="${CI:-false}"

# ── Project layout (edit if your tree differs) ───────────────────────────────
# Where flutter_rust_bridge writes its generated code.
FRB_DART_OUT="lib/src/rust"
FRB_RUST_OUT="rust/src/frb_generated.rs"
# Rust workspace root: the repo root if it has a Cargo.toml, else ./rust.
if [[ -f Cargo.toml ]]; then RUST_ROOT="."; else RUST_ROOT="rust"; fi
# Rust targets matching --target-platform android-arm,android-arm64.
RUST_TARGETS=(aarch64-linux-android armv7-linux-androideabi)
PKG_NAME="keyel"

# ── Flags ─────────────────────────────────────────────────────────────────────
VERBOSE=false
MODE=build # build | detect-version | release-notes
CHECK_VERSION=true
RUN_CHECKS=true
SKIP_BINDINGS=false
FAST=false
BUILD_AAB=false
OBFUSCATE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose) VERBOSE=true ;;
  --detect-version) MODE=detect-version ;;
  --release-notes) MODE=release-notes ;;
  --no-version-checksum) CHECK_VERSION=false ;;
  --skip-checks) RUN_CHECKS=false ;;
  --skip-bindings) SKIP_BINDINGS=true ;;
  --fast) FAST=true ;;
  --aab) BUILD_AAB=true ;;
  --obfuscate) OBFUSCATE=true ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# --fast implies skipping checks and bindings regeneration (local only).
if [[ "$FAST" == true ]]; then
  RUN_CHECKS=false
  SKIP_BINDINGS=true
  BUILD_AAB=false
fi

# CI always runs the full pipeline, whatever the flags say.
if [[ "$CI_RUNNER" == true ]]; then
  if [[ "$FAST" == true ]]; then
    echo "[keyel] --fast is not allowed in CI (it skips checks and builds a single ABI)." >&2
    exit 1
  fi
  RUN_CHECKS=true
  SKIP_BINDINGS=false
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
info() { printf '\033[1;36m[keyel]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[keyel]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[keyel]\033[0m %s\n' "$*" >&2; }
run() {
  if [[ "$VERBOSE" == true ]]; then printf '+ %s\n' "$*"; fi
  "$@"
}
have() { command -v "$1" >/dev/null 2>&1; }

# Find a tool in the newest Android SDK build-tools (apksigner, aapt2).
sdk_tool() {
  local name="$1" sdk_dir tool=""
  sdk_dir="$(sed -n 's/^sdk\.dir=//p' android/local.properties 2>/dev/null | head -n1)"
  sdk_dir="${sdk_dir:-${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}}"
  if [[ -n "$sdk_dir" ]]; then
    tool="$(find "$sdk_dir/build-tools" -name "$name" -type f 2>/dev/null | sort -V | tail -n1 || true)"
  fi
  if [[ -z "$tool" ]] && have "$name"; then tool="$(command -v "$name")"; fi
  printf '%s' "$tool"
}

# ── Versioning ────────────────────────────────────────────────────────────────
# `pubspec.yaml` is the single source of truth. The tag is `v<semver>` and the
# versionCode is major*10000 + minor*100 + patch. build.sh hands it to Flutter
# via --build-number (see VERSION_ARGS), so the APK's versionCode is always
# predictable and strictly increases between releases.
get_version() { sed -n 's/^version: *//p' pubspec.yaml | head -n1; }

VERSION="$(get_version)"
VERSION="${VERSION%%+*}" # strip any +<build-number> metadata
IFS='.' read -r MAJOR MINOR PATCH <<<"$VERSION"
VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + PATCH))
TAG="v${VERSION}"

# ── Mode: print version lines for $GITHUB_OUTPUT / scripting ──────────────────
if [[ "$MODE" == detect-version ]]; then
  printf 'tag=%s\nversion=%s\nversionCode=%s\n' "$TAG" "$VERSION" "$VERSION_CODE"
  exit 0
fi

# ── Mode: extract this release's CHANGELOG section into dist/notes.md ─────────
if [[ "$MODE" == release-notes ]]; then
  mkdir -p dist
  # Strip only TRAILING whitespace; leading indentation is Markdown structure.
  sed -n "/^## \\[$VERSION\\]/,/^## \\[/p" CHANGELOG.md |
    sed '$d' |
    sed -E '/^[[:space:]]*\[[^]]+\]:[[:space:]]/d' |
    sed -E 's/[[:space:]]+$//' \
      >dist/notes.md
  if [[ ! -s dist/notes.md ]]; then
    err "CHANGELOG.md has no '## [$VERSION]' section. Add the release notes first."
    exit 1
  fi
  if ! grep -qF "## [$VERSION]" dist/notes.md; then
    err "Extracted notes do not contain the '## [$VERSION]' heading."
    exit 1
  fi
  info "Release notes extracted -> dist/notes.md ($(wc -l <dist/notes.md) lines)"
  exit 0
fi

# ── Preflight ────────────────────────────────────────────────────────────────
preflight() {
  local missing=()
  for tool in flutter rustup cargo; do
    have "$tool" || missing+=("$tool")
  done
  if ((${#missing[@]} > 0)); then
    err "Missing required tools: ${missing[*]}"
    exit 1
  fi
  if [[ ! -f "$RUST_ROOT/Cargo.lock" ]]; then
    err "$RUST_ROOT/Cargo.lock not found. Commit it so Rust builds are reproducible."
    exit 1
  fi
}

ensure_rust_targets() {
  local installed t
  installed="$(rustup target list --installed 2>/dev/null || true)"
  for t in "${RUST_TARGETS[@]}"; do
    # --fast only needs the arm64 target.
    if [[ "$FAST" == true && "$t" != "aarch64-linux-android" ]]; then
      continue
    fi
    if ! grep -qx "$t" <<<"$installed"; then
      info "Adding missing Rust target $t ..."
      run rustup target add "$t"
    fi
  done
}

# ── flutter_rust_bridge: bindings must match the Rust API ────────────────────
# NOTE: codegen runs `cargo expand`, which can take many minutes. Use
# --skip-bindings locally when the Rust API has not changed. After changing the
# Rust API, run `flutter_rust_bridge_codegen generate` once and commit the result.
check_bindings() {
  if [[ "$SKIP_BINDINGS" == true ]]; then
    warn "Skipping bindings regeneration (--skip-bindings / --fast). Local build only."
    return
  fi
  if ! have flutter_rust_bridge_codegen; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "flutter_rust_bridge_codegen not installed in CI (cargo install flutter_rust_bridge_codegen)."
      exit 1
    fi
    warn "flutter_rust_bridge_codegen not found; skipping bindings check."
    return
  fi
  info "Regenerating flutter_rust_bridge bindings (slow: cargo expand) ..."
  run flutter_rust_bridge_codegen generate
  if ! git diff --quiet -- "$FRB_DART_OUT" "$FRB_RUST_OUT" 2>/dev/null; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "Generated bindings are out of date. Run 'flutter_rust_bridge_codegen generate' and commit:"
      git --no-pager diff --stat -- "$FRB_DART_OUT" "$FRB_RUST_OUT" >&2
      exit 1
    fi
    warn "Bindings changed after regeneration. Review and commit them before releasing."
  fi
}

# ── Quality gates ────────────────────────────────────────────────────────────
run_checks() {
  info "Rust: fmt, clippy, tests ..."
  (cd "$RUST_ROOT" &&
    run cargo fmt --all -- --check &&
    run cargo clippy --workspace --all-targets -- -D warnings &&
    run cargo test --workspace)

  if cargo audit --version >/dev/null 2>&1; then
    info "Rust: cargo audit ..."
    (cd "$RUST_ROOT" && run cargo audit)
  elif [[ "$CI_RUNNER" == true ]]; then
    err "cargo-audit not installed in CI (cargo install cargo-audit)."
    exit 1
  else
    warn "cargo-audit not installed; skipping dependency audit."
  fi

  info "Flutter: analyze + test ..."
  run flutter analyze
  run flutter test
}

# ── Provision the Android release keystore ────────────────────────────────────
provision_keystore() {
  if [[ -n "${KEYEL_KEYSTORE_BASE64:-}" ]]; then
    local store_password="${KEYEL_KEYSTORE_PASSWORD:?KEYEL_KEYSTORE_PASSWORD not set}"
    local key_alias="${KEYEL_KEY_ALIAS:?KEYEL_KEY_ALIAS not set}"
    local key_password="${KEYEL_KEY_PASSWORD:?KEYEL_KEY_PASSWORD not set}"

    info "Provisioning Android release keystore (alias '$key_alias') ..."
    mkdir -p android/app/keystores
    printf '%s' "$KEYEL_KEYSTORE_BASE64" | base64 -d >android/app/keystores/keyel.jks
    # storeFile is relative to android/app/ (where build.gradle.kts resolves file()).
    cat >android/key.properties <<EOF
storePassword=${store_password}
keyPassword=${key_password}
keyAlias=${key_alias}
storeFile=keystores/keyel.jks
EOF
    # Verify the alias up front so a misconfigured secret fails fast.
    keytool -keystore android/app/keystores/keyel.jks -list \
      -storepass "${store_password}" -alias "${key_alias}" >/dev/null
    return
  fi

  if [[ "$CI_RUNNER" == true ]]; then
    err "KEYEL_KEYSTORE_BASE64 is not set. CI release builds MUST be signed"
    err "with the stable release keystore. Configure the KEYEL_* secrets on"
    err "GitHub (see build.sh header). Refusing to ship an unsigned release."
    exit 1
  fi

  if [[ -f android/key.properties ]]; then
    warn "No KEYEL_* secrets in env, reusing android/key.properties."
  else
    warn "No keystore found, building with Android's debug signing (LOCAL ONLY, do not publish)."
  fi
}

# ── Builds ───────────────────────────────────────────────────────────────────
# Optional obfuscation flags (symbols are kept so crashes can be de-obfuscated).
OBF_ARGS=()
if [[ "$OBFUSCATE" == true ]]; then
  OBF_ARGS=(--obfuscate --split-debug-info=build/symbols)
fi

# Compile-time metadata so AppInfo.version matches pubspec.yaml.
DEFINE_ARGS=(--dart-define=KEYEL_VERSION="$VERSION")

# Force the versionCode/versionName the versioning section computed. Without
# this Flutter fills them from the pubspec build number (`0.12.0+1` -> 1), so
# every release would ship versionCode 1 and the Play Store would reject the
# next upload as a duplicate.
VERSION_ARGS=(--build-name="$VERSION" --build-number="$VERSION_CODE")

# One slim APK per supported ABI (arm32 / arm64) ...
# (cargokit compiles the Rust crate for exactly these targets.)
build_split_abis() {
  info "Building split-per-ABI release APKs (arm / arm64) ..."
  run flutter build apk --release --split-per-abi \
    --target-platform android-arm,android-arm64 \
    "${DEFINE_ARGS[@]}" \
    "${VERSION_ARGS[@]}" \
    "${OBF_ARGS[@]+"${OBF_ARGS[@]}"}" \
    -Pforce-version-code-ignoring-abi=true
}

# ... and one universal fat APK (arm + arm64) for sideloading / F-Droid.
build_universal() {
  info "Building universal release APK (arm + arm64) ..."
  run flutter build apk --release \
    --target-platform android-arm,android-arm64 \
    "${DEFINE_ARGS[@]}" \
    "${VERSION_ARGS[@]}" \
    "${OBF_ARGS[@]+"${OBF_ARGS[@]}"}"
}

build_aab() {
  info "Building Play Store app bundle ..."
  run flutter build appbundle --release \
    --target-platform android-arm,android-arm64 \
    "${DEFINE_ARGS[@]}" \
    "${VERSION_ARGS[@]}" \
    "${OBF_ARGS[@]+"${OBF_ARGS[@]}"}"
}

# Quick local build: a single arm64 APK (most modern phones).
build_fast() {
  info "Fast build: single arm64 release APK (local only) ..."
  run flutter build apk --release \
    --target-platform android-arm64 \
    "${DEFINE_ARGS[@]}" \
    "${VERSION_ARGS[@]}" \
    "${OBF_ARGS[@]+"${OBF_ARGS[@]}"}"
}

# ── Stage + checksum ─────────────────────────────────────────────────────────
stage_artifacts() {
  info "Staging artifacts under dist/ ..."
  mkdir -p dist
  local out="build/app/outputs/flutter-apk"

  for src_name in app-armeabi-v7a-release.apk app-arm64-v8a-release.apk app-release.apk; do
    [[ -f "$out/$src_name" ]] || {
      err "Missing build output: $out/$src_name"
      exit 1
    }
  done

  cp "$out/app-armeabi-v7a-release.apk" "dist/${PKG_NAME}-v${VERSION}-armeabi-v7a.apk"
  cp "$out/app-arm64-v8a-release.apk" "dist/${PKG_NAME}-v${VERSION}-arm64-v8a.apk"
  cp "$out/app-release.apk" "dist/${PKG_NAME}-v${VERSION}-universal.apk"

  if [[ "$BUILD_AAB" == true ]]; then
    local aab="build/app/outputs/bundle/release/app-release.aab"
    [[ -f "$aab" ]] || {
      err "Missing build output: $aab"
      exit 1
    }
    cp "$aab" "dist/${PKG_NAME}-v${VERSION}.aab"
  fi

  finish_staging
}

stage_fast() {
  info "Staging fast build under dist/ ..."
  mkdir -p dist
  local src="build/app/outputs/flutter-apk/app-release.apk"
  [[ -f "$src" ]] || {
    err "Missing build output: $src"
    exit 1
  }
  cp "$src" "dist/${PKG_NAME}-v${VERSION}-arm64-v8a.apk"
  finish_staging
}

# Symbols zip + checksums + listing (shared by both staging paths).
finish_staging() {
  if [[ "$OBFUSCATE" == true ]]; then
    [[ -d build/symbols ]] || {
      err "Missing build/symbols (obfuscation symbols)."
      exit 1
    }
    (cd build && zip -qr "../dist/${PKG_NAME}-v${VERSION}-symbols.zip" symbols)
  fi

  (cd dist && sha256sum "${PKG_NAME}"-v"${VERSION}"* >checksums.txt)
  echo
  info "Staged files:"
  ls -1 dist
}

# ── Signature verification ───────────────────────────────────────────────────
verify_signing() {
  local apksigner
  apksigner="$(sdk_tool apksigner)"
  if [[ -z "$apksigner" ]]; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "apksigner not found. Cannot verify the release signatures in CI."
      exit 1
    fi
    warn "apksigner not found, skipping signature verification."
    return
  fi

  local apk certs subject
  local debug_signed=false
  for apk in dist/${PKG_NAME}-v${VERSION}-*.apk; do
    info "Verifying signature: ${apk##*/}"
    certs="$("$apksigner" verify --print-certs "$apk")"
    subject="$(sed -n 's/^Signer #1 certificate DN: //p' <<<"$certs")"
    if grep -qi "Android Debug" <<<"$subject"; then
      debug_signed=true
      warn "  ${apk##*/} is signed with the ANDROID DEBUG key."
    fi
  done

  if [[ "$debug_signed" == true ]]; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "CI produced a debug-signed APK: the release keystore was not applied."
      exit 1
    fi
    if [[ -f android/key.properties ]]; then
      err "android/key.properties exists but the APK is debug-signed."
      err "Check storeFile in key.properties and the release signingConfig."
      exit 1
    fi
    warn "Debug-signed (no release keystore configured). Do NOT publish this build."
  else
    info "All APKs verify; release-signing confirmed."
  fi
}

# ── Privacy policy checks (Keyel is a password manager) ──────────────────────
verify_policy() {
  local aapt2
  aapt2="$(sdk_tool aapt2)"
  if [[ -z "$aapt2" ]]; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "aapt2 not found. Cannot verify APK policy in CI."
      exit 1
    fi
    warn "aapt2 not found, skipping APK policy checks."
    return
  fi

  local apk perms badging backup_line
  for apk in dist/${PKG_NAME}-v${VERSION}-*.apk; do
    info "Policy check: ${apk##*/}"
    perms="$("$aapt2" dump permissions "$apk" 2>/dev/null || true)"
    if grep -q 'android.permission.INTERNET' <<<"$perms"; then
      err "${apk##*/} requests INTERNET. Keyel must stay offline. Find the plugin or manifest adding it."
      exit 1
    fi
    badging="$("$aapt2" dump badging "$apk" 2>/dev/null || true)"
    if grep -q 'application-debuggable' <<<"$badging"; then
      err "${apk##*/} is DEBUGGABLE. Refusing to ship."
      exit 1
    fi
    backup_line="$("$aapt2" dump xmltree --file AndroidManifest.xml "$apk" 2>/dev/null | grep 'allowBackup' || true)"
    if [[ -z "$backup_line" || "$backup_line" == *"=true"* ]]; then
      err "${apk##*/} does not set android:allowBackup=\"false\" (vault data could leak into cloud backups)."
      exit 1
    fi
  done
  info "Policy OK: no INTERNET permission, not debuggable, backups disabled."
}

# ── Sanity checks ────────────────────────────────────────────────────────────
check_version_checksum() {
  if [[ "$CHECK_VERSION" == false || "$CI_RUNNER" == true ]]; then
    return
  fi
  if ! [[ "$(git status --porcelain 2>/dev/null)" == "" ]]; then
    warn "Working tree has uncommitted changes; building anyway (dirty build)."
    warn "Pass --no-version-checksum to silence this check."
  fi
}

# ── Dispatch ─────────────────────────────────────────────────────────────────
echo
echo "═══════════════════════════════════════════"
echo "  keyel — release build"
echo "  version: $VERSION   (versionCode $VERSION_CODE, tag $TAG)"
if [[ "$FAST" == true ]]; then
  echo "  mode: FAST (arm64 only, local build)"
fi
echo "═══════════════════════════════════════════"

preflight
ensure_rust_targets

info "Fetching dependencies ..."
run flutter pub get

check_bindings
if [[ "$RUN_CHECKS" == true ]]; then run_checks; else warn "Skipping lint/test checks."; fi

check_version_checksum
provision_keystore

if [[ "$FAST" == true ]]; then
  build_fast
  stage_fast
else
  build_split_abis
  build_universal
  if [[ "$BUILD_AAB" == true ]]; then build_aab; fi
  stage_artifacts
fi

verify_signing
verify_policy

echo
if [[ "$FAST" == true ]]; then
  info "Fast build finished (arm64 only). Run the full ./build.sh before publishing."
else
  info "All release artifacts built, signed and verified."
fi
