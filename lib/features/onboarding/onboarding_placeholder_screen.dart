import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/ui/design_system/keyel_buttons.dart';

/// Placeholder for the full onboarding flow that arrives in phase 0.6.
///
/// It keeps the router guard (no vault → `/onboarding`) testable without
/// the four-step design-spec onboarding.
class OnboardingPlaceholderScreen extends StatelessWidget {
  /// Creates the placeholder screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.key_rounded,
                size: 72,
                color: scheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Keyel',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No vault found on this device. The full onboarding flow '
                'arrives in phase 0.6; until then you can create a vault '
                'with the debug tools.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              KeyelPillButton(
                label: 'Open debug tools',
                icon: Icons.bug_report_outlined,
                onPressed: () => context.push(KeyelRoutes.debug),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
