import 'package:flutter/material.dart';

import 'package:keyel/features/security_dashboard/widgets/mini_button.dart';
import 'package:keyel/ui/keyel.dart';

/// Colored tile in the vulnerability summary grid.
class IssueCard extends StatelessWidget {
  /// Creates an issue card.
  const new({
    required this.background,
    required this.content,
    required this.accent,
    required this.countColor,
    required this.icon,
    required this.count,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.accentContent,
    this.actionBackground,
    this.actionForeground,
    super.key,
  });

  /// Fill color of the tile.
  final Color background;

  /// Primary content (title and subtitle) color.
  final Color content;

  /// Color of the icon hull and, by default, the action button.
  final Color accent;

  /// Color of the big count number.
  final Color countColor;

  /// Color of the icon glyph; falls back to white when omitted.
  final Color? accentContent;

  /// Icon displayed in the top-left hull.
  final IconData icon;

  /// Number of affected credentials.
  final int count;

  /// Category title.
  final String title;

  /// Short explanation under the title.
  final String subtitle;

  /// Label of the action button.
  final String actionLabel;

  /// Invoked when the action button is pressed.
  final VoidCallback onAction;

  /// Fill color of the action button; falls back to [accent].
  final Color? actionBackground;

  /// Text color of the action button; falls back to white.
  final Color? actionForeground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KeyelRadii.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: accentContent ?? Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$count',
                style: KeyelTheme.mono(
                  context,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: content,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: content.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          MiniButton(
            label: actionLabel,
            background: actionBackground ?? accent,
            foreground: actionForeground ?? Colors.white,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}
