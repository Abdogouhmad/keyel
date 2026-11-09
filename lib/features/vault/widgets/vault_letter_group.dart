import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_entry_list.dart';
import 'package:keyel/ui/keyel.dart';

/// One alphabetical letter group: letter header plus its entry rows.
class VaultLetterGroup extends StatelessWidget {
  /// Creates the letter group.
  const new({
    required this.letter,
    required this.entries,
    required this.config,
    super.key,
  });

  /// Uppercase letter that groups the entries.
  final String letter;

  /// Entries grouped under the letter.
  final List<VaultEntry> entries;

  /// Shared section callbacks and selection state.
  final VaultSectionConfig config;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KeyelSpacing.md + KeyelSpacing.xs,
              KeyelSpacing.sm,
              KeyelSpacing.md + KeyelSpacing.xs,
              KeyelSpacing.sm,
            ),
            child: KeyelLetterHeader(letter: letter),
          ),
        ),
        VaultEntryList(entries: entries, config: config),
      ],
    );
  }
}
