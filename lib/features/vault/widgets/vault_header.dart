import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
    final l10n = l10nOf(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // In the resizable master/detail pane the header can be much narrower
        // than the window. Keep the action, but collapse it to an icon until
        // the full label has room.
        final compactAction = constraints.maxWidth < 480;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.vaultTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      Expanded(
                        child: Text(
                          l10n.vaultEntriesSavedOffline(entryCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isWide)
              if (compactAction)
                IconButton(
                  onPressed: onNewItem,
                  tooltip: l10n.vaultNewItem,
                  icon: const Icon(Icons.add_rounded),
                  color: scheme.primary,
                )
              else
                FilledButton.icon(
                  onPressed: onNewItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.vaultNewItem),
                ),
          ],
        );
      },
    );
  }
}
