import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_alphabetical_sections.dart';
import 'package:keyel/features/vault/widgets/vault_empty_state.dart';
import 'package:keyel/features/vault/widgets/vault_entry_list.dart';
import 'package:keyel/features/vault/widgets/vault_entry_section.dart';
import 'package:keyel/features/vault/widgets/vault_filter.dart';
import 'package:keyel/features/vault/widgets/vault_filter_bar.dart';
import 'package:keyel/features/vault/widgets/vault_header.dart';
import 'package:keyel/ui/keyel.dart';

/// The scrollable vault list shown when the session is unlocked.
class VaultListPane extends StatefulWidget {
  /// Creates the vault list pane.
  const new({
    required this.entries,
    required this.loading,
    required this.filter,
    required this.query,
    required this.selectedEntryId,
    required this.onLock,
    required this.onNewItem,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onOpenEntry,
    required this.onRefresh,
    super.key,
  });

  /// The entries currently loaded from the repository.
  final List<VaultEntry> entries;

  /// Whether an entry list reload is in flight.
  final bool loading;

  /// Currently selected filter family.
  final VaultFilter filter;

  /// The active search query.
  final String query;

  /// Identifier of the entry selected in the wide detail pane.
  final String? selectedEntryId;

  /// Called when the user taps the lock action.
  final VoidCallback onLock;

  /// Called when the user wants to create a new entry.
  final VoidCallback onNewItem;

  /// Called with the search text whenever it changes.
  final ValueChanged<String> onSearchChanged;

  /// Called with the newly selected filter family.
  final ValueChanged<VaultFilter> onFilterChanged;

  /// Called when the user asks to clear search and filters.
  final VoidCallback onClearFilters;

  /// Called when the user opens an entry.
  final OnVaultEntryOpen onOpenEntry;

  /// Called when an entry changed so the list can reload.
  final Future<void> Function() onRefresh;

  @override
  State<VaultListPane> createState() => _VaultListPaneState();
}

class _VaultListPaneState extends State<VaultListPane> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isWide(BuildContext context) {
    final windowClass = WindowSizeClass.of(context);
    return !windowClass.isCompact && MediaQuery.sizeOf(context).width >= 720;
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final isWide = _isWide(context);
    final favorites = entries.where((e) => e.favorite).toList();
    final others = entries.where((e) => !e.favorite).toList();
    final config = VaultSectionConfig(
      isWide: isWide,
      selectedEntryId: widget.selectedEntryId,
      onOpenEntry: widget.onOpenEntry,
      onRefresh: widget.onRefresh,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KeyelTopBar(
            title: 'Keyel Vault',
            icon: Icons.shield_rounded,
            trailing: KeyelIconHull(
              icon: Icons.lock_rounded,
              tooltip: 'Lock vault',
              onPressed: widget.onLock,
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
              onNewItem: widget.onNewItem,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
          sliver: SliverToBoxAdapter(
            child: KeyelSearchField(
              controller: _searchController,
              hintText: 'Search items, tags or notes...',
              onChanged: widget.onSearchChanged,
              trailing: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KeyelSpacing.md),
            child: VaultFilterBar(
              filter: widget.filter,
              onFilter: widget.onFilterChanged,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KeyelSpacing.lg)),
        if (widget.loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: VaultEmptyState(
              query: widget.query,
              onClear: () {
                _searchController.clear();
                widget.onClearFilters();
              },
              onAddItem: widget.onNewItem,
            ),
          )
        else if (widget.query.trim().isNotEmpty)
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
