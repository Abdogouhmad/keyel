import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Channel used by Android to request a lock while Flutter is already running.
const MethodChannel lockRequestChannel = MethodChannel('keyel/lock');

/// Method sent by the native side for a one-tap lock request.
const String lockRequestedMethod = 'lockRequested';

/// Bridges native one-tap lock requests to the app's lock callback.
class LockRequestBridge {
  /// Creates a bridge that calls the supplied callback for each native request.
  new(this._onLockRequested);

  final VoidCallback _onLockRequested;

  bool _registered = false;

  /// Installs the native-to-Dart handler. Safe to call more than once.
  void register() {
    if (_registered) return;
    lockRequestChannel.setMethodCallHandler((call) async {
      if (call.method == lockRequestedMethod) {
        _onLockRequested();
      }
    });
    _registered = true;
  }

  /// Removes the handler when the host leaves the tree.
  void unregister() {
    if (!_registered) return;
    lockRequestChannel.setMethodCallHandler(null);
    _registered = false;
  }
}

/// Injectable bridge factory so tests can drive one-tap lock without a device.
final lockRequestBridgeProvider =
    Provider<LockRequestBridge Function(VoidCallback)>((ref) {
      return LockRequestBridge.new;
    });
