import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action reported by Android when Keyel was launched to lock immediately.
const String lockLaunchAction = 'lock';

const MethodChannel _platformChannel = MethodChannel('keyel/platform');

/// Reads and consumes a one-tap lock request made before Flutter started.
///
/// Missing plugins and platform errors fail closed to `null`: the app then
/// starts normally instead of crashing on platforms without the action channel.
Future<String?> getInitialLaunchAction() async {
  try {
    return await _platformChannel.invokeMethod<String>('getInitialAction');
  } on MissingPluginException catch (_) {
    return null;
  } on PlatformException catch (_) {
    return null;
  }
}

/// Signature of the startup action reader, injectable in tests.
typedef InitialLaunchActionReader = Future<String?> Function();

/// Injectable reader so tests can exercise the startup path without a device.
final initialLaunchActionProvider = Provider<InitialLaunchActionReader>((ref) {
  return getInitialLaunchAction;
});
