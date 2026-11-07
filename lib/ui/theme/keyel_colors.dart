import 'package:flutter/material.dart';

/// The fixed Keyel brand palette.
///
/// Values come from the Stitch design export
/// (`stitch_keyel_android_password_manager/keyel_vault/DESIGN.md`) and the
/// rendered screens. Light and dark schemes are written out explicitly — the
/// app never derives colours from the device wallpaper.
///
/// Dynamic color (`dynamic_color` / Material You) is intentionally absent:
/// security status colours, password-strength tones and WCAG contrast must be
/// identical on every device. See `docs/DECISIONS.md` (2026-11-05).
abstract final class KeyelColors {
  // -------------------------------------------------------------------------
  // Light scheme
  // -------------------------------------------------------------------------

  /// Primary brand indigo used for CTAs and focused controls.
  static const primaryLight = Color(0xFF293CA0);

  /// Text and icons placed on [primaryLight].
  static const onPrimaryLight = Color(0xFFFFFFFF);

  /// Expressive indigo container (avatars, highlighted blocks).
  static const primaryContainerLight = Color(0xFF4355B9);

  /// Text and icons placed on [primaryContainerLight].
  static const onPrimaryContainerLight = Color(0xFFD1D6FF);

  /// Fixed pale indigo — FAB, selected filters and tonal chips.
  static const primaryFixedLight = Color(0xFFDEE0FF);

  /// Dimmed fixed indigo.
  static const primaryFixedDimLight = Color(0xFFBAC3FF);

  /// High-contrast text on [primaryFixedLight].
  static const onPrimaryFixedLight = Color(0xFF00105C);

  /// Secondary slate used for supporting labels.
  static const secondaryLight = Color(0xFF5A5D72);

  /// Content colour on the secondary (light).
  static const onSecondaryLight = Color(0xFFFFFFFF);

  /// The secondary container (light) tone.
  static const secondaryContainerLight = Color(0xFFDCDEF7);

  /// Content colour on the secondary container (light).
  static const onSecondaryContainerLight = Color(0xFF5E6177);

  /// The secondary fixed (light) tone.
  static const secondaryFixedLight = Color(0xFFDFE1FA);

  /// The secondary fixed dim (light) tone.
  static const secondaryFixedDimLight = Color(0xFFC3C5DD);

  /// Content colour on the secondary fixed (light).
  static const onSecondaryFixedLight = Color(0xFF171A2C);

  /// Content colour on the secondary fixed variant (light).
  static const onSecondaryFixedVariantLight = Color(0xFF42465A);

  /// Tertiary plum — accent shapes, secret tokens and notes.
  static const tertiaryLight = Color(0xFF5C3C55);

  /// Content colour on the tertiary (light).
  static const onTertiaryLight = Color(0xFFFFFFFF);

  /// The tertiary container (light) tone.
  static const tertiaryContainerLight = Color(0xFF76546E);

  /// Content colour on the tertiary container (light).
  static const onTertiaryContainerLight = Color(0xFFF7CCEB);

  /// The tertiary fixed (light) tone.
  static const tertiaryFixedLight = Color(0xFFFFD7F3);

  /// The tertiary fixed dim (light) tone.
  static const tertiaryFixedDimLight = Color(0xFFE4BAD8);

  /// Content colour on the tertiary fixed (light).
  static const onTertiaryFixedLight = Color(0xFF2C1228);

  /// Content colour on the tertiary fixed variant (light).
  static const onTertiaryFixedVariantLight = Color(0xFF5C3D55);

  /// Error / critical actions.
  static const errorLight = Color(0xFFBA1A1A);

  /// Content colour on the error (light).
  static const onErrorLight = Color(0xFFFFFFFF);

  /// The error container (light) tone.
  static const errorContainerLight = Color(0xFFFFDAD6);

  /// Content colour on the error container (light).
  static const onErrorContainerLight = Color(0xFF93000A);

  /// Tonal canvas and containers.
  static const surfaceLight = Color(0xFFFBF8FF);

