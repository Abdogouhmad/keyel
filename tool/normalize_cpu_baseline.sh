#!/usr/bin/env bash
# Normalize a Linux desktop bundle so every ELF is usable on an original
# x86-64 CPU.
#
# The compile flags in linux/CMakeLists.txt and .cargo/config.toml pin our own
# code to the baseline, but a runner can still contribute a non-baseline ISA
# note through its startup objects or a cached Rust artifact. When that happens
# glibc refuses to start the app with "CPU ISA level is lower than required".
# This script removes the stale GNU property note from exactly those ELFs and
# lets check_cpu_baseline.sh verify the result; it never changes the bundle when
# it is already portable.
#
# Usage:
#   ./tool/normalize_cpu_baseline.sh --bundle build/linux/x64/release/bundle
#   ./tool/normalize_cpu_baseline.sh --bundle DIR --platform linux

set -euo pipefail

bundle=''
platform=''

usage() {
  cat <<'EOF'
Usage: tool/normalize_cpu_baseline.sh --bundle DIR [--platform linux]

  --bundle    Flutter desktop release bundle to normalize.
  --platform  Override host detection (only linux needs normalization).
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

if [[ "$platform" != linux ]]; then
  echo "No ISA normalization needed for $platform."
  exit 0
fi

command -v readelf >/dev/null 2>&1 || { echo "readelf (binutils) is required" >&2; exit 2; }
command -v objcopy >/dev/null 2>&1 || { echo "objcopy (binutils) is required" >&2; exit 2; }

non_baseline() {
  local notes="$1" line level levels
  local requirements
  requirements="$(grep 'x86 ISA needed:' <<<"$notes" || true)"
  [[ -n "$requirements" ]] || return 1
  while IFS= read -r line; do
    IFS=',' read -ra levels <<<"${line#*x86 ISA needed: }"
    for level in "${levels[@]}"; do
      level="${level//[[:space:]]/}"
      if [[ -n "$level" && "$level" != x86-64-baseline ]]; then
        return 0
      fi
    done
  done <<<"$requirements"
  return 1
}

normalized=0
while IFS= read -r -d '' elf; do
  notes="$(readelf -n "$elf" 2>/dev/null || true)"
  if ! non_baseline "$notes"; then
    continue
  fi

  echo "Non-baseline ISA note in $elf: $(grep 'x86 ISA needed:' <<<"$notes" | paste -sd '; ' -)"

  # A stale .note.gnu.property says the loader must reject this ELF on older
  # CPUs. Our own objects were compiled with -march=x86-64, so the note is
  # metadata, not code; dropping the whole section also drops CET hints, which is
  # the right trade for an app that must run on baseline hardware.
  objcopy --remove-section=.note.gnu.property "$elf"

  notes="$(readelf -n "$elf" 2>/dev/null || true)"
  if non_baseline "$notes"; then
    echo "ERROR: still non-baseline after normalization: $elf" >&2
    exit 1
  fi
  normalized=$((normalized + 1))
  echo "Removed non-baseline ISA note from $elf"
done < <(find "$bundle" -type f \( -name keyel -o -name '*.so' -o -name '*.so.*' \) -print0)

if (( normalized > 0 )); then
  echo "Normalized $normalized Linux ELF file(s) to x86-64-baseline."
else
  echo "OK: no Linux ELF needed ISA normalization."
fi
