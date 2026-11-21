import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/platform/biometric_auth.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/biometric_settings.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/error.dart';
import 'package:keyel/ui/design_system/button_type.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Biometric unlock button for the locked-vault screen.
///
/// The verification itself is the operating system's prompt; Keyel only reads
/// the stored credential once the system reports success.
class VaultBiometricButton extends ConsumerStatefulWidget {
  /// Creates the button. [autoPrompt] opens the system prompt once when the
  /// unlock screen first appears.
  const new({super.key, this.autoPrompt = false});

  /// Whether to open the system prompt automatically.
  final bool autoPrompt;

  @override
  ConsumerState<VaultBiometricButton> createState() =>
      _VaultBiometricButtonState();
}

class _VaultBiometricButtonState extends ConsumerState<VaultBiometricButton> {
  bool _available = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    if (!AppPreferences.instance.biometricEnabled) return;
    final available = await BiometricAuth.instance.isAvailable;
    if (!mounted) return;
    setState(() => _available = available);
    if (available && widget.autoPrompt) await _unlock();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final l10n = l10nOf(context);
    setState(() => _busy = true);
    try {
      final auth = BiometricAuth.instance;

      // The operating system performs the check; Keyel trusts only its
      // verdict.
      if (!await auth.authenticate()) return;

      final master = await auth.readMaster();
      if (master == null) {
        await _reset(l10n.vaultQuickUnlockSetupAgain);
        return;
      }
      await ref.read(vaultSessionProvider.notifier).unlockWithMaster(master);
    } on Object catch (error) {
      if (error is VaultApiError && error == VaultApiError.wrongPassword) {
        await _reset(l10n.vaultMasterPasswordChanged);
      } else if (mounted) {
        showKeyelSnack(context, describeVaultError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset(String message) async {
    await disableBiometricUnlock();
    if (!mounted) return;
    setState(() => _available = false);
    showKeyelSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    return KeyelButtonM3(
      label: l10nOf(context).vaultUnlockWithBiometrics,
      icon: Icons.fingerprint_rounded,
      type: ButtonType.secondary,
      isFullWidth: true,
      isLoading: _busy,
      onPressed: _busy ? null : () => unawaited(_unlock()),
    );
  }
}