  /// The surface dim (light) tone.
  static const surfaceDimLight = Color(0xFFDBD9E0);

  /// The surface bright (light) tone.
  static const surfaceBrightLight = Color(0xFFFBF8FF);

  /// The surface container lowest (light) tone.
  static const surfaceContainerLowestLight = Color(0xFFFFFFFF);

  /// The surface container low (light) tone.
  static const surfaceContainerLowLight = Color(0xFFF5F2F9);

  /// The surface container (light) tone.
  static const surfaceContainerLight = Color(0xFFEFEDF4);

  /// The surface container high (light) tone.
  static const surfaceContainerHighLight = Color(0xFFEAE7EE);

  /// The surface container highest (light) tone.
  static const surfaceContainerHighestLight = Color(0xFFE4E1E8);

  /// Content colour on the surface (light).
  static const onSurfaceLight = Color(0xFF1B1B20);

  /// Content colour on the surface variant (light).
  static const onSurfaceVariantLight = Color(0xFF454652);

  /// The inverse surface (light) tone.
  static const inverseSurfaceLight = Color(0xFF303035);

  /// Content colour on the inverse surface (light).
  static const onInverseSurfaceLight = Color(0xFFF2EFF6);

  /// The outline (light) tone.
  static const outlineLight = Color(0xFF757684);

  /// The outline variant (light) tone.
  static const outlineVariantLight = Color(0xFFC5C5D4);

  /// The surface tint (light) tone.
  static const surfaceTintLight = Color(0xFF4355B9);

  /// The inverse primary (light) tone.
  static const inversePrimaryLight = Color(0xFFBAC3FF);

  // -------------------------------------------------------------------------
  // Dark scheme
  // -------------------------------------------------------------------------

  /// The primary (dark) tone.
  static const primaryDark = Color(0xFFBAC3FF);

  /// Content colour on the primary (dark).
  static const onPrimaryDark = Color(0xFF08218A);

  /// The primary container (dark) tone.
  static const primaryContainerDark = Color(0xFF293CA0);

  /// Content colour on the primary container (dark).
  static const onPrimaryContainerDark = Color(0xFFDDE1FF);

  /// The primary fixed (dark) tone.
  static const primaryFixedDark = Color(0xFFDEE0FF);

  /// The primary fixed dim (dark) tone.
  static const primaryFixedDimDark = Color(0xFFBAC3FF);

  /// Content colour on the primary fixed (dark).
  static const onPrimaryFixedDark = Color(0xFF00105C);

  /// Content colour on the primary fixed variant (dark).
  static const onPrimaryFixedVariantDark = Color(0xFF293CA0);

  /// The secondary (dark) tone.
  static const secondaryDark = Color(0xFFC3C5DD);

  /// Content colour on the secondary (dark).
  static const onSecondaryDark = Color(0xFF171A2C);

  /// The secondary container (dark) tone.
  static const secondaryContainerDark = Color(0xFF424559);

  /// Content colour on the secondary container (dark).
  static const onSecondaryContainerDark = Color(0xFFDFE1F9);

  /// The secondary fixed (dark) tone.
  static const secondaryFixedDark = Color(0xFFDFE1FA);

  /// The secondary fixed dim (dark) tone.
  static const secondaryFixedDimDark = Color(0xFFC3C5DD);

  /// Content colour on the secondary fixed (dark).
  static const onSecondaryFixedDark = Color(0xFF171A2C);

  /// Content colour on the secondary fixed variant (dark).
  static const onSecondaryFixedVariantDark = Color(0xFF42465A);

  /// The tertiary (dark) tone.
  static const tertiaryDark = Color(0xFFE5BAD8);

  /// Content colour on the tertiary (dark).
  static const onTertiaryDark = Color(0xFF2D1229);

  /// The tertiary container (dark) tone.
  static const tertiaryContainerDark = Color(0xFF5D3D56);

