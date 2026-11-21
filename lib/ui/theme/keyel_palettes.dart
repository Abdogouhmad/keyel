import 'package:flutter/material.dart';

import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_colors.dart';

/// Supported accent palettes.
///
/// [indigo] preserves the classic hand-tuned Keyel brand schemes. Other
/// palettes are generated from curated seed colors so security/status
/// semantics remain consistent.
enum KeyelPalette {
  /// Classic Keyel indigo palette.
  indigo,

  /// Ocean blue palette.
  ocean,

  /// Forest green palette.
  forest,

  /// Teal palette.
  teal,

  /// Amber palette.
  amber,

  /// Rose palette.
  rose,

  /// Violet palette.
  violet,

  /// Neutral graphite palette.
  graphite,
}

/// Metadata and helpers for [KeyelPalette].
extension KeyelPaletteX on KeyelPalette {
  /// Stable identifier persisted in preferences.
  String get id => switch (this) {
    KeyelPalette.indigo => 'indigo',
    KeyelPalette.ocean => 'ocean',
    KeyelPalette.forest => 'forest',
    KeyelPalette.teal => 'teal',
    KeyelPalette.amber => 'amber',
    KeyelPalette.rose => 'rose',
    KeyelPalette.violet => 'violet',
    KeyelPalette.graphite => 'graphite',
  };

  /// Human-readable label for the appearance picker.
  String get label {
    final l10n = currentL10n;
    return switch (this) {
      KeyelPalette.indigo => l10n.corePaletteIndigo,
      KeyelPalette.ocean => l10n.corePaletteOcean,
      KeyelPalette.forest => l10n.corePaletteForest,
      KeyelPalette.teal => l10n.corePaletteTeal,
      KeyelPalette.amber => l10n.corePaletteAmber,
      KeyelPalette.rose => l10n.corePaletteRose,
      KeyelPalette.violet => l10n.corePaletteViolet,
      KeyelPalette.graphite => l10n.corePaletteGraphite,
    };
  }

  /// Short description shown in the appearance picker.
  String get description {
    final l10n = currentL10n;
    return switch (this) {
      KeyelPalette.indigo => l10n.corePaletteIndigoDesc,
      KeyelPalette.ocean => l10n.corePaletteOceanDesc,
      KeyelPalette.forest => l10n.corePaletteForestDesc,
      KeyelPalette.teal => l10n.corePaletteTealDesc,
      KeyelPalette.amber => l10n.corePaletteAmberDesc,
      KeyelPalette.rose => l10n.corePaletteRoseDesc,
      KeyelPalette.violet => l10n.corePaletteVioletDesc,
      KeyelPalette.graphite => l10n.corePaletteGraphiteDesc,
    };
  }

  /// Seed color used to generate non-classic schemes and previews.
  Color get seed => switch (this) {
    KeyelPalette.indigo => KeyelColors.primaryLight,
    KeyelPalette.ocean => const Color(0xFF1565C0),
    KeyelPalette.forest => const Color(0xFF2E7D32),
    KeyelPalette.teal => const Color(0xFF00796B),
    KeyelPalette.amber => const Color(0xFFB26A00),
    KeyelPalette.rose => const Color(0xFFC2185B),
    KeyelPalette.violet => const Color(0xFF6A1B9A),
    KeyelPalette.graphite => const Color(0xFF546E7A),
  };

  /// Preview color for swatches.
  Color get preview => seed;

  /// Light scheme for this palette.
  ColorScheme lightScheme() {
    if (this == KeyelPalette.indigo) return KeyelColors.lightScheme;
    return ColorScheme.fromSeed(seedColor: seed);
  }

  /// Dark scheme for this palette.
  ColorScheme darkScheme() {
    if (this == KeyelPalette.indigo) return KeyelColors.darkScheme;
    return ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
  }

  /// Resolve a persisted palette id, falling back to [KeyelPalette.indigo].
  static KeyelPalette fromId(String? id) {
    for (final palette in KeyelPalette.values) {
      if (palette.id == id) return palette;
    }
    return KeyelPalette.indigo;
  }

  /// Resolve a persisted theme mode id.
  static ThemeMode themeModeFromId(String? id) => switch (id) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Persisted id for a [ThemeMode].
  static String themeModeToId(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  /// Human-readable label for a [ThemeMode].
  static String themeModeLabel(ThemeMode mode) {
    final l10n = currentL10n;
    return switch (mode) {
      ThemeMode.light => l10n.coreThemeLight,
      ThemeMode.dark => l10n.coreThemeDark,
      ThemeMode.system => l10n.coreThemeSystem,
    };
  }
}
