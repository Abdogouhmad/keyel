#!/usr/bin/env bash
# Enforce the Wear OS isolation contract from docs/threat-model.md T16.
#
# The watch app may receive *one* explicitly revealed TOTP seed at a time. It
# must never become a background service, hold a vault, reach the clipboard or
# allow screenshots. Most of that is enforced in code review; this script makes
# the cheap, unambiguous parts mechanical so a future refactor cannot quietly
# turn the GMS-bound message handler into an always-running service.
#
# Run locally:  ./tool/check_wear_isolation.sh
# CI:           .github/workflows/ci.yml "Wear OS isolation" step.

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

reject() {
  local label="$1"
  local hits="$2"
  if [[ -n "$hits" ]]; then
    echo "::error::$label"
    echo "$hits"
    fail=1
  fi
}

require() {
  local label="$1"
  shift
  if ! "$@"; then
    echo "::error::Missing Wear OS isolation guarantee: $label"
    fail=1
  fi
}

# No boot receiver, no foreground service, no self-start: the listener is bound
# on demand by the Wearable Data Layer.
reject "Wear manifest must not declare a boot receiver or foreground service" "$(
  grep -RInE \
    'RECEIVE_BOOT_COMPLETED|FOREGROUND_SERVICE|foregroundServiceType|<receiver' \
    wear/src/main/AndroidManifest.xml 2>/dev/null || true
)"

reject "Wear sources must not start a foreground service" "$(
  grep -RInE --include='*.kt' 'startForeground\(' wear/src 2>/dev/null || true
)"

# The watch never touches the system clipboard.
reject "Wear sources must not access the clipboard" "$(
  grep -RInE --include='*.kt' \
    'ClipboardManager|ClipboardData|setPrimaryClip|getPrimaryClip' \
    wear/src 2>/dev/null || true
)"

# A watch screenshot must never capture a TOTP code.
require "FLAG_SECURE on the watch activity" grep -q 'FLAG_SECURE' \
  wear/src/main/java/com/freesoftware/keyel/wear/MainActivity.kt

# Keep the listener system-bound and path-scoped. `exported=true` is required
# for GMS to bind it; the `wear` scheme plus pathPrefix is what narrows it.
require "WearableListenerService base class" grep -q \
  'WearMessageListenerService : WearableListenerService()' \
  wear/src/main/java/com/freesoftware/keyel/wear/WearMessageListenerService.kt
require "MESSAGE_RECEIVED intent filter" grep -q \
  'com.google.android.gms.wearable.MESSAGE_RECEIVED' \
  wear/src/main/AndroidManifest.xml
require "path-scoped TOTP messages" grep -q \
  'android:pathPrefix="/keyel/totp"' \
  wear/src/main/AndroidManifest.xml

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Wear OS isolation contract violated. See docs/threat-model.md T16."
  exit 1
fi

echo "Wear OS isolation contract satisfied."
