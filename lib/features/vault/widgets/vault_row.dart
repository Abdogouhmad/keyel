import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_copy_button.dart';
import 'package:keyel/features/vault/widgets/vault_favorite_button.dart';
import 'package:keyel/features/vault/widgets/vault_row_details.dart';
import 'package:keyel/ui/keyel.dart';

/// Interactive row representing a single vault entry.
class VaultRow extends StatelessWidget {
  /// Creates a vault entry row.
  const new({
    required this.entry,
    required this.favorite,
    required this.isSelected,
    required this.onTap,
    required this.onRefresh,
    super.key,
  });

  /// The entry displayed by this row.
  final VaultEntry entry;

  /// Whether the entry is pinned to favorites.
  final bool favorite;

  /// Whether the row is the selected entry in the wide layout.
  final bool isSelected;

  /// Called when the user taps the row.
  final VoidCallback onTap;

  /// Called after the favorite flag was toggled so the list reloads.
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.tile),
      semanticLabel: 'Open ${entry.title}',
      child: Container(
        height: favorite ? 76 : 72,
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.sm + 4,
          vertical: KeyelSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.6)
              : scheme.surfaceContainer,
          border: isSelected
              ? Border.all(
                  color: scheme.primary.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : null,
          borderRadius: BorderRadius.circular(KeyelRadii.tile),
        ),
        child: Row(
          children: [
            KeyelAvatar(
              icon: entry.icon,
              tone: entry.avatarTone,
              shape: entry.avatarShape,
              size: favorite ? 48 : 44,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(child: VaultRowDetails(entry: entry)),
            const SizedBox(width: KeyelSpacing.sm),
            VaultFavoriteButton(entry: entry, onRefresh: onRefresh),
            if (entry.kind != VaultEntryKind.note) ...[
              const SizedBox(width: KeyelSpacing.xs),
              VaultCopyButton(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}
