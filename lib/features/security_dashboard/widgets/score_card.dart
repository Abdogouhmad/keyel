import 'package:flutter/material.dart';

import 'package:keyel/features/security_dashboard/widgets/score_gauge.dart';
import 'package:keyel/ui/keyel.dart';

/// Hero card summarizing overall vault health with a call to review issues.
class ScoreCard extends StatelessWidget {
  /// Creates the score card.
  const new({
    required this.score,
    required this.issueCount,
    required this.onOptimize,
    super.key,
  });

  /// Vault health score from 0 to 100.
  final int score;

  /// Number of affected credentials across all categories.
  final int issueCount;

  /// Invoked when the review button is pressed.
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (accent, label, status) = switch (score) {
      >= 90 => (scheme.strong, 'Excellent', 'SECURE'),
      >= 70 => (scheme.strong, 'Good', 'SECURE'),
      >= 40 => (scheme.fair, 'Fair', 'REVIEW'),
      _ => (scheme.weak, 'At risk', 'AT RISK'),
    };

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.lg - 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Column(
        children: [
          ScoreGauge(
            score: score,
            accent: accent,
            track: scheme.surfaceContainerHighest,
            statusLabel: status,
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
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Flexible(
                  child: Text(
                    'Vault health: $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Text(
            issueCount == 0
                ? 'No issues found. Your vault is in great shape.'
                : '$issueCount ${issueCount == 1 ? 'item needs' : 'items need'} '
                      'your attention',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (issueCount > 0) ...[
            const SizedBox(height: KeyelSpacing.md),
            KeyelPillButton(
              label: 'Review issues',
              icon: Icons.auto_fix_high_rounded,
              height: 52,
              onPressed: onOptimize,
            ),
          ],
        ],
      ),
    );
  }
}
