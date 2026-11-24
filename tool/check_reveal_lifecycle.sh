#!/usr/bin/env bash
# Enforce the 1.11.0 secret-lifecycle contract mechanically.
#
# The reveal timer and lifecycle observers are covered by widget/unit tests;
# this guard catches the cheap native and configuration regressions that tests
# on the host cannot see (FLAG_SECURE before first frame, biometric prompts
# surviving backgrounding, route masking registration).
#
# Run locally:  ./tool/check_reveal_lifecycle.sh
# CI:           .github/workflows/ci.yml "Reveal lifecycle" step.

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

require() {
  local label="$1"
  shift
  if ! "$@"; then
    echo "::error::Missing reveal-lifecycle guarantee: $label"
    fail=1
  fi
}

reject() {
  local label="$1"
  shift
  if "$@"; then
    echo "::error::$label"
    fail=1
  fi
}

require "FLAG_SECURE on the main activity before first frame" grep -q \
  'FLAG_SECURE' \
  android/app/src/main/kotlin/com/freesoftware/keyel/MainActivity.kt
require "FLAG_SECURE on the autofill activity before first frame" grep -q \
  'FLAG_SECURE' \
  android/app/src/main/kotlin/com/freesoftware/keyel/autofill/AuthActivity.kt
require "FLAG_SECURE on the passkey activity before first frame" grep -q \
  'FLAG_SECURE' \
  android/app/src/main/kotlin/com/freesoftware/keyel/passkeys/PasskeyHandlerActivity.kt

reject "biometric authorization must not survive backgrounding" grep -q \
  'persistAcrossBackgrounding: true' \
  lib/core/platform/biometric_auth.dart

require "reveal generation guard" grep -q '_revealGeneration' \
  lib/features/entry/entry_detail_controller.dart
require "route-change masking registered in the app" grep -q \
  'keyelRouteObserver' lib/core/router/app_router.dart
require "local APK installation carries an unverified warning" grep -q \
  'otaLocalInstallWarning' lib/features/ota/widgets/ota_screen_sections.dart

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Secret lifecycle contract violated. See docs/roadmap_1.11.0.md."
  exit 1
fi

echo "Secret lifecycle contract satisfied."
