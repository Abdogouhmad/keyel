import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Small, shared building blocks for the import/export bottom sheets.
///
/// Kept in one file because each part is only a few lines and they are used by
/// every sheet; the sheets themselves live in focused files next to this one.

/// Header shown at the top of every sheet: icon, title and subtitle.
class SheetHeader extends StatelessWidget {
  /// Creates a sheet header.
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  /// Leading icon in the rounded badge.
  final IconData icon;

  /// Sheet title.
  final String title;

  /// Supporting line under the title (usually a file name or explanation).
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(KeyelRadii.field),
          ),
          child: Icon(icon, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: KeyelSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Merge-or-replace choice shared by the restore and CSV import sheets.
class ModeSelector extends StatelessWidget {
  /// Creates a mode selector.
  const new({required this.mode, required this.onChanged, super.key});

  /// Currently selected mode.
  final ImportModeDto mode;

  /// Called with the newly selected mode.
  final ValueChanged<ImportModeDto> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Column(
      children: [
        ModeOption(
          icon: Icons.merge_rounded,
          title: l10n.imexMergeTitle,
          subtitle: l10n.imexMergeSubtitle,
          selected: mode == ImportModeDto.merge,
          onTap: () => onChanged(ImportModeDto.merge),
        ),
        const SizedBox(height: KeyelSpacing.xs),
        ModeOption(
          icon: Icons.swap_horiz_rounded,
          title: l10n.imexReplaceTitle,
          subtitle: l10n.imexReplaceSubtitle,
          selected: mode == ImportModeDto.replace,
          onTap: () => onChanged(ImportModeDto.replace),
        ),
      ],
    );
  }
}

/// A single selectable merge/replace option.
class ModeOption extends StatelessWidget {
  /// Creates a mode option.
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Option title.
  final String title;

  /// Short explanation of what the option does.
  final String subtitle;

  /// Whether this option is the current selection.
  final bool selected;

  /// Called when the option is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.field),
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: KeyelSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 20, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// One labelled count in a preview or report card.
class CountRow extends StatelessWidget {
  /// Creates a count row.
  const new({
    required this.icon,
    required this.label,
    required this.count,
    this.danger = false,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Human-readable label for the count.
  final String label;

  /// The value to display.
  final int count;

  /// Whether to style the row as an error (e.g. failed rows).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = danger ? scheme.error : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: danger ? scheme.error : scheme.primary),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: color),
            ),
          ),
          Text(
            '$count',
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lists the first rows that could not be imported, with an overflow summary.
class FailureList extends StatelessWidget {
  /// Creates a failure list.
  const new({required this.failures, super.key});

  /// Import failures to display (only the first 20 are shown).
  final List<ImportFailureDto> failures;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.imexFailureListTitle,
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KeyelSpacing.xs),
          for (final failure in failures.take(20))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.imexRowFailure(failure.row, failure.reason),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          if (failures.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.imexMoreFailures(failures.length - 20),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
