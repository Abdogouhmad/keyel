import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform bridge for local "update available" notifications.
///
/// Android implements this natively through `keyel/notifications`; desktop and
/// test environments simply report that notifications are unavailable.
abstract class UpdateNotificationPlatform {
  /// Creates a notification platform adapter.
  const new();

  /// Whether the OS currently allows Keyel to post notifications.
  Future<bool> areNotificationsEnabled();

  /// Asks the OS for notification permission, returning the granted state.
  Future<bool> requestPermission();

  /// Posts a notification for [version] on [channel], returning success.
  Future<bool> showUpdateAvailable({
    required String version,
    required String channel,
  });
}

/// Method-channel implementation backed by the Android notification bridge.
class MethodChannelUpdateNotificationPlatform
    implements UpdateNotificationPlatform {
  /// Creates the bridge with the app's notification channel.
  const new();

  static const _channel = MethodChannel('keyel/notifications');

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('areNotificationsEnabled') ??
          false;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<bool> showUpdateAvailable({
    required String version,
    required String channel,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('showUpdate', <String, Object?>{
            'version': version,
            'channel': channel,
          }) ??
          false;
    } on Object catch (_) {
      return false;
    }
  }
}

/// Injectable notification adapter used by the OTA notifier and tests.
final updateNotificationProvider = Provider<UpdateNotificationPlatform>((ref) {
  return const MethodChannelUpdateNotificationPlatform();
});
