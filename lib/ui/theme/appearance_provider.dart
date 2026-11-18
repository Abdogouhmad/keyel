import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/ui/theme/keyel_palettes.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Immutable appearance settings used by the app theme and UI preferences.
class AppearanceState {
  /// Creates an appearance snapshot.
  const new({
    required this.themeMode,
    required this.palette,
    required this.amoledBlack,
    required this.animationsEnabled,
    required this.hapticsEnabled,
  });

  /// Builds state from persisted [AppPreferences].
  factory fromPrefs(AppPreferences prefs) {
    return AppearanceState(
      themeMode: KeyelPaletteX.themeModeFromId(prefs.themeMode),
      palette: KeyelPaletteX.fromId(prefs.paletteId),
      amoledBlack: prefs.amoledBlack,
      animationsEnabled: prefs.animationsEnabled,
      hapticsEnabled: prefs.hapticsEnabled,
    );
  }

  /// Selected theme mode.
  final ThemeMode themeMode;

  /// Selected accent palette.
  final KeyelPalette palette;

  /// Whether dark mode uses pure black surfaces.
  final bool amoledBlack;

  /// Whether in-app animations are enabled.
  final bool animationsEnabled;

  /// Whether haptic feedback is enabled.
  final bool hapticsEnabled;

  /// Light theme for the current palette.
  ThemeData get lightTheme => KeyelTheme.light(palette: palette);

  /// Dark theme for the current palette and AMOLED setting.
  ThemeData get darkTheme =>
      KeyelTheme.dark(palette: palette, amoledBlack: amoledBlack);

  /// Returns a copy with updated fields.
  AppearanceState copyWith({
    ThemeMode? themeMode,
    KeyelPalette? palette,
    bool? amoledBlack,
    bool? animationsEnabled,
    bool? hapticsEnabled,
  }) {
    return AppearanceState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      amoledBlack: amoledBlack ?? this.amoledBlack,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

/// Riverpod provider for appearance and interaction preferences.
final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(
      AppearanceNotifier.new,
    );

/// Persists and exposes appearance settings.
class AppearanceNotifier extends Notifier<AppearanceState> {
  @override
  AppearanceState build() => AppearanceState.fromPrefs(AppPreferences.instance);

  Future<void> _save(AppPreferences prefs) => prefs.save();

  /// Updates the app theme mode.
  void setThemeMode(ThemeMode mode) {
    final prefs = AppPreferences.instance
      ..themeMode = KeyelPaletteX.themeModeToId(mode);
    state = state.copyWith(themeMode: mode);
    unawaited(_save(prefs));
  }

  /// Updates the accent palette.
  void setPalette(KeyelPalette palette) {
    final prefs = AppPreferences.instance..paletteId = palette.id;
    state = state.copyWith(palette: palette);
    unawaited(_save(prefs));
  }

  /// Toggles pure-black AMOLED dark surfaces.
  void setAmoledBlack({required bool enabled}) {
    final prefs = AppPreferences.instance..amoledBlack = enabled;
    state = state.copyWith(amoledBlack: enabled);
    unawaited(_save(prefs));
  }

  /// Toggles in-app animations.
  void setAnimationsEnabled({required bool enabled}) {
    final prefs = AppPreferences.instance..animationsEnabled = enabled;
    state = state.copyWith(animationsEnabled: enabled);
    unawaited(_save(prefs));
  }

  /// Toggles haptic feedback.
  void setHapticsEnabled({required bool enabled}) {
    final prefs = AppPreferences.instance..hapticsEnabled = enabled;
    state = state.copyWith(hapticsEnabled: enabled);
    unawaited(_save(prefs));
  }
}
