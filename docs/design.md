---
name: Keyel Vault
colors:
  surface: '#fbf8ff'
  surface-dim: '#dbd9e0'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f2f9'
  surface-container: '#efedf4'
  surface-container-high: '#eae7ee'
  surface-container-highest: '#e4e1e8'
  on-surface: '#1b1b20'
  on-surface-variant: '#454652'
  inverse-surface: '#303035'
  inverse-on-surface: '#f2eff6'
  outline: '#757684'
  outline-variant: '#c5c5d4'
  surface-tint: '#4355b9'
  primary: '#293ca0'
  on-primary: '#ffffff'
  primary-container: '#4355b9'
  on-primary-container: '#d1d6ff'
  inverse-primary: '#bac3ff'
  secondary: '#5a5d72'
  on-secondary: '#ffffff'
  secondary-container: '#dcdef7'
  on-secondary-container: '#5e6177'
  tertiary: '#5c3c55'
  on-tertiary: '#ffffff'
  tertiary-container: '#76546e'
  on-tertiary-container: '#f7cceb'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dee0ff'
  primary-fixed-dim: '#bac3ff'
  on-primary-fixed: '#00105c'
  on-primary-fixed-variant: '#293ca0'
  secondary-fixed: '#dfe1fa'
  secondary-fixed-dim: '#c3c5dd'
  on-secondary-fixed: '#171a2c'
  on-secondary-fixed-variant: '#42465a'
  tertiary-fixed: '#ffd7f3'
  tertiary-fixed-dim: '#e4bad8'
  on-tertiary-fixed: '#2c1228'
  on-tertiary-fixed-variant: '#5c3d55'
  background: '#fbf8ff'
  on-background: '#1b1b20'
  surface-variant: '#e4e1e8'
typography:
  display-lg:
    fontFamily: Roboto Flex
    fontSize: 57px
    fontWeight: '700'
    lineHeight: 64px
  headline-lg:
    fontFamily: Roboto Flex
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Roboto Flex
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Roboto Flex
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Roboto Flex
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Roboto Flex
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  title-sm:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Roboto Flex
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Roboto Flex
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: Roboto Flex
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
  code-display:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  code-body:
    fontFamily: JetBrains Mono
    fontSize: 15px
    fontWeight: '500'
    lineHeight: 22px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1rem
  margin-tablet: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style
The design system embodies a calm, confident, and delightfully tactile security environment crafted specifically for Android. It blends the structural logic of Material 3 Expressive with the approachable, human warmth of Google Pixel interface styling. 

Security applications often project anxiety through cold, clinical surfaces or aggressive warning states. This design system counters that stress by offering serene, dependable interactions through expressive rounded geometries, squircle-based structural nesting, and deeply tactile interactions. The visual atmosphere communicates airtight cryptographic discipline beneath a playful, effortless exterior. Large hit targets, fluid spring physics, and gentle tonal layering establish an intuitive sense of control without visual clutter.

## Colors
The color palette relies on Material You tonal containers rather than stark line separators. Surface transitions define elevation and hierarchy, maintaining contrast ratios that strictly satisfy WCAG AAA standards for security-critical information.

### Light Scheme
- **Primary & Containers**: Primary `#4355B9`, On-Primary `#FFFFFF`, Primary Container `#DDE1FF`, On-Primary Container `#00105C`.
- **Secondary**: Secondary `#5A5D72`, On-Secondary `#FFFFFF`, Secondary Container `#DFE1F9`, On-Secondary Container `#171B2C`.
- **Tertiary**: Tertiary `#76546E`, Tertiary Container `#FFD7F2`, On-Tertiary Container `#2D1229`.
- **Surfaces**: Surface `#FBF8FF`, Surface Dim `#DCD8E0`, Surface Container Lowest `#FFFFFF`, Surface Container Low `#F5F2FA`, Surface Container `#EFEDF4`, Surface Container High `#E9E7EF`, Surface Container Highest `#E3E1E9`.
- **Outlines**: Outline `#757680`, Outline Variant `#C5C6D0`.

