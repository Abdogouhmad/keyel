import 'package:flutter/material.dart';

import 'package:keyel/features/onboarding/widgets/step_badge.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Final onboarding frame: lock-behaviour note and the vault entry action.
class FinishStep extends StatelessWidget {
  /// Creates the finish step.
  const new({
    required this.onOpenVault,
    this.biometricEnabled = false,
    super.key,
  });

  /// Leaves onboarding and opens the vault.
  final VoidCallback onOpenVault;

  /// Whether the user turned on biometric quick unlock.
  final bool biometricEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingStepBadge(icon: Icons.lock_rounded, color: scheme.primary),
        const SizedBox(height: KeyelSpacing.xl),
        Text(
          l10n.vaultReadyTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        Text(
          l10n.vaultReadySubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: KeyelSpacing.lg),

        // Info Card
        Container(
          padding: const EdgeInsets.all(KeyelSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(KeyelRadii.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  biometricEnabled
                      ? Icons.fingerprint_rounded
                      : Icons.timer_outlined,
                  color: scheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: KeyelSpacing.md),
              Expanded(
                child: Text(
                  biometricEnabled
                      ? l10n.vaultQuickUnlockOn
                      : l10n.vaultQuickUnlockLater,
                  style: TextStyle(color: scheme.onSurface, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KeyelSpacing.xl * 1.5),
        KeyelButtonM3(
          label: l10n.vaultOpenMyVault,
          icon: Icons.shield_rounded,
          isFullWidth: true,
          onPressed: onOpenVault,
        ),
      ],
    );
  }
}
