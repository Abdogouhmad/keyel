import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';

/// Empty vault message shown when no entries match.
class VaultEmptyState extends StatelessWidget {
  /// Creates the empty state view.
  const new({
    required this.query,
    required this.onClear,
    required this.onAddItem,
    super.key,
  });

  /// The active search query.
  final String query;

  /// Called when the user asks to clear the filters.
  final VoidCallback onClear;

  /// Called when the user wants to add the first item.
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final searching = query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.card),
              ),
              child: Icon(
                searching ? Icons.search_off_rounded : Icons.lock_open_rounded,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            Text(
              searching ? 'No matches found' : 'Your vault is empty',
              style: textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              searching
                  ? 'Try a different search term or filter.'
                  : 'Start adding passwords, payment cards, or secure notes. '
                        'Everything is stored locally with zero-knowledge '
                        'encryption.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            if (searching)
              KeyelPillButton(
                label: 'Clear filters',
                icon: Icons.refresh_rounded,
                tone: KeyelButtonTone.tonal,
                height: 48,
                expand: false,
                onPressed: onClear,
              )
            else
              FilledButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first item'),
              ),
          ],
        ),
      ),
    );
  }
}