  /// Content colour on the tertiary container (dark).
  static const onTertiaryContainerDark = Color(0xFFFFD7F2);

  /// The tertiary fixed (dark) tone.
  static const tertiaryFixedDark = Color(0xFFFFD7F3);

  /// The tertiary fixed dim (dark) tone.
  static const tertiaryFixedDimDark = Color(0xFFE4BAD8);

  /// Content colour on the tertiary fixed (dark).
  static const onTertiaryFixedDark = Color(0xFF2C1228);

  /// Content colour on the tertiary fixed variant (dark).
  static const onTertiaryFixedVariantDark = Color(0xFF5C3D55);

  /// The error (dark) tone.
  static const errorDark = Color(0xFFFFB4AB);

  /// Content colour on the error (dark).
  static const onErrorDark = Color(0xFF690005);

  /// The error container (dark) tone.
  static const errorContainerDark = Color(0xFF93000A);

  /// Content colour on the error container (dark).
  static const onErrorContainerDark = Color(0xFFFFDAD6);

  /// The surface (dark) tone.
  static const surfaceDark = Color(0xFF121318);

  /// The surface dim (dark) tone.
  static const surfaceDimDark = Color(0xFF121318);

  /// The surface bright (dark) tone.
  static const surfaceBrightDark = Color(0xFF38393F);

  /// The surface container lowest (dark) tone.
  static const surfaceContainerLowestDark = Color(0xFF0D0E13);

  /// The surface container low (dark) tone.
  static const surfaceContainerLowDark = Color(0xFF1A1B20);

  /// The surface container (dark) tone.
  static const surfaceContainerDark = Color(0xFF1F1F25);

  /// The surface container high (dark) tone.
  static const surfaceContainerHighDark = Color(0xFF2A2A30);

  /// The surface container highest (dark) tone.
  static const surfaceContainerHighestDark = Color(0xFF35343B);

  /// Content colour on the surface (dark).
  static const onSurfaceDark = Color(0xFFE4E1E9);

  /// Content colour on the surface variant (dark).
  static const onSurfaceVariantDark = Color(0xFFC5C6D0);

  /// The inverse surface (dark) tone.
  static const inverseSurfaceDark = Color(0xFFE4E1E9);

  /// Content colour on the inverse surface (dark).
  static const onInverseSurfaceDark = Color(0xFF303035);

  /// The outline (dark) tone.
  static const outlineDark = Color(0xFF8F909A);

  /// The outline variant (dark) tone.
  static const outlineVariantDark = Color(0xFF45464F);

  /// The surface tint (dark) tone.
  static const surfaceTintDark = Color(0xFFBAC3FF);

  /// The inverse primary (dark) tone.
  static const inversePrimaryDark = Color(0xFF293CA0);

  // -------------------------------------------------------------------------
  // Semantic password strength & health
  // -------------------------------------------------------------------------

  /// The strong (light) tone.
  static const strongLight = Color(0xFF1B6D3A);

  /// The strong container (light) tone.
  static const strongContainerLight = Color(0xFFCEF4D2);

  /// Content colour on the strong container (light).
  static const onStrongContainerLight = Color(0xFF00210B);

  /// The fair (light) tone.
  static const fairLight = Color(0xFF7A5900);

  /// The fair container (light) tone.
  static const fairContainerLight = Color(0xFFFFE088);

  /// Content colour on the fair container (light).
  static const onFairContainerLight = Color(0xFF251A00);

  /// The weak (light) tone.
  static const weakLight = Color(0xFFBA1A1A);

  /// The weak container (light) tone.
  static const weakContainerLight = Color(0xFFFFDAD6);

  /// Content colour on the weak container (light).
  static const onWeakContainerLight = Color(0xFF410002);

  /// The strong (dark) tone.
  static const strongDark = Color(0xFF9BD6A5);

  /// The strong container (dark) tone.
  static const strongContainerDark = Color(0xFF005324);

  /// Content colour on the strong container (dark).
  static const onStrongContainerDark = Color(0xFFCEF4D2);

