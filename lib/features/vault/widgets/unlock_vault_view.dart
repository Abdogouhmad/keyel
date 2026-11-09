import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';

/// Full screen view for unlocking an existing vault.
class UnlockVaultView extends ConsumerStatefulWidget {
  /// Creates the unlock-vault view.
  const new({super.key});

  @override
  ConsumerState<UnlockVaultView> createState() => _UnlockVaultViewState();
}

class _UnlockVaultViewState extends ConsumerState<UnlockVaultView>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _unlocking = false;
  bool _useRecovery = false;
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _shakeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _coolingDown => _cooldownSeconds > 0;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    final rawExponent = _failedAttempts - 3;
    final exponent = rawExponent < 0 ? 0 : (rawExponent > 6 ? 6 : rawExponent);
    final seconds = 5 * (1 << exponent);
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  Future<void> _unlock() async {
    if (_unlocking || _coolingDown) return;
    final input = _passwordController.text.trim();
    if (input.isEmpty) {
      showKeyelSnack(
        context,
        _useRecovery
            ? 'Enter your recovery key.'
            : 'Enter your master password.',
      );
      return;
    }

    setState(() => _unlocking = true);
    try {
      if (_useRecovery) {
        await ref.read(vaultSessionProvider.notifier).unlockWithRecovery(input);
      } else {
        await ref.read(vaultSessionProvider.notifier).unlockWithMaster(input);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _unlocking = false;
        _failedAttempts += 1;
      });
      _shakeController.forward(from: 0);
      showKeyelSnack(context, describeVaultError(error));
      if (_failedAttempts >= 3) _startCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KeyelSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                Text(
                  'Vault is Locked',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xs),
                Text(
                  _useRecovery
                      ? 'Enter your 24-word recovery key to restore access.'
                      : 'Enter your master password to decrypt your '
                            'credentials.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(_shake.value, 0),
                    child: child,
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_useRecovery && _obscure,
                    maxLines: _useRecovery ? 3 : 1,
                    enabled: !_coolingDown,
                    decoration: InputDecoration(
                      labelText: _useRecovery
                          ? 'Recovery Key'
                          : 'Master Password',
                      prefixIcon: Icon(
                        _useRecovery
                            ? Icons.vpn_key_rounded
                            : Icons.password_rounded,
                      ),
                      suffixIcon: _useRecovery
                          ? null
                          : IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                    ),
                    onSubmitted: (_) => unawaited(_unlock()),
                  ),
                ),
                if (_coolingDown) ...[
                  const SizedBox(height: KeyelSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 18,
                        color: scheme.error,
                      ),
                      const SizedBox(width: KeyelSpacing.xs),
                      Text(
                        'Too many attempts. Try again in $_cooldownSeconds s.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: KeyelSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _unlocking || _coolingDown
                        ? null
                        : () => unawaited(_unlock()),
                    child: _unlocking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _coolingDown
                                ? 'Wait $_cooldownSeconds s'
                                : 'Unlock Vault',
                          ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useRecovery = !_useRecovery;
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _useRecovery
                        ? 'Unlock with Master Password'
                        : 'Forgot password? Use Recovery Key',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
