import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Top action bar of the entry detail view.
class DetailBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.favorite,
    required this.isEmbedded,
    required this.onBack,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// Whether the entry is currently favorited.
  final bool favorite;

  /// Whether this view is embedded in a wide-screen multi-pane layout.
  final bool isEmbedded;

  /// Called when the back button is tapped.
  final VoidCallback onBack;

  /// Called when the favorite button is tapped.
  final VoidCallback onFavorite;

  /// Called when the edit button is tapped.
  final VoidCallback onEdit;

  /// Called when the delete button is tapped.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KeyelSpacing.sm,
        vertical: KeyelSpacing.xs,
      ),
      child: Row(
        children: [
          if (!isEmbedded)
            KeyelIconHull(
              icon: Icons.arrow_back_rounded,
              tooltip: l10n.actionBack,
              onPressed: onBack,
            )
          else
            const SizedBox(width: KeyelSpacing.md),
          const Spacer(),
          KeyelIconHull(
            icon: favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            tooltip: favorite
                ? l10n.entryRemoveFavorite
                : l10n.entryAddToFavorites,
            foreground: favorite ? scheme.primary : scheme.onSurfaceVariant,
            onPressed: onFavorite,
          ),
          const SizedBox(width: KeyelSpacing.xs),
          KeyelIconHull(
            icon: Icons.edit_rounded,
            tooltip: l10n.entryEditEntry,
            onPressed: onEdit,
          ),
          const SizedBox(width: KeyelSpacing.xs),
          KeyelIconHull(
            icon: Icons.delete_outline_rounded,
            tooltip: l10n.entryDeleteEntry,
            foreground: scheme.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
