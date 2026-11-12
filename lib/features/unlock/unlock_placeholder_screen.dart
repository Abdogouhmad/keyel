import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/ui/design_system/keyel_buttons.dart';

/// Placeholder for the real unlock screen that arrives in phase 0.6.
///
/// It keeps the router guard (locked → `/unlock`) testable before the
/// password field, biometrics and auto-lock land.
class UnlockPlaceholderScreen extends StatelessWidget {
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
              Icon(Icons.lock_outline_rounded, size: 72, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'Vault locked',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The real unlock flow (password, biometrics, auto-lock) '
                'arrives in phase 0.6. Until then use the debug screen to '
                'unlock this vault.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              KeyelPillButton(
                label: 'Open debug tools',
                icon: Icons.bug_report_outlined,
                tone: KeyelButtonTone.tonal,
                onPressed: () => context.push(KeyelRoutes.debug),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
