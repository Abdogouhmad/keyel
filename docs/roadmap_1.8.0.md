# Keyel Roadmap: 1.8.0 — optimize, harden, polish

This phase is deliberately a **quality release**, not a feature release. It
follows 1.7.0 (opt-in breach check) and has three tracks with equal weight:

1. **Optimize the codebase** — fewer rebuilds, smaller and more focused
   widgets, and tooling that keeps local and CI analysis in agreement.
2. **Strengthen security** — close the remaining clipboard/session gap and make
   the "no secrets in logs" rule mechanically enforced instead of documented.
3. **Enhance the UI** — a distinctive, information-bearing vault-posture
   surface on the security dashboard, built from existing design tokens and
   respectful of reduced motion and large text.

Nothing here introduces a new permission, a Keyel account/server, a vault
schema change, or a change to the offline-by-default promise. 1.6.0 (one-tap
lock / Quick Settings tile / shortcuts / widgets) remains a separate,
not-yet-started idea; 1.8.0 is the next version as requested.

As since 1.5.0 the release is CI-driven: bump `pubspec.yaml` and add a
`CHANGELOG.md` section, merge to `main`, and let the workflow cut `v1.8.0`.
**Never push tags by hand.**

**Rules for this phase**
- Secrets stay in Rust. No new DTO, preference, diagnostic or log field may
  carry a password, digest, vault key, or decrypted value.
- Every optimisation must preserve behaviour. Use tests, not vibes: a rebuild
  narrowing or widget split needs a widget test proving the same observable UI.
- UI work reuses `KeyelTheme` / `KeyelMotion` tokens; no new colour literals.
  Every new widget must render at 200 % text scale and with motion disabled.
- Crypto/security changes get tests before UI, per the project-wide rule.

---

## Progress tracker

| Version | Phase | Est. | Status |
|---|---|---|---|
| 1.6.0 | One-tap lock / quick access (reserved, not started) | 1 week | ☐ |
| 1.7.0 | Opt-in HIBP breach check | 1–1.5 weeks | ☑ (CI release green; manual device smoke outstanding) |
| 1.8.0 | Optimize, harden, polish | 1–1.5 weeks | ☑ (local checks green; CI release pending merge) |

Legend: ☐ todo · ◐ in progress · ☑ done

---

## 1.8.0 — Optimize, harden, polish

### Definition of done
- Hot screens subscribe only to the state they render; a regression test
  demonstrates that an unrelated session change does not rebuild a static
  subtree.
- Copied secrets are wiped on vault lock and when the app is backgrounded,
  **even when the user chose "Never clear"**; the preference only controls the
  timed wipe while the app stays unlocked and foregrounded.
- Rust and Dart sources are checked in CI for accidental secret-printing
  calls, closing the source-grep item in the threat model (T3).
- The security dashboard shows a vault-posture card that reflects real state
  (auto-lock, clipboard wipe, screenshot protection, breach opt-in), has
  semantics labels, and passes 200 % text-scale and reduced-motion tests.
- `cargo fmt --check`, `cargo clippy -D warnings`, `cargo test`,
  `flutter analyze`, `flutter test`, FRB regeneration idempotency, and both
  debug builds pass; docs, changelog and version are updated for CI.

### Knowledge
- **Rebuilds:** Riverpod 3 `ref.watch(provider.select((s) => s.field))` narrows
  rebuilds to a single field. Hot spots: `lib/features/vault/vault_screen.dart`,
  `lib/features/settings/settings_screen.dart`,
  `lib/features/security_dashboard/security_screen.dart`,
  `lib/features/security_dashboard/widgets/breach_check_row.dart`,
  `lib/data/folders_provider.dart`, `lib/data/health_provider.dart`.
- **Session:** `lib/data/vault_session_provider.dart` owns `lock()`,
  `onAppBackgrounded()` and the Rust lock-event subscription;
  `lib/core/platform/sensitive_clipboard.dart` owns the timed wipe.
- **Clipboard preference:** `AppPreferences.clipboardClearSeconds` (0 = never)
  is a non-secret `settings.json` value; `debug_bundle.dart` reports it.
- **Design tokens:** `lib/ui/theme/keyel_theme.dart` (`KeyelSpacing`,
  `KeyelRadii`, `KeyelMotion`), `lib/ui/design_system/keyel_surfaces.dart`,
  `lib/features/security_dashboard/widgets/score_card.dart` and `score_gauge.dart`.
