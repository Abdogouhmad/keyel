import 'package:flutter/services.dart';

/// Thin Dart wrapper around the phone-side Wear OS transport.
///
/// Every method fails closed: no paired watch / Play Services means `false`,
/// never a local fallback that would keep a secret on the phone.
class WearTotpBridge {
  /// Creates a bridge around the default platform channel.
  const new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('keyel/wear');

  final MethodChannel _channel;

  /// Whether a paired watch is reachable right now.
  Future<bool> get available async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on Object {
      return false;
    }
  }

  /// Pushes one TOTP seed to the watch. The payload is sent only while the
  /// vault is unlocked and the caller has just revealed the secret.
  Future<bool> push({
    required String id,
    required String label,
    required String secret,
    required String algorithm,
    required int digits,
    required int period,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('push', {
            'id': id,
            'label': label,
            'secret': secret,
            'algorithm': algorithm,
            'digits': digits,
            'period': period,
          }) ??
          false;
    } on Object {
      return false;
    }
  }

  /// Removes a single seed from the watch by its vault entry id.
  Future<bool> remove(String id) async {
    try {
      return await _channel.invokeMethod<bool>('remove', {'id': id}) ?? false;
    } on Object {
      return false;
    }
  }

  /// Removes every seed from the watch.
  Future<bool> clear() async {
    try {
      return await _channel.invokeMethod<bool>('clear') ?? false;
    } on Object {
      return false;
    }
  }
}

/// Default bridge used by the settings flow and injectable in tests.
const wearTotpBridge = WearTotpBridge();
