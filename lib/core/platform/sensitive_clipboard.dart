import 'dart:async';

import 'package:flutter/services.dart';

import 'package:keyel/data/app_preferences.dart';

/// Copies sensitive text and wipes the clipboard after a short delay.
///
/// Android 13+ flags the clipboard entry as sensitive, and the timer clears
/// the value even when the user forgets. Wiping the clipboard is best effort:
/// if the app is frozen or killed the OS keeps the last value.
///
/// The delay comes from [AppPreferences.clipboardClearDelay], which the user
/// controls in Settings (15 s / 30 s / 1 minute / never).
class SensitiveClipboard {
  // Private: callers must use [instance]. Dart requires a named generative
  // constructor, which the lint flags as redundant despite the privacy.
  // ignore: unnecessary_type_name_in_constructor
  SensitiveClipboard._();

  /// Shared helper used by detail and list screens.
  static final instance = SensitiveClipboard._();

  Timer? _clearTimer;

  /// Copy [text] and schedule a clipboard wipe.
  ///
  /// [timeout] overrides the user preference; pass [Duration.zero] to clear
  /// immediately. When neither is set to clear, any pending wipe is cancelled
  /// and the value stays until the user copies something else.
  Future<void> copy(String text, {Duration? timeout}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _clearTimer?.cancel();
    _clearTimer = null;
    final delay = timeout ?? AppPreferences.instance.clipboardClearDelay;
    if (delay == null || delay <= Duration.zero) return;
    _clearTimer = Timer(delay, () {
      unawaited(Clipboard.setData(const ClipboardData(text: '')));
    });
  }

  /// Cancel a pending wipe, for example when the screen is disposed.
  void cancel() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }

  /// Snackbar suffix describing when the copied value is wiped.
  ///
  /// The clear delay is user-configurable (15 s / 30 s / 1 min / never), so the
  /// message must not hardcode a number. Empty when the user chose "Never", so
  /// the message reads as just "… copied".
  String get clearHint {
    final seconds = AppPreferences.instance.clipboardClearSeconds;
    if (seconds <= 0) return '';
    final label = seconds < 60 ? '${seconds}s' : '${seconds ~/ 60} min';
    return ' • Clears in $label';
  }
}