- **Threat model:** `docs/threat-model.md` T3 (logs), T5 (shoulder surfing),
  T9 (auto-lock) and T15 (breach egress); verification map section 6.

### Todo — 1. Optimize the codebase

1. [x] Replace broad `ref.watch(vaultSessionProvider)` /
       `ref.watch(breachCheckProvider)` in hot widgets with field-level
       `select`, keeping `ref.read` in callbacks.
2. [x] Add a rebuild-counting widget test proving an unrelated session field
       change (e.g. `busy`) does not rebuild a static dashboard subtree
       (`test/rebuild_narrowing_test.dart`).
3. [x] Split the largest hand-written UI file
       (`lib/features/import_export/widgets/import_export_sheets.dart`, 825 →
       80 lines) into a facade plus `import_export_request.dart`,
       `import_export_sheet_parts.dart`, `import_export_form_sheets.dart` and
       `import_export_result_sheets.dart`. All widgets keep `const`
       constructors; `test/import_export_screen_test.dart` exercises every
       sheet (incl. 200 % text scale), proving unchanged observable UI.
4. [x] Pin the analysis toolchain by documenting the CI Flutter version in
       `analysis_options.yaml` comments and adding a local `tool/check_ci.sh`
       that runs the exact CI command set (`cargo fmt/clippy/test`,
       `flutter analyze`, `flutter test`) so version drift is caught locally.

### Todo — 2. Strengthen security

The items below were confirmed against the source in a pre-work audit; things
already implemented (backup policy, `FLAG_SECURE`, throttle, redacted session
`Debug`, k-anonymity, authenticated sync envelopes) are deliberately excluded.

1. [x] Add `SensitiveClipboard.clearOnLock()` that wipes immediately, cancels
       the pending timer, and is called from `VaultSessionNotifier.lock()`,
       `onAppBackgrounded()` and Rust lock events. "Never clear" now controls
       only the timed wipe.
2. [x] Add tests: lock wipes even with `clipboardClearSeconds = 0`;
       backgrounding wipes before the auto-lock delay elapses.
3. [x] **P1 — Autofill WebView spoofing.** `keyel_core::autofill::match_quality`
       falls through to web-domain matching when a `packageName` is present but
       has no `androidapp://` match. A malicious app can host `victim.com` in a
       WebView and harvest the credential. If a package is present and has no
       match, return no `Exact`/`SameSite` candidate; only match domains when no
       package is supplied. Add a regression test with
       `{package: com.evil, web_domain: victim.com}`.
4. [x] **P1 — OTA installs with no checksum.** `downloadRelease` accepts a
       missing/invalid `sha256` (notably the beta single-release path) and
       `installUpdate` never checks `isChecksumVerified`. Fail closed: require
       a 64-hex checksum, delete the download and throw when it is absent, and
       gate install on verification. Add a `MockClient` test.
5. [x] **P1 — Auto-lock is absent from the autofill and passkey entrypoints.**
       Only `main.dart` wraps the app in `AutoLockHost`; `main_autofill.dart`
       and `main_passkey.dart` run `ProviderScope` directly, so backgrounding
       never starts the timer or wipes the clipboard. Wrap both trees.
6. [x] **P1 — Secret DTOs leak via derived `Debug`.** `EntryDraft`,
       `CustomFieldDraft.value`, `TotpConfigDto.secret` and
       `PasskeyCreateDto.private_key` derive `Debug` and would print plaintext,
       contradicting the redaction claim in T3. Implement manual redacted
       `Debug` impls and add format tests.
7. [x] **P2 — Android 13 sensitive-clipboard flag is documented but missing.**
       Add `copySensitive`/`clearSensitive` to the `keyel/platform` channel with
       `ClipDescription.EXTRA_IS_SENSITIVE`, called from `SensitiveClipboard`.
8. [x] **P2 — Zeroize transient secret buffers.** `GeneratedPasskey`
       private keys and the normalized recovery-key / pairing-code strings are
       ordinary buffers that outlive their `Zeroizing` wrappers.
9. [x] **P2 — CSV export file creation.** Use `create_new` + mode `0o600` on
       Unix and wipe imported plaintext buffers.
10. [x] Add `tool/check_no_secret_logs.sh` (Rust `println!/eprintln!/dbg!/log::`,
        Dart `print/debugPrint` outside an explicit allow-list) and wire it into
        both CI workflows. Keep the single allowed `debugPrint` in `main.dart`
        and document why.
11. [x] Update `docs/threat-model.md` T3/T5/T7/T13 and the verification map to
        reflect the new controls; record the decisions in `docs/DECISIONS.md`.
