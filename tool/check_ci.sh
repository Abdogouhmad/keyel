#!/usr/bin/env bash
# Run the exact command set CI runs, so toolchain drift is caught locally.
#
# CI pins Flutter 3.47.9 (see .github/workflows/ci.yml FLUTTER_VERSION and the
# note in analysis_options.yaml). If `flutter --version` here differs, treat any
# green result as provisional until CI agrees.
#
# Usage:
#   ./tool/check_ci.sh          # fmt/clippy/test/log-guard/analyze/test
#   ./tool/check_ci.sh --frb    # additionally verify FRB bindings are current
#                               # (requires flutter_rust_bridge_codegen 2.13.0)

set -euo pipefail

cd "$(dirname "$0")/.."

step() {
  echo
  echo "==> $*"
}

step "Flutter version (CI pins 3.47.9)"
flutter --version | head -n 2

step "cargo fmt --all --check"
cargo fmt --all --check

step "cargo clippy --workspace --all-targets -- -D warnings"
cargo clippy --workspace --all-targets -- -D warnings

step "cargo test --workspace"
cargo test --workspace

step "tool/check_no_secret_logs.sh"
./tool/check_no_secret_logs.sh

step "flutter gen-l10n (idempotency)"
flutter gen-l10n
git diff --exit-code -- lib/l10n/generated || {
  echo "Generated localizations are out of date; commit the regenerated files."
  exit 1
}

step "flutter analyze"
flutter analyze

step "flutter test"
flutter test

if [[ "${1:-}" == "--frb" ]]; then
  step "flutter_rust_bridge_codegen generate (idempotency)"
  # Must match build.sh and ci.yml: generate WITHOUT --no-web.
  flutter_rust_bridge_codegen generate
  git diff --exit-code -- lib/src/rust rust/src/frb_generated.rs \
    || {
      echo "Generated FRB bindings are out of date; commit the regenerated files."
      exit 1
    }
fi

echo
echo "All CI checks passed locally."