  /// The fair (dark) tone.
  static const fairDark = Color(0xFFF0C05A);

  /// The fair container (dark) tone.
  static const fairContainerDark = Color(0xFF5B4200);

  /// Content colour on the fair container (dark).
  static const onFairContainerDark = Color(0xFFFFE088);

  /// The weak (dark) tone.
  static const weakDark = Color(0xFFFFB4AB);

  /// The weak container (dark) tone.
  static const weakContainerDark = Color(0xFF93000A);

  /// Content colour on the weak container (dark).
  static const onWeakContainerDark = Color(0xFFFFDAD6);

  // -------------------------------------------------------------------------
  // Role schemes
  // -------------------------------------------------------------------------

  /// The complete light [ColorScheme], written out role by role.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: onPrimaryLight,
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: onPrimaryContainerLight,
    primaryFixed: primaryFixedLight,
    primaryFixedDim: primaryFixedDimLight,
    onPrimaryFixed: onPrimaryFixedLight,
    onPrimaryFixedVariant: primaryLight,
    secondary: secondaryLight,
    onSecondary: onSecondaryLight,
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: onSecondaryContainerLight,
    secondaryFixed: secondaryFixedLight,
    secondaryFixedDim: secondaryFixedDimLight,
    onSecondaryFixed: onSecondaryFixedLight,
    onSecondaryFixedVariant: onSecondaryFixedVariantLight,
    tertiary: tertiaryLight,
    onTertiary: onTertiaryLight,
    tertiaryContainer: tertiaryContainerLight,
    onTertiaryContainer: onTertiaryContainerLight,
    tertiaryFixed: tertiaryFixedLight,
    tertiaryFixedDim: tertiaryFixedDimLight,
    onTertiaryFixed: onTertiaryFixedLight,
    onTertiaryFixedVariant: onTertiaryFixedVariantLight,
    error: errorLight,
    onError: onErrorLight,
    errorContainer: errorContainerLight,
    onErrorContainer: onErrorContainerLight,
    surface: surfaceLight,
    onSurface: onSurfaceLight,
    surfaceDim: surfaceDimLight,
    surfaceBright: surfaceBrightLight,
    surfaceContainerLowest: surfaceContainerLowestLight,
    surfaceContainerLow: surfaceContainerLowLight,
    surfaceContainer: surfaceContainerLight,
    surfaceContainerHigh: surfaceContainerHighLight,
    surfaceContainerHighest: surfaceContainerHighestLight,
    onSurfaceVariant: onSurfaceVariantLight,
    outline: outlineLight,
    outlineVariant: outlineVariantLight,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: inverseSurfaceLight,
    onInverseSurface: onInverseSurfaceLight,
    inversePrimary: inversePrimaryLight,
    surfaceTint: surfaceTintLight,
  );

  /// The complete dark [ColorScheme], written out role by role.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: onPrimaryDark,
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: onPrimaryContainerDark,
    primaryFixed: primaryFixedDark,
    primaryFixedDim: primaryFixedDimDark,
    onPrimaryFixed: onPrimaryFixedDark,
    onPrimaryFixedVariant: onPrimaryFixedVariantDark,
    secondary: secondaryDark,
    onSecondary: onSecondaryDark,
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: onSecondaryContainerDark,
    secondaryFixed: secondaryFixedDark,
    secondaryFixedDim: secondaryFixedDimDark,
    onSecondaryFixed: onSecondaryFixedDark,
    onSecondaryFixedVariant: onSecondaryFixedVariantDark,
    tertiary: tertiaryDark,
    onTertiary: onTertiaryDark,
    tertiaryContainer: tertiaryContainerDark,
    onTertiaryContainer: onTertiaryContainerDark,
    tertiaryFixed: tertiaryFixedDark,
    tertiaryFixedDim: tertiaryFixedDimDark,
    onTertiaryFixed: onTertiaryFixedDark,
    onTertiaryFixedVariant: onTertiaryFixedVariantDark,
    error: errorDark,
    onError: onErrorDark,
    errorContainer: errorContainerDark,
    onErrorContainer: onErrorContainerDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceDim: surfaceDimDark,
    surfaceBright: surfaceBrightDark,
    surfaceContainerLowest: surfaceContainerLowestDark,
    surfaceContainerLow: surfaceContainerLowDark,
    surfaceContainer: surfaceContainerDark,
    surfaceContainerHigh: surfaceContainerHighDark,
    surfaceContainerHighest: surfaceContainerHighestDark,
    onSurfaceVariant: onSurfaceVariantDark,
    outline: outlineDark,
    outlineVariant: outlineVariantDark,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: inverseSurfaceDark,
    onInverseSurface: onInverseSurfaceDark,
    inversePrimary: inversePrimaryDark,
    surfaceTint: surfaceTintDark,
  );

  /// Password-strength and vault-health tones for the active brightness.
  static KeyelSemanticColors semanticsFor(Brightness brightness) =>
      brightness == Brightness.light ? lightSemantics : darkSemantics;

  /// Light semantic tones.
  static const lightSemantics = KeyelSemanticColors(
    strong: strongLight,
    strongContainer: strongContainerLight,
    onStrongContainer: onStrongContainerLight,
    fair: fairLight,
    fairContainer: fairContainerLight,
    onFairContainer: onFairContainerLight,
    weak: weakLight,
    weakContainer: weakContainerLight,
    onWeakContainer: onWeakContainerLight,
  );

  /// Dark semantic tones.
  static const darkSemantics = KeyelSemanticColors(
    strong: strongDark,
    strongContainer: strongContainerDark,
    onStrongContainer: onStrongContainerDark,
    fair: fairDark,
    fairContainer: fairContainerDark,
    onFairContainer: onFairContainerDark,
    weak: weakDark,
    weakContainer: weakContainerDark,
    onWeakContainer: onWeakContainerDark,
  );
}

