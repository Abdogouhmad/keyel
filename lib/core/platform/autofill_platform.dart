import 'package:flutter/services.dart';

const _channel = MethodChannel('keyel/platform');

/// Whether Keyel is the device's active autofill service.
///
/// Returns `false` on platforms without the Android autofill framework and in
/// widget tests, where the call is simply not implemented.
Future<bool> isAutofillServiceEnabled() async {
  try {
    final enabled = await _channel.invokeMethod<bool>('isAutofillEnabled');
    return enabled ?? false;
  } on Object catch (_) {
    return false;
  }
}

/// Open the system autofill settings so the user can pick Keyel.
///
/// This is a no-op on unsupported platforms.
Future<void> openAutofillSettings() async {
  try {
    await _channel.invokeMethod<void>('openAutofillSettings');
  } on Object catch (_) {
    // Nothing to open (tests, desktop, web).
  }
}
