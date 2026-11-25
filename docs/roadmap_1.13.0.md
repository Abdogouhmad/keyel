# Keyel Roadmap: 1.13.0 — ranked command palette

This phase upgrades the 1.12.0 quick-actions palette from exact/substring
matching into a real, keyboard-first command palette. It is the first item in
`docs/roadmap_1.12.0.md`'s "Deferred, not forgotten" list.

1. **Fuzzy ranking over secret-free metadata.** Title and subtitle matches are
   accent-insensitive, token-based and prefer exact/prefix matches over loose
   subsequences. Favourites and recently opened entries break ties.
2. **Keyboard-navigable results.** `↑`/`↓` move the selection, `Enter` runs it,
   `Esc` closes, and `Ctrl/Cmd+K` still toggles. The selected row scrolls into
   view and is announced by the platform semantics.
3. **Remembered recency.** The last eight entry ids opened from the palette are
   kept in `settings.json` as opaque, non-secret UI preferences.

No vault schema change, no Keyel account/server, no new permission and no
change to the offline-by-default promise. The vault key stays in Rust, the
palette consumes only secret-free summaries, the lock/unlock guard and the
reveal-generation guard from 1.11.0 stay intact. EN/FR parity, RTL correctness
and 200 % text scale remain hard requirements.

Each phase is one version. Finish the **Definition of done**, then merge to
`main`; CI cuts the tag from the `pubspec.yaml`/`CHANGELOG.md` bump. Never push
tags by hand.

---

## Definition of done

### Ranking

- Typing a query matches entries and static actions by token, case- and
  accent-insensitively; a subsequence such as `atm` finds "Account Manager".
- Exact prefix and word-start hits outrank mid-word hits; mid-word hits outrank
  loose subsequences. Favourites and recent entries win equal-score ties.
- With an empty query the six static actions keep their 1.12.0 order at the top,
  followed by entries.
- Ranking runs only over `EntrySummaryDto` metadata (id/title/subtitle/favourite
  flag). No password, note, TOTP, full entry detail or secret reaches the
  palette or its tests.

### Keyboard and accessibility

- `↑`/`↓` move through the visible rows and scroll the selection into view;
  `Enter` activates the selected row; `Esc` and `Ctrl/Cmd+K` close an open
  palette exactly as in 1.12.0.
- The selected row is visually and semantically selected, works with TalkBack,
  and does not depend on pointer input.
- At 200 % text scale the sheet and its list scroll instead of clipping; RTL
  mirrors icons and text while keeping the same row order and keyboard
  behaviour.

### Recency and preferences

- Opening an entry from the palette remembers its id, capped at eight unique
  ids, newest first; ids are never passwords or vault payload data.
- `settings.json` round-trips recent ids and rejects corrupt values without
  affecting any fail-closed default (autofill, screenshot, unlock throttle).

### Verification

- `dart format --set-exit-if-changed lib test`, `flutter analyze`,
  `flutter test`, the Rust gate and all three static CI guards are green using
  the CI-pinned Flutter 3.47.9 at `/tmp/opencode/flutter-3.47.9/bin/flutter`.
- `flutter gen-l10n` and FRB generation remain idempotent; EN and FR stay at
  exact key parity.
- Android debug APK, Linux debug bundle and Wear Gradle unit tests pass.
- Version/changelog bump lands only after the gate is green.

---

## Deferred, not forgotten

- Arabic translation remains deferred; the RTL groundwork must not regress.
- Server-backed E2EE sync remains out of scope: 1.5.0's opt-in folder sync is
  still the only sync transport.
- Ranking across non-vault screens (settings, generator, security dashboard)
  stays out of scope; this phase ranks palette entries and the six existing
  static actions only.
- 1.7.0's manual on-device breach smoke is unchanged by this phase.
