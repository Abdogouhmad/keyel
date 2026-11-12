import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// System biometric prompt plus Keystore-encrypted credential storage.
///
/// Keyel never implements a biometric check of its own: [authenticate] hands
/// control to the operating system (Android `BiometricPrompt`, iOS Face ID /
/// Touch ID) and only trusts its verdict. The master credential is kept in the
/// platform Keystore-backed store and is read *after* a successful prompt, so
/// copying the app's data directory alone is not enough to recover it.
///
/// Every platform call degrades to "unavailable" instead of throwing, so a
/// device without enrolled biometrics can always fall back to the master
/// password.
class BiometricAuth {
  new _();

  /// Shared instance.
  static final BiometricAuth instance = BiometricAuth._();

  static const _masterKey = 'keyel.master.v1';

  static const _storage = FlutterSecureStorage();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Whether the device has a usable biometric enrolled.
  ///
  /// Asks the platform itself, so the answer stays correct when the user adds
  /// or removes fingerprints in system settings.
  Future<bool> get isAvailable async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.any(_isStrong);
    } on Object catch (_) {
      return false;
    }
  }

  /// Show the operating system's biometric prompt.
  ///
  /// Returns `true` only when the system reported a successful match;
  /// cancellations, lockouts and platform errors all return `false`.
  Future<bool> authenticate({String reason = 'Unlock your Keyel vault'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Object catch (_) {
      return false;
    }
  }

  /// Read the stored master password, or `null` when unavailable.
  ///
  /// This only touches storage; call [authenticate] first, since reading is
  /// what the prompt is supposed to guard.
  Future<String?> readMaster() async {
    try {
      return await _storage.read(key: _masterKey);
    } on Object catch (_) {
      return null;
    }
  }

  /// Persist the master password in Keystore-backed storage.
  ///
  /// Returns `false` when the platform rejected the write, in which case
  /// biometric unlock simply stays unavailable.
  Future<bool> storeMaster(String master) async {
    try {
      await _storage.write(key: _masterKey, value: master);
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Remove the stored master password.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _masterKey);
    } on Object catch (_) {
      // Nothing left to clean up.
    }
  }

  /// Only fingerprint, face, iris or an explicit strong biometric qualifies,
  /// matching the `BIOMETRIC_STRONG` hardening requirement. Weak (Class 2)
  /// modalities are deliberately not offered for unlocking a vault.
  static bool _isStrong(BiometricType type) => switch (type) {
    BiometricType.strong ||
    BiometricType.fingerprint ||
    BiometricType.face ||
    BiometricType.iris => true,
    BiometricType.weak => false,
  };
}
