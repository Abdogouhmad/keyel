import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';

import 'package:keyel/features/vault/widgets/vault_entry_list.dart';
import 'package:keyel/features/vault/widgets/vault_letter_group.dart';

/// Non-favorite entries split into sorted alphabetical letter groups.
class VaultAlphabeticalSections extends StatelessWidget {
  /// Creates the alphabetical sections.
  const new({required this.entries, required this.config, super.key});

  /// Entries grouped by the first letter of their title.
  final List<VaultEntry> entries;

  /// Shared section callbacks and selection state.
  final VaultSectionConfig config;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<VaultEntry>>{};
    for (final entry in entries) {
      final letter = entry.title.isEmpty
          ? '#'
          : entry.title.substring(0, 1).toUpperCase();
      groups.putIfAbsent(letter, () => []).add(entry);
    }
    final letters = groups.keys.toList()..sort();

    return SliverMainAxisGroup(
      slivers: [
        for (final letter in letters)
          VaultLetterGroup(
            letter: letter,
            entries: groups[letter]!,
            config: config,
          ),
      ],
    );
  }
}
