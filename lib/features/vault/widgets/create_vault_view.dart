import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';

/// Full screen view for creating a new encrypted vault.
class CreateVaultView extends ConsumerStatefulWidget {
  /// Creates the create-vault view.
  const new({super.key});

  @override
  ConsumerState<CreateVaultView> createState() => _CreateVaultViewState();
}

class _CreateVaultViewState extends ConsumerState<CreateVaultView> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _creating = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (pass.isEmpty) {
      showKeyelSnack(context, 'Please choose a master password.');
      return;
    }
    if (pass != confirm) {
      showKeyelSnack(context, 'Passwords do not match.');
      return;
    }

    setState(() => _creating = true);
    try {
      final recoveryKey = await ref
          .read(vaultSessionProvider.notifier)
          .create(pass);
      if (!mounted) return;

      if (recoveryKey != null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.vpn_key_rounded, color: Colors.amber),
                SizedBox(width: KeyelSpacing.sm),
                Text('Recovery Key'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write down or securely store this recovery key offline. '
                  'If you forget your master password, this is the ONLY way '
                  'to regain access to your vault.',
                ),
                const SizedBox(height: KeyelSpacing.md),
                Container(
                  padding: const EdgeInsets.all(KeyelSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogCtx)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(KeyelRadii.field),
                  ),
                  child: SelectableText(
                    recoveryKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  unawaited(SensitiveClipboard.instance.copy(recoveryKey));
                  showKeyelSnack(
                    dialogCtx,
                    'Recovery key copied to clipboard'
                    '${SensitiveClipboard.instance.clearHint}',
                    icon: Icons.content_copy_rounded,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Key'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('I Have Saved It'),
              ),
            ],
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _creating = false);
        showKeyelSnack(context, describeVaultError(error));
      }
    }
  }

  Future<void> _openExistingVault() async {
    await ref.read(vaultSessionProvider.notifier).refresh();
    if (!mounted) return;
    if (ref.read(vaultSessionProvider).status == VaultStatus.locked) {
      context.go(KeyelRoutes.unlock);
    } else {
      showKeyelSnack(context, 'No existing vault was found on this device.');
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
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                Text(
                  'Welcome to Keyel',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xs),
                Text(
                  'Create your encrypted offline vault. Only you have the key '
                  'to your credentials.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: TextStyle(color: scheme.onSurface),
                  cursorColor: scheme.onSurface,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.md),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  style: TextStyle(color: scheme.onSurface),
                  cursorColor: scheme.onSurface,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Master Password',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  onSubmitted: (_) => unawaited(_create()),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _creating ? null : () => unawaited(_create()),
                    child: _creating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Encrypted Vault'),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                TextButton.icon(
                  onPressed: _creating
                      ? null
                      : () => unawaited(_openExistingVault()),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('I already have a vault'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
