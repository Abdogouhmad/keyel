import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';

/// Four-step first-run flow: welcome, master password, recovery key and
/// quick-unlock preferences.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the onboarding flow.
  const new({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _OnboardingStep { welcome, master, recovery, finish }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _OnboardingStep _step = _OnboardingStep.welcome;
  String? _recoveryKey;
  bool _obscure = true;
  bool _busy = false;
  bool _savedRecovery = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  PasswordStrength get _strength => PasswordStrength.estimate(_password.text);

  bool get _masterValid =>
      _password.text.length >= 8 &&
      _password.text == _confirm.text &&
      _strength.bits >= 50;

  Future<void> _createVault() async {
    if (!_masterValid) return;
    setState(() => _busy = true);
    try {
      final key = await ref
          .read(vaultSessionProvider.notifier)
          .create(_password.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
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

  void _finish() {
    context.go(KeyelRoutes.vault);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KeyelSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_step) {
                  _OnboardingStep.welcome => _welcomeStep(context),
                  _OnboardingStep.master => _masterStep(context),
                  _OnboardingStep.recovery => _recoveryStep(context),
                  _OnboardingStep.finish => _finishStep(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('onboarding-welcome'),
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.key_rounded, size: 48, color: scheme.primary),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        Text(
          'Welcome to Keyel',
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        Text(
          'Your passwords stay encrypted on this device. There is no account, '
          'no cloud and no telemetry.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: KeyelSpacing.xl),
        KeyelPillButton(
          label: 'Get started',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => setState(() => _step = _OnboardingStep.master),
        ),
      ],
    );
  }

  Widget _masterStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('onboarding-master'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create your master password',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KeyelSpacing.xs),
        Text(
          'This is the only key to your vault. We cannot reset it for you.',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        TextField(
          controller: _password,
          obscureText: _obscure,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Master password',
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
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
          controller: _confirm,
          obscureText: _obscure,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_masterValid) unawaited(_createVault());
          },
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: Icon(Icons.check_circle_outline_rounded),
          ),
        ),
        const SizedBox(height: KeyelSpacing.md),
        KeyelStrengthMeter(strength: _strength),
        const SizedBox(height: KeyelSpacing.lg),
        KeyelPillButton(
          label: _busy ? 'Creating vault…' : 'Continue',
          icon: _busy ? null : Icons.arrow_forward_rounded,
          onPressed: _busy || !_masterValid
              ? null
              : () => unawaited(_createVault()),
        ),
        TextButton(
          onPressed: () => setState(() => _step = _OnboardingStep.welcome),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _recoveryStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final key = _recoveryKey ?? '';
    return Column(
      key: const ValueKey('onboarding-recovery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Save your recovery key',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KeyelSpacing.xs),
        Text(
          'If you forget the master password, this key is the only way back '
          'into your vault. It is shown once.',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        Container(
          padding: const EdgeInsets.all(KeyelSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(KeyelRadii.field),
          ),
          child: SelectableText(
            key,
            style: const TextStyle(
              fontFamily: KeyelTheme.monoFamily,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        KeyelPillButton(
          label: 'Copy key',
          icon: Icons.content_copy_rounded,
          tone: KeyelButtonTone.neutral,
          height: 48,
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: key)));
            showKeyelSnack(
              context,
              'Recovery key copied',
              icon: Icons.content_copy_rounded,
            );
          },
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CheckboxListTile(
          value: _savedRecovery,
          onChanged: (value) => setState(() => _savedRecovery = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I stored this key somewhere safe'),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        KeyelPillButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _savedRecovery
              ? () => setState(() => _step = _OnboardingStep.finish)
              : null,
        ),
      ],
    );
  }

  Widget _finishStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('onboarding-finish'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_rounded, size: 64, color: scheme.primary),
        const SizedBox(height: KeyelSpacing.md),
        Text(
          'Your vault is ready',
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KeyelSpacing.xs),
        Text(
          'Keyel locks itself after one minute in the background. You can '
          'change this in Settings later.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        Container(
          padding: const EdgeInsets.all(KeyelSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(KeyelRadii.card),
          ),
          child: Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.sm),
              const Expanded(
                child: Text(
                  'Biometric unlock will be enabled in a later update. Until '
                  'then use your master password.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        KeyelPillButton(
          label: 'Open my vault',
          icon: Icons.shield_rounded,
          onPressed: _finish,
        ),
      ],
    );
  }
}
