import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:keyel/ui/theme/keyel_colors.dart';

/// Corner radii from the Keyel shape language.
abstract final class KeyelRadii {
  /// Small chips and inner badges.
  static const double sm = 8;

  /// Inputs and nested data blocks (16 dp).
  static const double field = 16;

  /// Credential rows and small cards.
  static const double tile = 24;

  /// Vault cards, sheets and section surfaces (28 dp).
  static const double card = 28;

  /// Bottom-sheet top corners.
  static const double sheet = 32;

  /// Full pills — CTAs, chips and search bars.
  static const double pill = 9999;
}

/// Spacing scale used by the redesigned screens.
abstract final class KeyelSpacing {
  /// 4 dp.
  static const double xs = 4;

  /// 8 dp.
  static const double sm = 8;

  /// 16 dp.
  static const double md = 16;

  /// 24 dp.
  static const double lg = 24;

  /// 32 dp.
  static const double xl = 32;

  /// 48 dp.
  static const double xxl = 48;
}

/// Motion tokens for the tactile, springy Pixel feel.
abstract final class KeyelMotion {
  /// Expressive spring used for pressed states.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Quick state change.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transition.
  static const Duration medium = Duration(milliseconds: 300);

  /// Long, expressive transition.
  static const Duration slow = Duration(milliseconds: 450);

  /// Pressed scale for cards and buttons.
  static const double pressedScale = 0.97;

