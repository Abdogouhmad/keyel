import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/biometric_settings.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/onboarding/widgets/finish_step.dart';
import 'package:keyel/features/onboarding/widgets/master_password_step.dart';
import 'package:keyel/features/onboarding/widgets/quick_unlock_step.dart';
import 'package:keyel/features/onboarding/widgets/recovery_steps.dart';
import 'package:keyel/features/onboarding/widgets/welcome_step.dart';
import 'package:keyel/ui/keyel.dart';

/// Five-step first-run flow: welcome, master password, recovery key, quick
/// unlock and a closing summary.
///
/// The screen owns the step machine and the vault creation; the step UIs
/// render each frame and report their result through callbacks.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the onboarding flow.
  const new({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _OnboardingStep { welcome, master, recovery, quickUnlock, finish }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _OnboardingStep _step = _OnboardingStep.welcome;
  String? _recoveryKey;
  String? _master;
  bool _quickUnlockEnabled = false;
  bool _busy = false;

  Future<void> _createVault(String master) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);

    try {
      final key = await ref.read(vaultSessionProvider.notifier).create(master);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _master = master;
        _recoveryKey = key;
        _step = _OnboardingStep.recovery;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Enables quick unlock while the freshly created master password is still
  /// in memory, so the user does not have to type it again.
  Future<bool> _enableQuickUnlock() async {
    final master = _master;
    if (master == null) return false;

    final enabled = await enableBiometricUnlock(master);
    if (!enabled || !mounted) return enabled;

    setState(() => _quickUnlockEnabled = true);
    showKeyelSnack(
      context,
      'Quick unlock enabled',
      icon: Icons.fingerprint_rounded,
    );
    return true;
  }

  void _finish() {
    _master = null;
    context.go(KeyelRoutes.vault);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCentered =
                  _step == _OnboardingStep.welcome ||
                  _step == _OnboardingStep.finish;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(KeyelSpacing.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (KeyelSpacing.xl * 2),
                    maxWidth: 460,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: isCentered
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.04),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: switch (_step) {
                            _OnboardingStep.welcome => WelcomeStep(
                              key: const ValueKey('onboarding-welcome'),
                              onGetStarted: () => setState(
                                () => _step = _OnboardingStep.master,
                              ),
                            ),
                            _OnboardingStep.master => MasterPasswordStep(
                              key: const ValueKey('onboarding-master'),
                              busy: _busy,
                              onBack: () => setState(
                                () => _step = _OnboardingStep.welcome,
                              ),
                              onCreate: (master) =>
                                  unawaited(_createVault(master)),
                            ),
                            _OnboardingStep.recovery => RecoveryKeyStep(
                              key: const ValueKey('onboarding-recovery'),
                              recoveryKey: _recoveryKey ?? '',
                              onContinue: () => setState(
                                () => _step = _OnboardingStep.quickUnlock,
                              ),
                            ),
                            _OnboardingStep.quickUnlock => QuickUnlockStep(
                              key: const ValueKey('onboarding-quick-unlock'),
                              onEnable: _enableQuickUnlock,
                              onContinue: () => setState(
                                () => _step = _OnboardingStep.finish,
                              ),
                            ),
                            _OnboardingStep.finish => FinishStep(
                              key: const ValueKey('onboarding-finish'),
                              biometricEnabled: _quickUnlockEnabled,
                              onOpenVault: _finish,
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
