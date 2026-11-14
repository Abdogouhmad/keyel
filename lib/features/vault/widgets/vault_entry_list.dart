import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_row.dart';
import 'package:keyel/ui/keyel.dart';

/// Typed callback invoked when a vault entry is opened.
typedef OnVaultEntryOpen = void Function(
  VaultEntry entry, {
  required bool isWide,
});

/// Shared callbacks and state used by the vault entry sections.
class VaultSectionConfig {
  /// Creates the section configuration.
  const new({
    required this.isWide,
    required this.selectedEntryId,
    required this.onOpenEntry,
    required this.onRefresh,
    this.selectionActive = false,
    this.selectedIds = const <String>{},
    this.onToggleSelection,
    this.onRowLongPress,
    this.onSwipeCopy,
    this.onSwipeFavorite,
  });

  /// Whether the two-pane wide layout is active.
  final bool isWide;

  /// Identifier of the entry selected in the wide layout detail pane.
  final String? selectedEntryId;

  /// Called when the user opens an entry.
  final OnVaultEntryOpen onOpenEntry;

  /// Called when an entry changed so the list can reload.
  final Future<void> Function() onRefresh;

  /// Whether the user is selecting multiple rows.
  final bool selectionActive;

  /// Entry ids marked in selection mode.
  final Set<String> selectedIds;

  /// Called when a row is tapped while selecting.
  final ValueChanged<VaultEntry>? onToggleSelection;

  /// Called when a row is long-pressed to start a selection.
  final ValueChanged<VaultEntry>? onRowLongPress;

  /// Called when a row is swiped to the start side (copy the secret).
  final ValueChanged<VaultEntry>? onSwipeCopy;

  /// Called when a row is swiped to the end side (toggle favorite).
  final ValueChanged<VaultEntry>? onSwipeFavorite;
}

/// Sliver list of vault entry rows separated by small gaps.
///
/// Rows are swipeable: towards the start side to copy the primary secret,
/// towards the end side to toggle the favorite flag. Both swipes run their
/// action and snap back — rows never leave the list.
class VaultEntryList extends StatelessWidget {
  /// Creates the entry list.
  const new({required this.entries, required this.config, super.key});

  /// Entries displayed as rows.
  final List<VaultEntry> entries;

  /// Shared section callbacks and selection state.
  final VaultSectionConfig config;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
      // Lazily build only the rows near the viewport. A 5,000-entry vault must
      // not inflate 5,000 row widgets (or 10,000 with gaps) on first paint;
      // `SliverList.list` did exactly that. See `docs/hardening-checklist.md`
      // (roadmap item 12).
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: KeyelSpacing.sm),
          child: _buildSwipeableRow(entries[index]),
        ),
      ),
    );
  }

  Widget _buildSwipeableRow(VaultEntry entry) {
    return Dismissible(
      key: ValueKey('vault-row-${entry.id}'),
      background: const _SwipeBackdrop(
        icon: Icons.content_copy_rounded,
        label: 'Copy',
        alignEnd: false,
      ),
      secondaryBackground: _SwipeBackdrop(
        icon: entry.favorite ? Icons.star_outline_rounded : Icons.star_rounded,
        label: entry.favorite ? 'Unfavorite' : 'Favorite',
        alignEnd: true,
      ),
      direction: config.selectionActive
          ? DismissDirection.none
          : DismissDirection.horizontal,
      confirmDismiss: (direction) => _confirmSwipe(entry, direction),
      child: VaultRow(
        entry: entry,
        favorite: entry.favorite,
        isSelected: config.isWide && config.selectedEntryId == entry.id,
        selectionActive: config.selectionActive,
        isMarked: config.selectedIds.contains(entry.id),
        onTap: () => config.selectionActive
            ? config.onToggleSelection?.call(entry)
            : config.onOpenEntry(entry, isWide: config.isWide),
        onLongPress: () => config.onRowLongPress?.call(entry),
        onRefresh: config.onRefresh,
      ),
    );
  }

  Future<bool> _confirmSwipe(VaultEntry entry, DismissDirection direction) {
    if (direction == DismissDirection.startToEnd) {
      unawaited(Haptics.light());
      config.onSwipeCopy?.call(entry);
    } else if (direction == DismissDirection.endToStart) {
      unawaited(Haptics.light());
      config.onSwipeFavorite?.call(entry);
    }
    // Always false: rows run their action but never leave the list.
    return Future<bool>.value(false);
  }
}

/// Direction-appropriate colored backdrop revealed behind a swiped row.
class _SwipeBackdrop extends StatelessWidget {
  const new({required this.icon, required this.label, required this.alignEnd});

  final IconData icon;

  final String label;

  /// Whether the backdrop content hugs the end of the row.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      alignment: alignEnd
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
      decoration: BoxDecoration(
        color: alignEnd ? scheme.secondaryContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: alignEnd
                ? scheme.onSecondaryContainer
                : scheme.onPrimaryContainer,
          ),
          const SizedBox(width: KeyelSpacing.sm),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: alignEnd
                  ? scheme.onSecondaryContainer
                  : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
