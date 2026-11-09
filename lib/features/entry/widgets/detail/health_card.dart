import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/ui/keyel.dart';

/// Password health summary shown above the notes card.
class HealthCard extends StatelessWidget {
  /// Creates the health card.
  const new({required this.entry, this.revealedPassword, super.key});

  /// Entry being displayed.
  final VaultEntry entry;

  /// Plaintext password when revealed, otherwise `null`.
  final String? revealedPassword;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pass = revealedPassword;

    if (pass == null) {
      return KeyelSectionCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.field),
              ),
              child: Icon(Icons.lock_rounded, color: scheme.primary),
            ),
            const SizedBox(width: KeyelSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Encrypted & Protected',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Secrets stay encrypted with Argon2id & ChaCha20-Poly1305.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final strength = PasswordStrength.estimate(pass);
    final (accent, container, onContainer) = switch (strength.level) {
      PasswordStrengthLevel.strong => (
        scheme.strong,
        scheme.strongContainer,
        scheme.onStrongContainer,
      ),
      PasswordStrengthLevel.fair => (
        scheme.fair,
        scheme.fairContainer,
        scheme.onFairContainer,
      ),
      PasswordStrengthLevel.weak => (
        scheme.weak,
        scheme.weakContainer,
        scheme.onWeakContainer,
      ),
    };

    return KeyelSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: container,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(Icons.security_rounded, color: accent),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strength.label} password (${pass.length} chars)',
                  style: textTheme.titleMedium?.copyWith(
                    color: onContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Score: ${(strength.score * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                KeyelStrengthMeter(strength: strength),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
