import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Toolbar that replaces the vault top bar while rows are multi-selected.
///
/// Shows the number of marked rows plus the bulk actions: toggle favorite,
/// move to folder, delete, and select-all / clear. The close button and the
/// system back button both leave selection mode.
class VaultSelectionBar extends StatelessWidget {
  /// Creates the selection toolbar.
  const new({
    required this.selectedCount,
    required this.allSelected,
    required this.onClose,
    required this.onSelectAll,
    required this.onToggleFavorite,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  /// Number of rows currently marked.
  final int selectedCount;

  /// Whether every visible row is marked.
  final bool allSelected;

  /// Called when the user leaves selection mode.
  final VoidCallback onClose;

  /// Called when the user selects all rows or clears the selection.
  final VoidCallback onSelectAll;

  /// Called when the user toggles favorites for the selection.
  final VoidCallback onToggleFavorite;

  /// Called when the user moves the selection to a folder.
  final VoidCallback onMove;

  /// Called when the user deletes the selection.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
        child: Row(
          children: [
            KeyelIconHull(
              icon: Icons.close_rounded,
              tooltip: l10n.vaultExitSelection,
              onPressed: onClose,
              background: scheme.secondaryContainer,
              foreground: scheme.primary,
              size: 40,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(
              child: Text(
                l10n.vaultItemsSelected(selectedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            KeyelIconHull(
              icon: allSelected
                  ? Icons.deselect_rounded
                  : Icons.select_all_rounded,
              tooltip: allSelected
                  ? l10n.vaultClearSelection
                  : l10n.vaultSelectAll,
              onPressed: onSelectAll,
              size: 40,
              iconSize: 20,
            ),
            KeyelIconHull(
              icon: Icons.star_rounded,
              tooltip: l10n.vaultToggleFavorite,
              onPressed: onToggleFavorite,
              size: 40,
              iconSize: 20,
            ),
            KeyelIconHull(
              icon: Icons.drive_file_move_rounded,
              tooltip: l10n.vaultMoveToFolder,
              onPressed: onMove,
              size: 40,
              iconSize: 20,
            ),
            KeyelIconHull(
              icon: Icons.delete_outline_rounded,
              tooltip: l10n.actionDelete,
              onPressed: onDelete,
              foreground: scheme.error,
              size: 40,
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
