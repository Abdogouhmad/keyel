import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';

/// Vault headline with the offline entry count and optional create button.
class VaultHeader extends StatelessWidget {
  /// Creates the vault header.
  const new({
    required this.entryCount,
    required this.isWide,
    required this.onNewItem,
    super.key,
  });

  /// Number of entries saved in the vault.
  final int entryCount;

  /// Whether the two-pane wide layout is active.
  final bool isWide;

  /// Called when the user wants to create a new entry.
  final VoidCallback onNewItem;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vault',
                style: textTheme.headlineLarge?.copyWith(
                  color: scheme.onSurface,
                  fontSize: 28,
                  height: 36 / 28,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: KeyelSpacing.sm),
                  Text(
                    '$entryCount ${entryCount == 1 ? "entry" : "entries"} '
                    'saved offline',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isWide)
          FilledButton.icon(
            onPressed: onNewItem,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Item'),
          ),
      ],
    );
  }
}