### Dark Scheme
- **Primary & Containers**: Primary `#BAC3FF`, On-Primary `#08218A`, Primary Container `#293CA0`, On-Primary Container `#DDE1FF`.
- **Secondary**: Secondary `#C3C5DD`, Secondary Container `#424559`, On-Secondary Container `#DFE1F9`.
- **Tertiary**: Tertiary `#E5BAD8`, Tertiary Container `#5D3D56`, On-Tertiary Container `#FFD7F2`.
- **Surfaces**: Surface `#121318`, Surface Dim `#121318`, Surface Container Lowest `#0D0E13`, Surface Container Low `#1A1B20`, Surface Container `#1F1F25`, Surface Container High `#2A2A30`, Surface Container Highest `#35343B`.
- **Outlines**: Outline `#8F909A`, Outline Variant `#45464F`.

### Semantic Password Strength & Status
- **Secure / Strong**: Light `#1B6D3A` (Container `#CEF4D2`, On-Container `#00210B`), Dark `#9BD6A5` (Container `#005324`, On-Container `#CEF4D2`).
- **Fair / Medium**: Light `#7A5900` (Container `#FFE088`, On-Container `#251A00`), Dark `#F0C05A` (Container `#5B4200`, On-Container `#FFE088`).
- **Critical / Weak**: Light `#BA1A1A` (Container `#FFDAD6`, On-Container `#410002`), Dark `#FFB4AB` (Container `#93000A`, On-Container `#FFDAD6`).

## Typography
Typography is split intentionally between human-scale interaction and high-precision data display.

- **Roboto Flex**: Powers the primary user interface. Its variable axes enable fluid transitions between subheadings, touch labels, and narrative copy while matching Android's native typographic weight hierarchy.
- **JetBrains Mono**: Reserved exclusively for sensitive vault payloads, including auto-generated master passphrases, encrypted seeds, hardware device hashes, and Time-based One-Time Password (TOTP) streams. The monospaced rhythm ensures zero character ambiguity (differentiating `0` from `O`, and `1` from `l`) and prevents visual shifting during live numerical counter updates.

## Layout & Spacing
The layout follows a responsive 4-column structure on mobile devices (width &lt; 600dp), stepping up to an 8-column layout on foldable unfolding states and small tablets (600dp to 839dp), and a 12-column dual-pane layout for large displays (&gt;= 840dp).

### Content Width & Adaptive Margins
Every screen body is wrapped in a shared `KeyelContent` column
(`lib/ui/adaptive/content.dart`) that centers the content and caps its width, so
a single column of text and controls never stretches across a tablet or desktop
window. The cap depends on the screen:

- **Form (560dp)** — focused, single-column tasks: onboarding, unlock, the
  generator and the entry editor on narrow windows.
- **Reading (720dp)** — settings, the security dashboard, list pages and the
  entry detail body.
- **Page (1000dp)** — wide, multi-column pages such as the two-column entry
  editor.

Page margins and card gaps grow with the window size class: `pageMargin` is
16dp on phones, 24dp on tablets and 32dp on large windows, and `contentGap` is
16dp on phones and 24dp above. The master/detail two-pane layout activates at
840dp (`WindowSizeClass.supportsListDetail`), with the list pane scaling
between 320dp and 420dp.

### Touch Ergonomics & Reachability
- Primary actions live in the thumb-accessible bottom quadrant. 
- Touch targets must never fall below `48dp x 48dp`, with standard operational triggers optimized to `56dp` height.
- Card interiors maintain an internal inset padding of `space-md` (16dp) to `space-lg` (24dp), creating spacious breathing room between confidential fields and action copy buttons.
- Vertical list item rhythm defaults to 72dp tall rows with an 8dp vertical gap between container blocks, avoiding accidental tap triggers in list views.

## Elevation & Depth
In alignment with Material 3 Expressive, this design system avoids harsh drop shadows and heavy linear borders, achieving separation through tonal surface mapping.

