import 'package:flutter/services.dart';

/// Lightweight wrapper around [HapticFeedback] that never throws.
class Haptics {
  /// new construction
  const new();

  /// A short, light tap. Used for most button presses.
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }

  /// A medium-strength tap. Used for destructive confirmations.
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }

  /// A short vibration. Used for errors and warnings.
  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }

  /// A selection tick. Used for toggle/checkbox interactions.
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } on Object catch (_) {
      // Ignore: haptics are best-effort.
    }
  }
}
