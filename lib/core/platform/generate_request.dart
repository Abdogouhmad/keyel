import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Method channel used for warm "Generate password" launch requests.
const String generateRequestChannelName = 'keyel/generate';

/// Method name sent by Android when the generator shortcut/widget is tapped.
const String generateRequestedMethod = 'generateRequested';

/// Minimal bridge surface used by the generate request host.
abstract class GenerateRequestBridge {
  /// Registers the method-call handler.
  void register();

  /// Removes the method-call handler.
  void unregister();
}

/// Factory for a bridge, injecting the callback fired on a native request.
typedef GenerateRequestBridgeFactory = GenerateRequestBridge Function(
  VoidCallback onRequested,
);

/// Real platform-channel implementation.
class MethodChannelGenerateRequestBridge implements GenerateRequestBridge {
  /// Creates a bridge that calls the callback for native requests.
  new(this._onRequested);

  final VoidCallback _onRequested;
  final MethodChannel _channel = const MethodChannel(
    generateRequestChannelName,
  );

  @override
  void register() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == generateRequestedMethod) _onRequested();
    });
  }

  @override
  void unregister() {
    _channel.setMethodCallHandler(null);
  }
}

/// Injectable factory so tests can simulate warm launch requests.
final generateRequestBridgeProvider = Provider<GenerateRequestBridgeFactory>((
  ref,
) {
  return MethodChannelGenerateRequestBridge.new;
});
