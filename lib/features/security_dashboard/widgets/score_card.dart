import 'package:flutter/material.dart';

import 'package:keyel/features/security_dashboard/widgets/score_gauge.dart';
import 'package:keyel/ui/keyel.dart';

/// Hero card summarizing overall vault health with a call to optimize.
class ScoreCard extends StatelessWidget {
  /// Creates the score card.
  const new({required this.onOptimize, super.key});

  /// Invoked when the optimize vault button is pressed.
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.lg - 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Column(
        children: [
          ScoreGauge(
            score: 88,
            accent: scheme.strong,
            track: scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: KeyelSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KeyelSpacing.sm + 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(KeyelRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.strong,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Text(
                  'Vault health: Good',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Text(
            '4 items need your attention to reach 100%',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          KeyelPillButton(
            label: 'Optimize vault',
            icon: Icons.auto_fix_high_rounded,
            height: 52,
            onPressed: onOptimize,
          ),
        ],
      ),
    );
  }
}
