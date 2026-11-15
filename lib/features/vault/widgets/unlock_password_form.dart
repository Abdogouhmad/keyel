import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/security/unlock_throttle.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/vault/widgets/vault_biometric_button.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';

/// Master-password form shown by the unlock screen.
///
/// Prompts for the password, offers biometric unlock when it is set up, and
/// hands off to the recovery reset flow when the password is lost.
class UnlockPasswordForm extends ConsumerStatefulWidget {
  /// Creates the password form.
  const new({required this.onForgotPassword, super.key});

  /// Opens the recovery-key reset flow.
  final VoidCallback onForgotPassword;

  @override
  ConsumerState<UnlockPasswordForm> createState() => _UnlockPasswordFormState();
}

class _UnlockPasswordFormState extends ConsumerState<UnlockPasswordForm> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  Duration _cooldown = Duration.zero;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(
      ref.read(vaultSessionProvider.notifier).unlockDelayRemaining,
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  /// Reflect the throttle's remaining delay and tick it down once a second.
  void _startCooldown(Duration remaining) {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    if (!mounted) return;
    setState(() => _cooldown = remaining);
    if (remaining <= Duration.zero) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = ref.read(vaultSessionProvider.notifier).unlockDelayRemaining;
      setState(() => _cooldown = left);
      if (left <= Duration.zero) {
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
      }
    });
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty || _busy) return;
    if (_cooldown > Duration.zero) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await ref
          .read(vaultSessionProvider.notifier)
          .unlockWithMaster(_passwordController.text);
    } on UnlockThrottledException catch (error) {
      _startCooldown(error.remaining);
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    } on Object catch (error) {
      // A wrong password may have just started a cooldown; show it inline.
      _startCooldown(
        ref.read(vaultSessionProvider.notifier).unlockDelayRemaining,
      );
      if (mounted) {
        showKeyelSnack(context, describeVaultError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final throttled = _cooldown > Duration.zero;

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
                      Icons.lock_rounded,
                      size: 40,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                Text(
                  'Enter your master password to unlock your vault.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  autofocus: true,
                  enabled: !_busy && !throttled,
                  style: TextStyle(color: scheme.onSurface),
                  cursorColor: scheme.primary,
                  onSubmitted: (_) => unawaited(_unlock()),
                  decoration: InputDecoration(
                    labelText: 'Master password',
                    prefixIcon: Icon(
                      Icons.key_rounded,
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
                KeyelButtonM3(
                  label: _busy ? 'Unlocking…' : 'Unlock',
                  icon: _busy ? null : Icons.lock_open_rounded,
                  isFullWidth: true,
                  onPressed: (_busy || throttled)
                      ? null
                      : () => unawaited(_unlock()),
                ),
                if (throttled) ...[
                  const SizedBox(height: KeyelSpacing.sm),
                  Text(
                    'Too many attempts. Try again in '
                    '${_cooldown.inSeconds}s.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: KeyelSpacing.sm),
                TextButton(
                  onPressed: _busy ? null : widget.onForgotPassword,
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: KeyelSpacing.xl),
                const VaultBiometricButton(autoPrompt: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
