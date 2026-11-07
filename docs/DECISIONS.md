# Keyel — Decision Log

Requests to change/interpret the plan, design or roadmap are recorded here
(date, decision, reason). Priority when documents conflict: roadmap > plan >
design (docs/roadmap.md header).

## 2026-11-03

- **`keyel-design.md` is missing from the Desktop.**
  Errata: the Stitch export (`stitch_keyel_android_password_manager/keyel_vault/DESIGN.md`)
  is the full design-system spec (colors, typography, spacing, components).
  It was converted to **docs/design.md**; the original stays in
  `design/stitch/`. If a separate authored design doc exists, share it and we
  will reconcile.

- **License: GPL-3.0-or-later.**
  The plan offered GPL-3.0/AGPL-3.0 vs MIT. Copyleft is the norm for password
  managers (Bitwarden is GPL-compatible); picks GPL-3.0. Recorded so users of
  the crypto design can rely on it.

- **`INTERNET` permission removed from the profile manifest** (roadmap 0.1.0
  said "release/profile"). DevTools *performance profiling* may need to
  re-add it temporarily while using the inspector; this is a deliberate
  tradeoff. Debug builds keep it for hot reload; the release APK (the
  artifact users install) never gets `INTERNET`.

- **App name set to "Keyel"** (label) and applicationId `dev.agouhmad.keyel`
  per the plan §Package id.

- **Flutter template cleaned to Android-only:** `ios/`, `web/`, `macos/`,
  `windows/`, `linux/` platform folders and `rust_builder` sibling platforms
  were removed. Keeps the repo focused and the CI matrix honest.

- **Packages for 0.1.0:** flutter_riverpod 3.4, go_router 18.1, dynamic_color
  2.1, very_good_analysis 11. `dynamic_color`'s builder hands over a
  `material_ui` `ColorScheme` (transitive dep in the current ecosystem),
  which is not directly assignable to `ThemeData`; for Foundation we keep the
  brand schemes only and defer applying dynamic color to phase 0.5.0 with a
  conversion note.

- **Boring stack for crypto:** the audited RustCrypto crates (argon2,
  chacha20poly1305, ciborium, zxcvbn…) are added in the phases that use
  them (0.2.0+) so the `cargo audit` surface stays minimal today.

## 2026-11-05

- **The app uses a fixed brand palette; dynamic color is removed.**
  `dynamic_color` is gone from `pubspec.yaml` and `KeyelApp` no longer wraps
  the tree in `DynamicColorBuilder`. `KeyelColors.lightScheme` /
  `darkScheme` are explicit, role-by-role `ColorScheme` literals built from
  the Stitch export (`stitch_keyel_android_password_manager/keyel_vault/DESIGN.md`
  and the rendered screens), and `KeyelTheme.light()` / `dark()` only select
  one of them. Reason: security-critical surfaces (strength, warnings,
  TOTP countdown) must keep the same WCAG contrast and semantic meaning on
  every device; a wallpaper-derived palette cannot guarantee that. This
  supersedes the 2026-11-03 note that deferred dynamic color to 0.5.0.

- **Stitch hex values win over conflicting prose in `docs/design.md`.**
  For example the rendered light scheme uses primary `#293CA0`,
  primary-container `#4355B9`, secondary-container `#DCDEF7` and
  on-secondary-container `#5E6177`; `tertiary-container` is `#76546E` while
  `#FFD7F2` is `tertiary-fixed`. Where the prose summary disagreed, the
  exported token map was treated as authoritative.

- **Screens are presented with local demo data until storage lands.**
  `lib/features/vault/vault_entry.dart` contains ten sample entries and the
  vault, detail and editor screens read from it. Actions that need the
  encrypted vault (delete, move, duplicate, history, export/import) show an
  explanatory snackbar instead of pretending to persist. The demo layer is
  deliberately isolated so the storage phase can replace it without touching
  the design system.

- **Generator UI exposes only options the Rust API supports.**
  `rust/src/api/generator.rs` currently accepts `length` and
  `includeSymbols`; lowercase, uppercase, digits and ambiguous-character
  exclusion are always on. The screen shows those as enforced rules rather
  than passing fake toggles to the core.

- **Passphrase mode is a local placeholder.**
  It joins eight words from a bundled 128-word list using
  `Random.secure()`, roughly seven bits per word. A real passphrase
  generator (and its entropy accounting) is future Rust work; the UI and
  strength meter are already in place for it.

- **Design-system tokens are now enforced in code.**
  Radii (16/24/28/full pill), spacing, spring press scale `0.97` with
  `Cubic(0.34, 1.56, 0.64, 1)`, tonal surfaces and the Roboto Flex /
  JetBrains Mono split live in `lib/ui/theme/keyel_theme.dart` and are
  consumed through the `lib/ui/design_system/` widgets.
