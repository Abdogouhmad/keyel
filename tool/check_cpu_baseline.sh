#!/usr/bin/env bash
# Verify that a desktop bundle only needs the BASELINE ISA of its architecture.
#
# A password manager that refuses to start on an older CPU is a broken release.
# On Linux this is a hard failure of the dynamic loader: when an ELF advertises
# "x86-64-v2"/"x86-64-v3" in .note.gnu.property, glibc prints
#   "<binary>: CPU ISA level is lower than required"
# and exits before any Dart code runs. The CI runner is allowed to be newer than
# our users' machines, so the release build must pin the baseline explicitly
# (linux/CMakeLists.txt) and this check must reject any bundle that drifts.
#
# macOS and Windows have no equivalent ELF note; their C/C++ toolchains already
# default to the baseline (SSE2 on x86-64, Apple's standard ARM64 slice), so the
# guard there rejects builds that inject host-native/arch-specific flags and
# verifies the macOS universal binary still carries the x86_64 slice.
#
# Usage:
#   ./tool/check_cpu_baseline.sh --bundle build/linux/x64/release/bundle
#   ./tool/check_cpu_baseline.sh --bundle build/macos/Build/Products/Release --platform macos
#   ./tool/check_cpu_baseline.sh --bundle build/windows/x64/runner/Release --platform windows

set -euo pipefail

bundle=''
platform=''

usage() {
  cat <<'EOF'
Usage: tool/check_cpu_baseline.sh --bundle DIR [--platform linux|macos|windows]

  --bundle    Flutter desktop release bundle to check.
  --platform  Override host detection (useful when checking another OS's bundle).
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --bundle) bundle="${2:?--bundle needs a value}"; shift 2 ;;
    --platform) platform="${2:?--platform needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$bundle" ]]; then
  echo "--bundle is required" >&2
  usage >&2
  exit 2
fi
if [[ ! -d "$bundle" ]]; then
  echo "Not a directory: $bundle" >&2
  exit 2
fi

if [[ -z "$platform" ]]; then
  case "$(uname -s)" in
    Linux) platform=linux ;;
    Darwin) platform=macos ;;
    MINGW*|MSYS*|CYGWIN*) platform=windows ;;
    *) echo "Unsupported host; pass --platform explicitly." >&2; exit 2 ;;
  esac
fi

fail() {
  echo "::error::CPU baseline check failed: $*" >&2
  exit 1
}

check_compile_flags() {
  local label="$1"; shift
  local value
  value="$*"
  case "$value" in
    *native*|*x86-64-v[234]*|*AVX*|*avx*) fail "$label requests a non-baseline ISA: $value" ;;
  esac
}

case "$platform" in
  linux)
    command -v readelf >/dev/null 2>&1 || fail "readelf (binutils) is required"
    [[ -f "$bundle/keyel" ]] || fail "missing $bundle/keyel"
    check_compile_flags CFLAGS "${CFLAGS:-}"
    check_compile_flags CXXFLAGS "${CXXFLAGS:-}"

    checked=0
    while IFS= read -r -d '' elf; do
      checked=$((checked + 1))
      notes="$(readelf -n "$elf" 2>/dev/null || true)"
      requirements="$(grep 'x86 ISA needed:' <<<"$notes" || true)"
      [[ -n "$requirements" ]] || continue

      while IFS= read -r line; do
        # readelf prints e.g. "x86 ISA needed: x86-64-baseline, x86-64-v2".
        IFS=',' read -ra levels <<<"${line#*x86 ISA needed: }"
        for level in "${levels[@]}"; do
          level="${level//[[:space:]]/}"
          [[ -z "$level" || "$level" == x86-64-baseline ]] ||
            fail "$elf requires '$level' (need plain x86-64 baseline)"
        done
      done <<<"$requirements"
    done < <(find "$bundle" -type f \( -name keyel -o -name '*.so' -o -name '*.so.*' \) -print0)

    (( checked > 0 )) || fail "no ELF binaries found in $bundle"
    echo "OK: $checked Linux ELF file(s) require only x86-64-baseline."
    ;;

  macos)
    app="$bundle/Keyel.app"
    binary="$app/Contents/MacOS/Keyel"
    [[ -x "$binary" ]] || fail "missing universal binary $binary"
    command -v lipo >/dev/null 2>&1 || fail "lipo (Xcode tools) is required"
    archs="$(lipo -archs "$binary")"
    case " $archs " in
      *" x86_64 "*) : ;;
      *) fail "macOS bundle lost its x86_64 slice (archs: $archs)" ;;
    esac
    case " $archs " in
      *" arm64 "*) : ;;
      *) fail "macOS bundle lost its arm64 slice (archs: $archs)" ;;
    esac
    check_compile_flags CFLAGS "${CFLAGS:-}"
    check_compile_flags CXXFLAGS "${CXXFLAGS:-}"
    echo "OK: macOS bundle is universal ($archs) with no host-native flags."
    ;;

  windows)
    exe="$bundle/keyel.exe"
    [[ -f "$exe" ]] || fail "missing $exe"
    check_compile_flags CL "${CL:-}"
    check_compile_flags CFLAGS "${CFLAGS:-}"
    check_compile_flags CXXFLAGS "${CXXFLAGS:-}"
    echo "OK: Windows bundle exists and no AVX/native arch flags were injected."
    ;;

  *)
    echo "Unknown platform: $platform" >&2
    exit 2
    ;;
esac
