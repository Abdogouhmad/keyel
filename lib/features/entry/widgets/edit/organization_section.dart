import 'package:flutter/material.dart';

import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Folder picker row and favorites switch.
class OrganizationSection extends StatelessWidget {
  /// Creates the organization section.
  const new({
    required this.favorite,
    required this.folder,
    required this.onFavoriteChanged,
    required this.onFolderTap,
    super.key,
  });

  /// Whether the entry is pinned to favorites.
  final bool favorite;

  /// Label of the entry's current folder.
  final String folder;

  /// Called when the favorites switch changes.
  final ValueChanged<bool> onFavoriteChanged;

  /// Called when the folder row is tapped.
  final VoidCallback onFolderTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return EditSection(
      child: Column(
        children: [
          PressableScale(
            onTap: onFolderTap,
            borderRadius: BorderRadius.circular(KeyelRadii.field),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 24,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KeyelSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.entryFolder,
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          folder,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const KeyelRule(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 24, color: scheme.primary),
                const SizedBox(width: KeyelSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.entryAddToFavorites,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.entryPinToQuickAccess,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: favorite, onChanged: onFavoriteChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
