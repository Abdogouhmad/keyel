import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Standardized onboarding title and subtitle for the form steps.
class OnboardingStepHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.title, required this.subtitle, super.key});

  /// Large step title.
  final String title;

  /// Supporting copy shown under the title.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        Text(
          subtitle,
          style: text.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
