import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/vault_list_controller.dart';
import 'package:keyel/features/vault/widgets/vault_alphabetical_sections.dart';
import 'package:keyel/features/vault/widgets/vault_empty_state.dart';
import 'package:keyel/features/vault/widgets/vault_entry_list.dart';
import 'package:keyel/features/vault/widgets/vault_entry_section.dart';
import 'package:keyel/features/vault/widgets/vault_filter_bar.dart';
import 'package:keyel/features/vault/widgets/vault_folder_bar.dart';
import 'package:keyel/features/vault/widgets/vault_header.dart';
import 'package:keyel/features/vault/widgets/vault_search_bar.dart';
import 'package:keyel/features/vault/widgets/vault_selection_bar.dart';
import 'package:keyel/ui/keyel.dart';

/// The scrollable vault list shown when the session is unlocked.
class VaultListPane extends StatelessWidget {
  /// Creates the vault list pane.
  const new({
    required this.controller,
    required this.onLock,
    required this.onNewItem,
    required this.onOpenEntry,
    super.key,
  });

  /// Owns the entries, filters and row selection shown here.
  final VaultListController controller;

  /// Called when the user taps the lock action.
  final VoidCallback onLock;

  /// Called when the user wants to create a new entry.
  final VoidCallback onNewItem;

  /// Called when the user opens an entry.
  final OnVaultEntryOpen onOpenEntry;

  bool _isWide(BuildContext context) {
    final windowClass = WindowSizeClass.of(context);
    return !windowClass.isCompact && MediaQuery.sizeOf(context).width >= 720;
  }

  void _handleRowLongPress(VaultEntry entry) {
    unawaited(Haptics.medium());
    controller.startSelection(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = controller.entries;
    final isWide = _isWide(context);
    final favorites = entries.where((e) => e.favorite).toList();
    final others = entries.where((e) => !e.favorite).toList();
    final config = VaultSectionConfig(
      isWide: isWide,
      selectedEntryId: controller.selectedEntryId,
      onOpenEntry: onOpenEntry,
      onRefresh: controller.load,
      selectionActive: controller.selectionMode,
      selectedIds: controller.selectedIds,
      onToggleSelection: (entry) {
        unawaited(Haptics.selection());
        controller.toggleSelection(entry.id);
      },
      onRowLongPress: _handleRowLongPress,
      onSwipeCopy: (entry) => unawaited(controller.copyPrimarySecret(entry)),
      onSwipeFavorite: (entry) => unawaited(controller.toggleFavorite(entry)),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: controller.selectionMode
              ? VaultSelectionBar(
                  selectedCount: controller.selectedIds.length,
                  allSelected: controller.allSelected,
                  onClose: controller.clearSelection,
                  onSelectAll: controller.toggleSelectAll,
                  onToggleFavorite: () =>
                      unawaited(controller.toggleFavoriteSelection()),
                  onMove: () => unawaited(controller.moveSelection()),
                  onDelete: () => unawaited(controller.deleteSelection()),
                )
              : KeyelTopBar(
                  title: 'Keyel Vault',
                  icon: Icons.shield_rounded,
                  trailing: KeyelIconHull(
                    icon: Icons.lock_rounded,
                    tooltip: 'Lock vault',
                    onPressed: onLock,
                  ),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KeyelSpacing.lg,
              KeyelSpacing.xs,
              KeyelSpacing.lg,
              KeyelSpacing.md,
            ),
            child: VaultHeader(
              entryCount: entries.length,
              isWide: isWide,
              onNewItem: onNewItem,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
          sliver: SliverToBoxAdapter(
            child: VaultSearchBar(
              query: controller.query,
              onSearchChanged: controller.onSearchChanged,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KeyelSpacing.md),
            child: VaultFilterBar(
              filter: controller.filter,
              onFilter: controller.setFilter,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KeyelSpacing.sm),
            child: VaultFolderBar(
              folders: controller.folders,
              selectedFolderId: controller.folderId,
              onFolderChanged: controller.setFolder,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KeyelSpacing.lg)),
        if (controller.loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: VaultEmptyState(
              query: controller.query,
              onClear: controller.clearFilters,
              onAddItem: onNewItem,
            ),
          )
        else if (controller.query.trim().isNotEmpty)
          VaultEntrySection(
            config: config,
            title: 'Results',
            count: entries.length,
            entries: entries,
          )
        else ...[
          if (favorites.isNotEmpty)
            VaultEntrySection(
              config: config,
              title: 'Favorites',
              count: favorites.length,
              entries: favorites,
              icon: Icons.star_rounded,
            ),
          VaultAlphabeticalSections(entries: others, config: config),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}
