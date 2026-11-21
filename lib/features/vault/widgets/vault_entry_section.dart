import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_entry_list.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A titled section of vault entries rendered as slivers.
class VaultEntrySection extends StatelessWidget {
  /// Creates the entry section.
  const new({
    required this.config,
    required this.title,
    required this.count,
    required this.entries,
    this.icon,
    super.key,
  });

  /// Shared section callbacks and selection state.
  final VaultSectionConfig config;

  /// Section title.
  final String title;

  /// Number of entries in the section.
  final int count;

  /// Entries listed below the section header.
  final List<VaultEntry> entries;

  /// Optional icon rendered next to the section title.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KeyelSpacing.xs,
                KeyelSpacing.xs,
                KeyelSpacing.xs,
                KeyelSpacing.sm + 2,
              ),
              child: KeyelSectionLabel(
                label: title,
                icon: icon,
                trailing: Text(
                  l10n.vaultItemCount(count),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        VaultEntryList(entries: entries, config: config),
      ],
    );
  }
}
