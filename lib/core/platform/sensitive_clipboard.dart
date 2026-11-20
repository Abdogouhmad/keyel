import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';

/// Immediate clipboard wipe used on vault lock and app background.
///
/// Overridable in tests so session behaviour can be asserted without touching
/// the platform clipboard. See `docs/threat-model.md` (T5).
final clipboardWipeProvider = Provider<Future<void> Function()>(
  (ref) => SensitiveClipboard.instance.clearOnLock,
);

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

  static const _channel = MethodChannel('keyel/platform');

  Timer? _clearTimer;

  /// Copy [text] and schedule a clipboard wipe.
  ///
  /// [timeout] overrides the user preference; pass [Duration.zero] to clear
  /// immediately. When neither is set to clear, any pending wipe is cancelled
  /// and the value stays until the user copies something else.
  Future<void> copy(String text, {Duration? timeout}) async {
    await _setSensitive(text);
    _clearTimer?.cancel();
    _clearTimer = null;
    final delay = timeout ?? AppPreferences.instance.clipboardClearDelay;
    if (delay == null || delay <= Duration.zero) return;
    _clearTimer = Timer(delay, () {
      unawaited(_clearSensitive());
    });
  }

  /// Writes a clipboard entry through the native channel so Android 13+ can
  /// mark it sensitive. Falls back to Flutter's clipboard when the channel is
  /// unavailable (tests, desktop) or the host OS has no implementation.
  Future<void> _setSensitive(String text) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('copySensitive', <String, Object?>{
          'text': text,
        });
        return;
      } on Object catch (_) {
        // Fall through to the platform-agnostic clipboard.
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Clears the clipboard without writing an empty clip.
  ///
  /// On Android the native channel calls `clearPrimaryClip()`, so the OS does
  /// not broadcast a copy event (which some OEMs show as a toast) and there is
  /// no empty value to keep in history or offer as a suggestion.
  Future<void> _clearSensitive() async {
    // Try the native channel on every platform. On Android it uses
    // clearPrimaryClip(); elsewhere the call fails fast and we fall back to
    // the platform-agnostic clipboard.
    try {
      await _channel.invokeMethod<void>('clearSensitive');
      return;
    } on Object catch (_) {
      // Fall through to the platform-agnostic clipboard.
    }
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// Wipe immediately for a security event.
  ///
  /// Unlike the timed clear this is unconditional: choosing "Never clear" only
  /// opts out of the automatic timer while the vault stays unlocked and the
  /// app stays in the foreground. Locking or backgrounding always wins.
  Future<void> clearOnLock() async {
    _clearTimer?.cancel();
    _clearTimer = null;
    try {
      await _clearSensitive();
    } on Object catch (_) {
      // No platform binding (unit tests) or clipboard unavailable: wiping is
      // best effort, as with the timed clear.
    }
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
