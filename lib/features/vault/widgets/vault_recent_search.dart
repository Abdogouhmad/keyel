import 'package:flutter/material.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/ui/keyel.dart';

/// Chips for the most recent vault searches, with a "Clear" action.
///
/// Show it only while the search field is focused and empty. It renders
/// nothing when there are no remembered searches.
class VaultRecentSearches extends StatefulWidget {
  /// Creates the recent-searches strip.
  const new({required this.onSelected, super.key});

  /// Called with the tapped search term.
  final ValueChanged<String> onSelected;

  @override
  State<VaultRecentSearches> createState() => _VaultRecentSearchesState();
}

class _VaultRecentSearchesState extends State<VaultRecentSearches> {
  @override
  Widget build(BuildContext context) {
    final searches = AppPreferences.instance.recentSearches;
    if (searches.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KeyelSpacing.md,
        KeyelSpacing.sm,
        KeyelSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent searches',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  AppPreferences.instance.clearRecentSearches();
                  setState(() {});
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          Wrap(
            spacing: KeyelSpacing.sm,
            runSpacing: KeyelSpacing.xs,
            children: [
              for (final term in searches)
                ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 18),
                  label: Text(term),
                  onPressed: () => widget.onSelected(term),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
