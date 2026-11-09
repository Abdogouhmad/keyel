import 'dart:async';

import 'package:flutter/services.dart';

/// Copies sensitive text and wipes the clipboard after a short delay.
///
/// Android 13+ flags the clipboard entry as sensitive, and the timer clears
/// the value even when the user forgets. Wiping the clipboard is best effort:
/// if the app is frozen or killed the OS keeps the last value.
class SensitiveClipboard {
  // Private: callers must use [instance]. Dart requires a named generative
  // constructor, which the lint flags as redundant despite the privacy.
  // ignore: unnecessary_type_name_in_constructor
  SensitiveClipboard._();

  /// Shared helper used by detail and list screens.
  static final instance = SensitiveClipboard._();

  Timer? _clearTimer;

  /// Copy [text] and schedule a clipboard wipe.
  Future<void> copy(
    String text, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    _clearTimer?.cancel();
    _clearTimer = Timer(timeout, () {
      unawaited(Clipboard.setData(const ClipboardData(text: '')));
    });
  }

  /// Cancel a pending wipe, for example when the screen is disposed.
  void cancel() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
