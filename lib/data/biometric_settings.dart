import 'package:keyel/core/platform/biometric_auth.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Turn system-biometric quick unlock on for [master].
///
/// Runs the operating system prompt first, then persists the master password
/// in the Keystore-backed store and records the preference. Returns `false`
/// when the user cancelled the prompt or storage failed, leaving both the
/// stored credential and the preference untouched.
Future<bool> enableBiometricUnlock(String master) async {
  final auth = BiometricAuth.instance;

  if (!await auth.isAvailable) return false;
  if (!await auth.authenticate(reason: currentL10n.coreBiometricEnableReason)) {
    return false;
  }
  if (!await auth.storeMaster(master)) return false;

  AppPreferences.instance.biometricEnabled = true;
  await AppPreferences.instance.save();
  return true;
}

/// Turn quick unlock off and wipe the stored credential.
Future<void> disableBiometricUnlock() async {
  await BiometricAuth.instance.clear();
  AppPreferences.instance.biometricEnabled = false;
  await AppPreferences.instance.save();
}