- **Level 0 (Canvas)**: Background canvas resting on `surface`.
- **Level 1 (Default Containers)**: Interactive cards, list groups, and text fields render on `surface-container`. Edges remain borderless, separated strictly by color contrast against the canvas.
- **Level 2 (Active / Raised)**: Floating navigation bars, segmented menus, and dynamic filter sheets render on `surface-container-high` accompanied by an ultra-soft, color-tinted ambient glow: `0px 4px 24px -2px rgba(67, 85, 185, 0.08)` in light mode, and `0px 4px 24px -2px rgba(0, 0, 0, 0.40)` in dark mode.
- **Level 3 (Modals & Bottom Sheets)**: Ephemeral dialogs and biometrics authentication sheets adopt `surface-container-highest` with a soft backdrop blur (`16px`) behind the scrim.
- **Micro-tactility**: Pressed states do not depress into the screen; instead, they scale down slightly (`scale(0.97)`) using an authentic spring curve (`cubic-bezier(0.34, 1.56, 0.64, 1)`), imparting a physical, rubberized touch.

## Shapes
The design embraces a hyper-rounded, expressive geometry that feels approachable and distinctly Pixel-like.

- **Full Pill (`9999px` / `rounded-full`)**: Applied to all primary CTA buttons, floating action buttons, search bars, strength indicators, and active chip tags.
- **Vault Squircles (`28dp` / `rounded-xl`)**: Applied to credential cards, bottom sheets, elevated modals, and categorized folder surfaces.
- **Item Containers (`16dp` / `rounded-lg`)**: Applied to internal nested data blocks (such as individual username/password copy rows inside an entry card).
- **Cookie & Diamond Avatars**: Domain favicons and vault category icons are cradled within non-standard organic shapes—specifically soft squircle shields, rounded diamond lozenges, and scallop cookies—instantly softening standard list views.

## Components

### Buttons
- **Primary Action (56dp)**: Full pill shape (`rounded-full`). Filled with `primary`, text/icons in `on-primary`. Generous horizontal padding (`space-lg`). Font is `title-md`.
- **Tonal Button (56dp)**: Filled with `secondary-container`, text in `on-secondary-container`. Used for secondary workflows like "Generate Alternate" or "Add Custom Field."
- **Inline Action Triggers (48dp)**: Minimum touch area strictly enforced. Tonal icon buttons inside fields (e.g., reveal password, copy to clipboard) use circular `40dp` visual hulls nested cleanly within centered `48dp` hitboxes.

### Text Fields & Secret Inputs
- **Base Input**: Minimum container height of `56dp`, corner radius `rounded-lg` (16dp). Background sits on `surface-container-high` with no perimeter line. Focused state activates a 2dp outer ring using `primary`.
- **Secret Input**: Renders with `code-body` (`JetBrains Mono`). Masked bullets display as oversized custom circular dots (`8dp`) with wide letter spacing. 
- **Quick-Action Trailing End**: Features built-in one-tap toggle for visibility mask, password generator trigger, and copy-to-clipboard pill button.

### Cards & Vault Rows
- **Credential Summary Card**: Outer corner radius `28dp` (`rounded-xl`), filled with `surface-container`. Contains service icon housed in a playful soft-diamond or squircle cookie container, primary account title (`title-md`), username (`body-md`), and a micro strength badge.
- **Revealed Vault Detail Card**: Multi-layered stack using `surface-container-low` as the chassis and nested `surface-container-highest` pill slots for individual key-value pairs (Username, Password, TOTP, Security Notes).

### Chips & Filter Pills
- **Filter Chips**: Height `40dp`, rounded to full pill (`9999px`). Unselected state relies on `surface-container` without border; selected state transitions to `secondary-container` with an internal check icon and `on-secondary-container` typography.

### TOTP Token Widget
- Prominent live display utilizing `code-display` (`JetBrains Mono`). Digit groupings split cleanly (`000 000`) for instantaneous scanning.
- Paired with an integrated circular countdown timer that depletes clockwise via a 4dp stroke colored according to the remaining window (transitions from `primary` to semantic `Weak/risk` in the final 5 seconds).

### Biometric Quick-Unlock Sheet
- Bottom-docked sheet using `rounded-xl` top corners (32dp). Background is `surface-container-high`.
- Large `72dp` tactile biometric sensor target anchored at thumb level, framed by playful, pulsating concentric squircle rings that react to haptic feedback pulses.