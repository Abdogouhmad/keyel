import 'package:flutter/material.dart';

import 'package:keyel/features/onboarding/widgets/step_badge.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';

/// First onboarding frame: the brand hello and a single call to action.
class WelcomeStep extends StatelessWidget {
  /// Creates the welcome step.
  const new({required this.onGetStarted, super.key});

  /// Advances to the master-password step.
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingStepBadge(icon: Icons.key_rounded, color: scheme.primary),
        const SizedBox(height: KeyelSpacing.xl),
        Text(
          'Welcome to Keyel',
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        Text(
          'Your passwords stay encrypted on this device. There is no account, '
          'no cloud, and no telemetry.',
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: KeyelSpacing.xl * 1.5),
        KeyelButtonM3(
          label: 'Get Started',
          icon: Icons.arrow_forward_rounded,
          isFullWidth: true,
          onPressed: onGetStarted,
        ),
      ],
    );
  }
}
