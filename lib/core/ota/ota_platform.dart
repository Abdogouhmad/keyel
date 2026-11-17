import 'package:flutter/services.dart';

/// Platform bridge for Android package installation and permissions.
class OtaPlatform {
  /// Default constructor.
  const new();

  static const MethodChannel _channel = MethodChannel('keyel/platform');

  /// Checks if Keyel has been granted permission to install unknown apps (Android 8.0+).
  Future<bool> canInstallPackages() async {
    try {
      final res = await _channel.invokeMethod<bool>('canInstallPackages');
      return res ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      // In tests or desktop platforms where the channel is not registered.
      return true;
    }
  }

  /// Opens the Android system settings screen allowing the user to grant
  /// install-unknown-apps permission for Keyel.
  Future<void> openInstallPermissionSettings() async {
    try {
      await _channel.invokeMethod<void>('openInstallPermissionSettings');
    } on PlatformException {
      // Best effort
    } on MissingPluginException {
      // Ignored
    }
  }

  /// Hands off the downloaded APK file to Android's PackageInstaller via Intent.
  Future<bool> installApk(String filePath) async {
    try {
      final res = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      throw StateError(e.message ?? 'Package installer could not be opened');
    } on MissingPluginException {
      throw UnsupportedError('Package installer is only supported on Android');
    }
  }
}
