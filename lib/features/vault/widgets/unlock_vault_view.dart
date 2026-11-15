import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/features/vault/widgets/recovery_reset_view.dart';
import 'package:keyel/features/vault/widgets/unlock_password_form.dart';
import 'package:keyel/ui/keyel.dart';

/// The screen shown when the vault is locked. Prompts the user for their
/// master password or biometric unlock, and offers a recovery-key reset for
/// a lost master password.
///
/// The reset flow is in-place view state rather than its own route: the
/// router redirects every location back to `/unlock` while the vault is
/// locked, and the redirect also performs the post-unlock navigation to the
/// vault home.
class UnlockVaultView extends ConsumerStatefulWidget {
  /// Creates the unlock view.
  const new({super.key});

  @override
  ConsumerState<UnlockVaultView> createState() => _UnlockVaultViewState();
}

class _UnlockVaultViewState extends ConsumerState<UnlockVaultView> {
  bool _resetFlow = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: KeyelMotion.resolve(context, KeyelMotion.medium),
          child: _resetFlow
              ? RecoveryResetView(
                  key: const ValueKey('unlock-recovery-reset'),
                  onBack: () => setState(() => _resetFlow = false),
                )
              : UnlockPasswordForm(
                  key: const ValueKey('unlock-password-form'),
                  onForgotPassword: () => setState(() => _resetFlow = true),
                ),
        ),
      ),
    );
  }
}