/// Security-specific colours that do not map to a Material [ColorScheme] role.
class KeyelSemanticColors {
  /// Creates a semantic tone set.
  const new({
    required this.strong,
    required this.strongContainer,
    required this.onStrongContainer,
    required this.fair,
    required this.fairContainer,
    required this.onFairContainer,
    required this.weak,
    required this.weakContainer,
    required this.onWeakContainer,
  });

  /// Secure / strong password accent.
  final Color strong;

  /// Secure / strong tonal container.
  final Color strongContainer;

  /// Content on [strongContainer].
  final Color onStrongContainer;

  /// Fair / medium password accent.
  final Color fair;

  /// Fair / medium tonal container.
  final Color fairContainer;

  /// Content on [fairContainer].
  final Color onFairContainer;

  /// Critical / weak password accent.
  final Color weak;

  /// Critical / weak tonal container.
  final Color weakContainer;

  /// Content on [weakContainer].
  final Color onWeakContainer;
}

/// Convenient semantic access from any [ColorScheme].
extension KeyelSemanticColorsX on ColorScheme {
  /// Semantic strength/health tones for this scheme's brightness.
  KeyelSemanticColors get keyel => KeyelColors.semanticsFor(brightness);

  /// Secure / strong accent.
  Color get strong => keyel.strong;

  /// Secure / strong container.
  Color get strongContainer => keyel.strongContainer;

  /// Content on [strongContainer].
  Color get onStrongContainer => keyel.onStrongContainer;

  /// Fair / medium accent.
  Color get fair => keyel.fair;

  /// Fair / medium container.
  Color get fairContainer => keyel.fairContainer;

  /// Content on [fairContainer].
  Color get onFairContainer => keyel.onFairContainer;

  /// Critical / weak accent.
  Color get weak => keyel.weak;

  /// Critical / weak container.
  Color get weakContainer => keyel.weakContainer;

  /// Content on [weakContainer].
  Color get onWeakContainer => keyel.onWeakContainer;
}
