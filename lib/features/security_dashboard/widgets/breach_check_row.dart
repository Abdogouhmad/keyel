import 'package:flutter/material.dart';

import 'package:keyel/features/security_dashboard/widgets/audit_surface.dart';
import 'package:keyel/ui/keyel.dart';

/// Audit row summarizing the offline breach check status.
class BreachCheckRow extends StatelessWidget {
  /// Creates the breach check row.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AuditSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: scheme.strongContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 22,
              color: scheme.strong,
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Offline breach check',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    KeyelBadge(
                      label: 'Pass',
                      compact: true,
                      background: scheme.strongContainer,
                      foreground: scheme.onStrongContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'No credentials found in known breach databases '
                  '(local bloom filter).',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.sync_rounded, size: 14, color: scheme.outline),
                    const SizedBox(width: KeyelSpacing.xs),
                    Expanded(
                      child: Text(
                        'Database sync: Today, 08:30 AM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