  /// Returns [duration] unchanged, or [Duration.zero] when the platform asks
  /// for reduced motion (`MediaQuery.disableAnimationsOf`).
  ///
  /// Motion is decoration, never information: honouring the system "remove
  /// animations" switch keeps every state change instant for people who are
  /// sensitive to movement (roadmap 0.11, accessibility).
  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// Soft, colour-tinted ambient elevation from design.md §Elevation.
abstract final class KeyelShadows {
  /// Level-2 ambient glow.
  static List<BoxShadow> ambient(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.light
          ? const Color(0x144355B9)
          : const Color(0x66000000),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Keyel brand themes built from the fixed palette.
///
/// There is no dynamic-color path: [light] and [dark] always resolve from
/// [KeyelColors.lightScheme] / [KeyelColors.darkScheme].
abstract final class KeyelTheme {
  /// Family for UI text.
  static const fontFamily = 'RobotoFlex';

  /// Family for secrets, TOTP codes and master passphrases.
  static const monoFamily = 'JetBrainsMono';

  /// Small radius token.
  static const shapeSm = BorderRadius.all(Radius.circular(KeyelRadii.sm));

  /// Medium radius token: fields and internal blocks.
  static const shapeMd = BorderRadius.all(Radius.circular(KeyelRadii.field));

  /// Large radius token: credential cards and sheets.
  static const shapeLg = BorderRadius.all(Radius.circular(KeyelRadii.card));

  /// Full-pill radius for CTAs, chips and search bars.
  static const pillRadius = BorderRadius.all(Radius.circular(KeyelRadii.pill));

  /// Static light theme.
  static ThemeData light() => _build(KeyelColors.lightScheme);

  /// Static dark theme.
  static ThemeData dark() => _build(KeyelColors.darkScheme);

  /// A higher-contrast variant of [base] for the platform's high-contrast
  /// setting (`MediaQuery.highContrastOf`).
  ///
  /// Keyel never derives its palette from the wallpaper, so there is no
  /// platform "high contrast" scheme to adopt. Instead the low-emphasis roles
  /// that carry text and boundaries are pushed to their full-contrast
  /// counterparts: secondary text uses the on-surface colour, and the hairline
  /// outline becomes a solid rule that also draws input borders and dividers.
  static ThemeData highContrast(ThemeData base) {
    final scheme = base.colorScheme;
    final rule = scheme.brightness == Brightness.light
        ? KeyelColors.onSurfaceVariantLight
        : KeyelColors.onSurfaceVariantDark;
    final hcScheme = scheme.copyWith(
      onSurfaceVariant: scheme.onSurface,
      outline: rule,
      outlineVariant: rule,
    );
    final border = OutlineInputBorder(
      borderRadius: shapeMd,
      borderSide: BorderSide(color: rule, width: 1.5),
    );
    return base.copyWith(
      colorScheme: hcScheme,
      dividerColor: rule,
      dividerTheme: DividerThemeData(color: rule, thickness: 1.5, space: 1),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        hintStyle: base.inputDecorationTheme.hintStyle?.copyWith(
          color: hcScheme.onSurfaceVariant,
        ),
        labelStyle: base.inputDecorationTheme.labelStyle?.copyWith(
          color: hcScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Wraps [child] in the high-contrast theme when the platform asks for it.
  ///
  /// Install in `MaterialApp.builder` so every route, dialog and bottom sheet
  /// inherits the stronger palette. The ambient [Theme] is read from the
  /// builder context (which sits below MaterialApp's own theme) and only the
  /// contrast-bearing roles are overridden.
  static Widget highContrastBuilder({required Widget child}) {
    return Builder(
      builder: (context) {
        if (!MediaQuery.highContrastOf(context)) return child;
        return Theme(data: highContrast(Theme.of(context)), child: child);
      },
    );
  }

  /// Mono style for secrets, TOTP codes and master passphrases.
  static TextStyle mono(
    BuildContext context, {
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? scheme.onSurface,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    // Colour every text style with the scheme's on-surface roles so text
    // entered in fields (and any unstyled text) stays readable on the
    // container surfaces in both light and dark themes.
    final textTheme = _textTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final isLight = scheme.brightness == Brightness.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle:
            (isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
                .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
          elevation: 0,
          textStyle: textTheme.titleMedium,
          shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 56),
          elevation: 0,
          textStyle: textTheme.titleMedium,
          shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: scheme.secondaryContainer,
          side: BorderSide.none,
          minimumSize: const Size(64, 56),
          textStyle: textTheme.titleMedium,
          shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(48, 48),
          shape: const CircleBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.outline,
          fontFamily: fontFamily,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: fontFamily,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontFamily: fontFamily,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: KeyelSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: shapeMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: shapeMd,
          borderSide: BorderSide.none,
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: shapeMd,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: shapeMd,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: shapeMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: shapeMd,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: shapeLg),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.secondaryContainer,
        disabledColor: scheme.surfaceContainerHigh,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: fontFamily,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.primary,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: scheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: KeyelSpacing.sm,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.surfaceContainerLowest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outlineVariant,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        actionTextColor: scheme.inversePrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontFamily: fontFamily,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(KeyelRadii.field)),
        ),
        elevation: 6,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryFixed,
        foregroundColor: scheme.onPrimaryFixed,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        extendedTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryFixed,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.surfaceContainerLowest,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 2,
          pressedElevation: 4,
        ),
        overlayShape: const RoundSliderOverlayShape(),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary,
          fontFamily: fontFamily,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        refreshBackgroundColor: scheme.surface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KeyelRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(KeyelRadii.card)),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: fontFamily,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        textStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: 2,
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: fontFamily,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(KeyelRadii.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
          fontFamily: fontFamily,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.24),
        selectionHandleColor: scheme.primary,
      ),
    );
  }

  /// The full Keyel type scale (design.md §Typography).
  static TextTheme _textTheme() {
    TextStyle style(
      double size,
      double lineHeight,
      FontWeight weight, {
      double? tracking,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: tracking,
      );
    }

    return TextTheme(
      displayLarge: style(57, 64, FontWeight.w700, tracking: -1.5),
      displayMedium: style(45, 52, FontWeight.w700, tracking: -1),
      displaySmall: style(36, 44, FontWeight.w600, tracking: -0.5),
      headlineLarge: style(32, 40, FontWeight.w600, tracking: -0.8),
      headlineMedium: style(24, 32, FontWeight.w600, tracking: -0.4),
      headlineSmall: style(20, 28, FontWeight.w600, tracking: -0.2),
      titleLarge: style(22, 28, FontWeight.w500, tracking: -0.2),
      titleMedium: style(16, 24, FontWeight.w600),
      titleSmall: style(14, 20, FontWeight.w600),
      bodyLarge: style(16, 24, FontWeight.w400),
      bodyMedium: style(14, 20, FontWeight.w400),
      bodySmall: style(12, 16, FontWeight.w400),
      labelLarge: style(14, 20, FontWeight.w600),
      labelMedium: style(12, 16, FontWeight.w500),
      labelSmall: style(11, 16, FontWeight.w500, tracking: 0.4),
    );
  }
}
