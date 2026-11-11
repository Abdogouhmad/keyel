import 'package:flutter/material.dart';

import 'package:keyel/features/security_dashboard/health_category.dart';
import 'package:keyel/features/security_dashboard/widgets/mini_button.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Bottom sheet listing the entries affected by one health category.
///
/// Pops with the id of the entry the user wants to fix, or `null` when
/// dismissed.
class HealthIssueSheet extends StatelessWidget {
  /// Creates the sheet for [category] with its [issues].
  const new({required this.category, required this.issues, super.key});

  /// Category being listed.
  final HealthCategory category;

  /// Entries affected by the category.
  final List<HealthIssueDto> issues;

  /// Shows the sheet and resolves to the chosen entry id, or `null`.
  static Future<String?> show(
    BuildContext context, {
    required HealthCategory category,
    required List<HealthIssueDto> issues,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HealthIssueSheet(category: category, issues: issues),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KeyelRadii.card),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        KeyelSpacing.md,
        KeyelSpacing.sm,
        KeyelSpacing.md,
        KeyelSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
              ),
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Row(
            children: [
              Icon(category.icon, size: 22, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.sm),
              Expanded(
                child: Text(
                  category.title,
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              KeyelBadge(
                label: '${issues.length}',
                compact: true,
                background: scheme.surfaceContainerHigh,
                foreground: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            category.subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Flexible(
            child: issues.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: KeyelSpacing.lg,
                    ),
                    child: Text(
                      'Nothing to fix here.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: issues.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KeyelSpacing.sm),
                    itemBuilder: (context, index) =>
                        _IssueRow(issue: issues[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const new({required this.issue});

  final HealthIssueDto issue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.sm + 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.key_rounded,
              size: 20,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (issue.subtitle.isNotEmpty)
                  Text(
                    issue.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            background: scheme.surfaceContainerHigh,
            foreground: scheme.primary,
            onTap: () => Navigator.of(context).pop(issue.id),
          ),
        ],
      ),
    );
  }
}
