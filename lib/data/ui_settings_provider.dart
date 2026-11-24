import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';

/// Immutable snapshot of the small UI preferences read while building screens.
@immutable
class UiSettings {
  /// Creates a UI settings snapshot.
  const new({required this.recentSearches, required this.animationsEnabled});

  /// Most recent vault searches, newest first.
  final List<String> recentSearches;

  /// Whether in-app motion is enabled (the platform setting still wins).
  final bool animationsEnabled;
}

/// Reactive mirror of the UI preferences that hot build paths depend on.
///
/// [AppPreferences] remains the persisted source of truth; this provider gives
/// widgets something to watch so a change rebuilt every surface immediately.
final uiSettingsProvider = NotifierProvider<UiSettingsNotifier, UiSettings>(
  UiSettingsNotifier.new,
);

/// Persists and exposes UI preferences used while building widgets.
class UiSettingsNotifier extends Notifier<UiSettings> {
  @override
  UiSettings build() => UiSettings(
    recentSearches: List.unmodifiable(AppPreferences.instance.recentSearches),
    animationsEnabled: AppPreferences.instance.animationsEnabled,
  );

  /// Remembers a search term and refreshes every strip showing recent searches.
  void rememberSearch(String query) {
    AppPreferences.instance.rememberSearch(query);
    _publish();
  }

  /// Drops all remembered searches and refreshes the strips.
  void clearRecentSearches() {
    AppPreferences.instance.clearRecentSearches();
    _publish();
  }

  /// Enables or disables in-app motion.
  void setAnimationsEnabled({required bool enabled}) {
    final prefs = AppPreferences.instance..animationsEnabled = enabled;
    unawaited(prefs.save());
    _publish();
  }

  /// Reloads the snapshot from the persisted singleton after an external load.
  void refresh() => _publish();

  void _publish() => state = UiSettings(
    recentSearches: List.unmodifiable(AppPreferences.instance.recentSearches),
    animationsEnabled: AppPreferences.instance.animationsEnabled,
  );
}
