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

class _UnlockVaultViewState extends ConsumerState<UnlockVaultView> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _unlocking = false;
  bool _useRecovery = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
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
      if (mounted) {
        setState(() => _unlocking = false);
        showKeyelSnack(context, describeVaultError(error));
      }
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
                TextField(
                  controller: _passwordController,
                  obscureText: !_useRecovery && _obscure,
                  maxLines: _useRecovery ? 3 : 1,
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
                const SizedBox(height: KeyelSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _unlocking ? null : () => unawaited(_unlock()),
                    child: _unlocking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock Vault'),
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
