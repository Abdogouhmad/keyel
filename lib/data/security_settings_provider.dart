import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';

/// Immutable snapshot of the security settings shown across the app.
@immutable
class SecuritySettings {
  /// Creates a security settings snapshot.
  const new({required this.autoLockDelay, required this.clipboardClearSeconds});

  /// How long the app may stay in the background before locking.
  final Duration autoLockDelay;

  /// Seconds before a copied secret is wiped; zero means on lock only.
  final int clipboardClearSeconds;
}

/// Reactive mirror of the auto-lock and clipboard-wipe preferences.
///
/// [AppPreferences] is a plain singleton with no change notification. Both the
/// Settings screen and the security dashboard watch this provider, so changing
/// either value through the setters updates every surface immediately while
/// the singleton remains the persisted source of truth.
final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
      SecuritySettingsNotifier.new,
    );

/// Persists and exposes the auto-lock and clipboard-wipe choices.
class SecuritySettingsNotifier extends Notifier<SecuritySettings> {
  @override
  SecuritySettings build() => SecuritySettings(
    autoLockDelay: AppPreferences.instance.autoLockDelay,
    clipboardClearSeconds: AppPreferences.instance.clipboardClearSeconds,
  );

  /// Change the auto-lock delay (options: immediately, 30 s, 1/5/15 min).
  void setAutoLockDelay(Duration delay) {
    final prefs = AppPreferences.instance..autoLockDelay = delay;
    state = SecuritySettings(
      autoLockDelay: delay,
      clipboardClearSeconds: state.clipboardClearSeconds,
    );
    unawaited(prefs.save());
  }

  /// Change the clipboard wipe timeout in seconds (0 = on lock only).
  void setClipboardClearSeconds(int seconds) {
    final prefs = AppPreferences.instance..clipboardClearSeconds = seconds;
    state = SecuritySettings(
      autoLockDelay: state.autoLockDelay,
      clipboardClearSeconds: seconds,
    );
    unawaited(prefs.save());
  }
}
