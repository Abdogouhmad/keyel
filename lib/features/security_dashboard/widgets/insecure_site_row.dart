import 'package:flutter/material.dart';

import 'package:keyel/features/security_dashboard/widgets/audit_surface.dart';
import 'package:keyel/features/security_dashboard/widgets/mini_button.dart';
import 'package:keyel/ui/keyel.dart';

/// Audit row listing insecure HTTP websites found in the vault.
class InsecureSiteRow extends StatelessWidget {
  /// Creates the insecure site row.
  const new({required this.onFix, super.key});

  /// Invoked when the fix button is pressed.
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AuditSurface(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.no_encryption_rounded,
              size: 22,
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Insecure websites (HTTP)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: KeyelSpacing.sm),
                    KeyelBadge(
                      label: '1',
                      compact: true,
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Credentials sent in plain text',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm),
          MiniButton(
            label: 'Fix',
            background: scheme.surfaceContainer,
            foreground: scheme.primary,
            onTap: onFix,
          ),
        ],
      ),
    );
  }
}
