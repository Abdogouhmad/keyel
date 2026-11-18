import 'package:flutter/services.dart';

import 'package:keyel/data/app_preferences.dart';

/// Lightweight wrapper around [HapticFeedback] that never throws.
///
/// Haptics are best-effort and can be disabled by the user in Appearance.
class Haptics {
  /// Prevent instantiation.
  const new _();

  /// A short, light tap. Used for most button presses.
  static Future<void> light() async {
    if (!AppPreferences.instance.hapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }

  /// A medium-strength tap. Used for destructive confirmations.
  static Future<void> medium() async {
    if (!AppPreferences.instance.hapticsEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }

  /// A short vibration. Used for errors and warnings.
  static Future<void> vibrate() async {
    if (!AppPreferences.instance.hapticsEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }

  /// A selection tick. Used for toggle/checkbox interactions.
  static Future<void> selection() async {
    if (!AppPreferences.instance.hapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }
}
