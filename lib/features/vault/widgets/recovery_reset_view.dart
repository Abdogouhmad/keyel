import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';

/// The "Forgot password?" flow shown from the unlock screen.
///
/// The user proves vault ownership with the one-time recovery key, then sets
/// a new master password. A successful reset leaves the vault unlocked with
/// the new password, and the router's locked-state redirect opens the vault
/// home just like the regular unlock path.
class RecoveryResetView extends ConsumerStatefulWidget {
  /// Creates the reset view.
  const new({required this.onBack, super.key});

  /// Returns to the master-password unlock form.
  final VoidCallback onBack;

  @override
  ConsumerState<RecoveryResetView> createState() => _RecoveryResetViewState();
}

class _RecoveryResetViewState extends ConsumerState<RecoveryResetView> {
  final _recoveryKeyController = TextEditingController();
  final _newMasterController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    _newMasterController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  PasswordStrength get _strength =>
      PasswordStrength.estimate(_newMasterController.text);

  /// Mirrors the onboarding rule: 8+ characters, confirmed, 50+ entropy bits.
  bool get _newMasterValid =>
      _newMasterController.text.length >= 8 &&
      _newMasterController.text == _confirmController.text &&
      _strength.bits >= 50;

  bool get _canReset =>
      _recoveryKeyController.text.trim().isNotEmpty && _newMasterValid;

  Future<void> _reset() async {
    if (!_canReset || _busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      // On success the session flips to [VaultStatus.unlocked], so the
      // router's redirect replaces this view with the vault home.
      await ref
          .read(vaultSessionProvider.notifier)
          .resetMasterWithRecovery(
            recoveryKey: _recoveryKeyController.text.trim(),
            newMaster: _newMasterController.text,
          );
    } on Object catch (error) {
      if (mounted) {
        showKeyelSnack(
          context,
          describeVaultError(error),
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KeyelSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                Text(
                  'Reset your master password',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                Text(
                  'Enter your recovery key to set a new master password and '
                  'unlock your vault.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                TextField(
                  controller: _recoveryKeyController,
                  enabled: !_busy,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontFamily: KeyelTheme.monoFamily,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: scheme.primary,
                  decoration: InputDecoration(
                    labelText: 'Recovery key',
                    prefixIcon: Icon(
                      Icons.vpn_key_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.md),
                TextField(
                  controller: _newMasterController,
                  enabled: !_busy,
                  obscureText: _obscure,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: scheme.primary,
                  decoration: InputDecoration(
                    labelText: 'New master password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.md),
                TextField(
                  controller: _confirmController,
                  enabled: !_busy,
                  obscureText: _obscure,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => unawaited(_reset()),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: scheme.primary,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(
                      Icons.check_circle_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                KeyelStrengthMeter(strength: _strength),
                const SizedBox(height: KeyelSpacing.xl),
                KeyelButtonM3(
                  label: _busy ? 'Resetting…' : 'Reset password',
                  icon: _busy ? null : Icons.lock_reset_rounded,
                  isFullWidth: true,
                  onPressed: _busy || !_canReset
                      ? null
                      : () => unawaited(_reset()),
                ),
                const SizedBox(height: KeyelSpacing.md),
                TextButton.icon(
                  onPressed: _busy ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
