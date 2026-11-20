#!/usr/bin/env bash
# Fail if a source file prints potentially sensitive values.
#
# This is the mechanical half of threat-model T3: "no secrets in logs". The
# grep below is intentionally coarse — a false positive is cheap to fix, a
# missed `debugPrint('$password')` is not. Every exception must be listed here
# with a reason, so an allow-list entry is always a deliberate, reviewed act.
#
# Run locally:  ./tool/check_no_secret_logs.sh
# CI:           ci.yml "no secret logs" step (both rust and flutter jobs).

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

report() {
  local label="$1"
  local hits="$2"
  if [[ -n "$hits" ]]; then
    echo "::error::Unapproved log call ($label):"
    echo "$hits"
    fail=1
  fi
}

# Rust: dbg! is always a debugging leftover. println!/eprintln! and log::* have
# no place in production code that handles secrets. The only allowed hits are
# timing output in the opt-in Argon2 benchmark test (no key material printed).
rust_hits="$(
  grep -RInE --include='*.rs' \
    '(dbg!|println!|eprintln!|log::(trace|debug|info|warn|error)!)' \
    crates rust 2>/dev/null \
    | grep -v '^crates/keyel_core/tests/vault_model.rs:' \
    || true
)"
report "Rust" "$rust_hits"

# Dart: print/debugPrint bypass our diagnostics bundle and can end up in
# device logs or crash reports. The single allowed call in main.dart reports a
# *storage path* failure during startup; the error is a filesystem error, never
# a password or decrypted value. Keep that justification next to the call.
dart_hits="$(
  grep -RInE --include='*.dart' \
    '(^|[^[:alnum:]_])(print|debugPrint)\(' \
    lib 2>/dev/null \
    | grep -v '^lib/src/rust/' \
    | grep -v '^lib/main.dart:.*vault storage is unavailable' \
    || true
)"
report "Dart" "$dart_hits"

# Generated bridge code is authoritative from FRB; if it ever starts printing
# we want to know, so scan it too but keep its own allow-list empty.
gen_hits="$(
  grep -RInE --include='*.dart' --include='*.rs' \
    '(dbg!|println!|eprintln!|(^|[^[:alnum:]_])(print|debugPrint)\()' \
    lib/src/rust rust/src/frb_generated.rs 2>/dev/null \
    || true
)"
report "generated bridge" "$gen_hits"

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Add a reviewed exception to tool/check_no_secret_logs.sh if the hit is"
  echo "provably free of secret material; otherwise remove the log call."
  exit 1
fi

echo "No unapproved log calls found."
