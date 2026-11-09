import 'package:flutter/services.dart';

const _channel = MethodChannel('keyel/platform');

/// Enable or disable Android's `FLAG_SECURE` for the current window.
///
/// While enabled the OS blocks screenshots and blanks the Recents thumbnail,
/// which keeps a locked vault out of the task switcher. Unsupported platforms
/// and widget tests simply ignore the call.
Future<void> setSecureScreen({required bool secure}) async {
  try {
    await _channel.invokeMethod<void>('setSecure', <String, Object?>{
      'secure': secure,
    });
  } on Object catch (_) {
    // No platform implementation (tests, desktop, web): nothing to do.
  }
}