12. [x] **P0 — Card/CVV/note reveals never auto-hide.** `EntryDetailController`
        only times password and hidden-field reveals; card and note reveals stay
        on screen indefinitely and no reveal is cleared on lock/background.
        Added `hideAll()`, a shared 15 s timer for all reveals, a `ref.listen` on
        session status in `EntryDetailScreen`, and the missing `mounted` guard in
        `_copy`. Tested with `fakeAsync` (auto-hide) and a direct `hideAll()` call
        (`test/entry_detail_reveal_test.dart`).
13. [x] **P0 — Generator and recovery-key copies bypass `SensitiveClipboard`.**
        `generator_screen.dart` and the create-vault / recovery-steps widgets
        called raw `Clipboard.setData`, so the timed-wipe preference was skipped.
        Routed them through `SensitiveClipboard.instance.copy()` with the clear
        hint.
14. [x] **P1 — Reveal hygiene in forms.** `KeyelPasswordField` claimed to re-mask
        on focus loss but didn't; password generation revealed immediately.
        Reveals now re-mask automatically after 15 s and generation keeps the
        field masked. Tested in `test/password_field_test.dart`.

### Todo — 3. Enhance the UI

1. [x] Add `lib/features/security_dashboard/widgets/security_posture_card.dart`:
       a "vault posture" card with four state-bearing seals (auto-lock,
       clipboard wipe, screenshot protection, breach check) derived from real
       providers, using existing colour/radius/spacing tokens. A plain
       `SecurityPosture` snapshot keeps the card testable without providers.
2. [x] Give the card one signature motion: a restrained staggered reveal of
       the seals on first build, resolved through `KeyelMotion.resolve` so it
       disappears under reduced motion and the in-app animation setting.
3. [x] Place the card on `SecurityScreen` above the score card, with semantics
       labels and a single "Review settings" action.
4. [x] Add widget tests for all-on / mixed states, 200 % text scale, and
       reduced motion (`test/security_posture_card_test.dart`); the screen
       layout test still passes with the card in place.
5. [x] **P1 — AMOLED theme is only half-applied.** `_build` now resolves one
       `scheme` up front and every component theme reads it; asserted for
       scaffold/app bar/card/sheet/dialog/input in `keyel_theme_test.dart`.
6. [x] **P1 — Ctrl/Cmd+F is dead.** Added `vaultSearchFocusProvider` so the
       shell's `onFind` action can focus the shared `KeyelSearchField` node;
       `test/adaptive_shell_test.dart` sends Ctrl+F and asserts focus.
7. [x] **P1 — Medium rail overflows.** `_RailItem.itemWidth` is now derived
       from the rail width; the medium-window test asserts no overflow and the
       checked-in goldens were refreshed.
8. [x] **P1 — Unsaved-changes guard.** `EntryEditScreen` snapshots all editor
       fields after load and wraps the route in a `PopScope` using
       `KeyelConfirmDialog`. `test/entry_edit_unsaved_test.dart` covers clean
       pop, cancel and confirm-discard.
9. [x] **P2 — Help placeholder snackbar.** Replaced with a local, offline
       `settings_help_sheet.dart` covering the security model, shortcuts and
       recovery; no "future update" copy remains. Tested at 200 % text scale.
10. [x] **P1 — Search debounce + generation guard.** `VaultListController`
        debounces typed queries by 200 ms, uses a load generation counter to
        discard stale responses, and prunes selection with one visible-id `Set`.
        `test/vault_list_search_test.dart` covers all three.

### Risks and mitigations
- **Rebuild narrowing changes behaviour:** keep `watch` where a value actually
  drives the UI; tests assert the same rendered text and actions.
- **Clipboard wipe surprises a user on "Never":** the UI copy must say the
  preference controls only the *timed* wipe, and that lock/background always
  clears. Update the settings dialog text.
- **Log guard produces false positives:** the script uses an explicit
  allow-list with file:line comments; CI runs it on every push so drift is
  visible immediately.
- **Posture card lies about state:** it reads the same preferences and session
  provider the features themselves use; no duplicated state.

### Sequencing notes
- Security first (tests before behaviour change), then optimisation, then UI,
  so every UI surface reads stable state.
- No schema change: the posture card is derived from existing non-secret
  preferences and providers, so v1–v5 vaults and 1.5.0 sync payloads are
  unaffected.
- Version bump and changelog come last, after the full suite is green.
