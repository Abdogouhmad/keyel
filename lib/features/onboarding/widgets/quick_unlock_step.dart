import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/core/platform/biometric_auth.dart';
import 'package:keyel/features/onboarding/widgets/step_header.dart';
import 'package:keyel/ui/design_system/button_type.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';

/// Fourth onboarding frame: offer quick unlock with the system biometric.
///
/// The step only asks the operating system whether a biometric is enrolled;
/// the check itself is always the system prompt, never a Keyel-made one. When
/// the user opts in, [onEnable] runs while the master password is still in
/// memory from the creation step, so nothing has to be typed twice.
class QuickUnlockStep extends StatefulWidget {
  /// Creates the quick-unlock step.
  const new({
    required this.onEnable,
    required this.onContinue,
    super.key,
  });

  /// Enables quick unlock and reports whether it succeeded.
  final Future<bool> Function() onEnable;

  /// Advances to the final step.
  final VoidCallback onContinue;

  @override
  State<QuickUnlockStep> createState() => _QuickUnlockStepState();
}

class _QuickUnlockStepState extends State<QuickUnlockStep> {
  /// `null` while the platform check is still running.
  bool? _available;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAvailability());
  }

  Future<void> _checkAvailability() async {
    final available = await BiometricAuth.instance.isAvailable;
    if (mounted) setState(() => _available = available);
  }

  Future<void> _enable() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final enabled = await widget.onEnable();
      if (enabled && mounted) widget.onContinue();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          title: 'Unlock faster',
          subtitle:
              'Use your fingerprint or face to open the vault instead of '
              'typing the master password every time.',
        ),
        const SizedBox(height: KeyelSpacing.xl),
        Container(
          padding: const EdgeInsets.all(KeyelSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(KeyelRadii.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 28,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: KeyelSpacing.md),
              Expanded(
                child: Text(
                  'The check is performed by your device. Keyel never sees '
                  'your fingerprint or face.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KeyelSpacing.xl),
        _buildAction(context),
      ],
    );
  }

  Widget _buildAction(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (_available) {
      null => const Center(
        child: Padding(
          padding: EdgeInsets.all(KeyelSpacing.lg),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      false => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No biometrics are enrolled on this device. Set one up in system '
            'settings, then enable quick unlock later in Keyel settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: KeyelSpacing.lg),
          KeyelButtonM3(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            isFullWidth: true,
            onPressed: widget.onContinue,
          ),
        ],
      ),
      true => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyelButtonM3(
            label: 'Enable quick unlock',
            icon: Icons.fingerprint_rounded,
            isFullWidth: true,
            isLoading: _working,
            onPressed: _working ? null : () => unawaited(_enable()),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          KeyelButtonM3(
            label: 'Not now',
            type: ButtonType.text,
            isFullWidth: true,
            onPressed: _working ? null : widget.onContinue,
          ),
        ],
      ),
    };
  }
}
