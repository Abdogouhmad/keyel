# Keyel Roadmap: 1.12.0 — route-driven vault, resizable panes and quick actions

This phase finishes the responsive work started in 1.11.0 and adds one fast,
cross-platform interaction that feels native on both a phone and a desktop.

1. **The URL is the source of truth for the selected entry.** A deep link opens
   the vault with that entry selected; the same route renders a full-screen
   detail page on a phone and a master/detail pair on a wide window.
2. **Resizable master/detail panes.** On medium+ windows the list pane can be
   dragged to a comfortable width, and the choice is persisted.
3. **Quick actions / command palette.** One entry point for "open an entry",
   "new entry", "lock now", "generator", "settings" and "updates", available as
   a sheet on mobile and via `Ctrl/Cmd+K` on desktop.

No vault schema change, no Keyel account/server, no new broad permission and no
change to the offline-by-default promise. The lock/unlock redirect guard, the
reveal-generation guard and the fail-closed security rules from 1.11.0 stay
intact. EN/FR parity and RTL correctness remain hard requirements.

Each phase is one version. Finish the **Definition of done**, then merge to
`main`; CI cuts the tag from the `pubspec.yaml`/`CHANGELOG.md` bump. Never push
tags by hand.

---

## Definition of done

### Master/detail routing

- `/vault/entry/:id` is a canonical, shareable URL. Opening it cold on an
  unlocked vault selects that entry in the wide pane; on a compact window it
  shows the full-screen detail page.
- Opening it on a locked vault goes through the existing unlock guard and then
  lands on the requested entry, not on an empty vault.
- Selecting an entry on a wide window updates the URL; closing the detail pane
  returns to `/vault` and clears the selection. Selection is not duplicated in
  local-only state.
- The existing `/entry/:id` deep link redirects to the canonical route so old
  links and launcher intents keep working.
- Back navigation behaves naturally on both layouts: compact pops to the list,
  wide clears the selection without leaving the vault tab.

### Resizable panes

- A draggable divider between list and detail adjusts the list pane width
  between 28 % and 50 % of the effective content width, with a 320 dp floor.
- The ratio is persisted in `AppPreferences` and survives a restart.
- At 200 % text scale, or when two panes no longer fit, the layout collapses to
  one column and the stored ratio is ignored rather than clipping content.
- RTL mirrors the divider and panes; the list stays at the reading start.

### Quick actions / command palette

- A single action opens a searchable sheet/palette with entry results and the
  six static actions listed above.
- On desktop `Ctrl/Cmd+K` toggles it; on mobile a top-bar action opens the same
  UI as a bottom sheet. It is reachable without a keyboard and works in RTL.
- Executing an entry action navigates through the canonical route (so the URL
  and pane selection stay in sync); "lock now" goes through the Rust-backed
  session and clears revealed secrets.
- No secret value appears in the palette: results are titles/subtitles only,
  and the existing masked-entry rules apply.

### Verification

- `dart format --set-exit-if-changed lib test`, `flutter analyze`,
  `flutter test`, the Rust gate and all three static CI guards are green using
  the CI-pinned Flutter 3.47.9.
- `flutter gen-l10n` and FRB generation remain idempotent, EN/FR stay at parity.
- Android debug APK, Linux debug bundle and Wear Gradle unit tests pass.
- Version/changelog bump lands only after the gate is green.

---

## Deferred, not forgotten

- Arabic translation stays deferred; the RTL groundwork from 1.10/1.11 is
  complete and this phase must not regress it.
- Server-backed E2EE sync is out of scope: 1.5.0's opt-in folder sync stays the
  only sync transport.
- A real "command palette" with fuzzy ranking across all screens is out of
  scope; this phase provides exact/substring search over entries plus actions.
