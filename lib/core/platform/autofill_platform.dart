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

/// Whether the platform can host a passkey/credential provider.
///
/// This is a coarse capability gate (e.g. Android 14+/API 34 for provider
/// services). Returns `false` on unsupported platforms and in tests.
Future<bool> isPasskeyProviderSupported() async {
  try {
    final supported = await _channel.invokeMethod<bool>(
      'isPasskeyProviderSupported',
    );
    return supported ?? false;
  } on Object catch (_) {
    return false;
  }
}

/// Open system settings for managing credential providers where supported.
///
/// Falls back to general settings or no-ops on unsupported platforms.
Future<void> openCredentialProviderSettings() async {
  try {
    await _channel.invokeMethod<void>('openCredentialProviderSettings');
  } on Object catch (_) {
    // Nothing to open (tests, desktop, web, unsupported Android).
  }
}
