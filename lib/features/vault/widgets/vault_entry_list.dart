import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_row.dart';
import 'package:keyel/ui/keyel.dart';

/// Typed callback invoked when a vault entry is opened.
typedef OnVaultEntryOpen =
    void Function(VaultEntry entry, {required bool isWide});

/// Shared callbacks and state used by the vault entry sections.
class VaultSectionConfig {
  /// Creates the section configuration.
  const new({
    required this.isWide,
    required this.selectedEntryId,
    required this.onOpenEntry,
    required this.onRefresh,
  });

  /// Whether the two-pane wide layout is active.
  final bool isWide;

  /// Identifier of the entry selected in the wide layout detail pane.
  final String? selectedEntryId;

  /// Called when the user opens an entry.
  final OnVaultEntryOpen onOpenEntry;

  /// Called when an entry changed so the list can reload.
  final Future<void> Function() onRefresh;
}

/// Sliver list of vault entry rows separated by small gaps.
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
      sliver: SliverList.list(
        children: [
          for (final entry in entries) ...[
            VaultRow(
              entry: entry,
              favorite: entry.favorite,
              isSelected:
                  config.isWide && config.selectedEntryId == entry.id,
              onTap: () =>
                  config.onOpenEntry(entry, isWide: config.isWide),
              onRefresh: config.onRefresh,
            ),
            const SizedBox(height: KeyelSpacing.sm),
          ],
        ],
      ),
    );
  }
}
