import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A single trashed vault entry row.
class TrashEntryTile extends StatelessWidget {
  /// Creates a trash entry tile.
  const new({
    required this.entry,
    required this.busy,
    required this.onRestore,
    required this.onPurge,
    super.key,
  });

  /// Trashed entry summary.
  final EntrySummaryDto entry;

  /// Whether trash actions are temporarily disabled.
  final bool busy;

  /// Restores the entry.
  final VoidCallback onRestore;

  /// Permanently deletes the entry.
  final VoidCallback onPurge;

  String _remainingLabel(BuildContext context) {
    final l10n = l10nOf(context);
    final deletedAt = entry.deletedAt;
    if (deletedAt == null) return l10n.trashDeleted;
    final deleted = DateTime.fromMillisecondsSinceEpoch(
      deletedAt.toInt() * 1000,
    );
    final days = 30 - DateTime.now().difference(deleted).inDays;
    final remaining = days < 0 ? 0 : days;
    return l10n.trashAutoDelete(remaining);
  }

  IconData get _kindIcon => switch (entry.kind) {
    EntryKindDto.login => Icons.key_rounded,
    EntryKindDto.card => Icons.credit_card_rounded,
    EntryKindDto.note => Icons.sticky_note_2_rounded,
    EntryKindDto.passkey => Icons.vpn_key_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return KeyelSectionCard(
      showBorder: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(_kindIcon, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _remainingLabel(context),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          KeyelIconHull(
            icon: Icons.restore_rounded,
            tooltip: l10n.actionRestore,
            foreground: scheme.primary,
            size: 40,
            iconSize: 20,
            onPressed: busy ? null : onRestore,
          ),
          KeyelIconHull(
            icon: Icons.delete_forever_rounded,
            tooltip: l10n.trashDeleteForever,
            foreground: scheme.error,
            size: 40,
            iconSize: 20,
            onPressed: busy ? null : onPurge,
          ),
        ],
      ),
    );
  }
}

/// Empty-state view for the trash screen.
class TrashEmptyState extends StatelessWidget {
  /// Creates a trash empty state.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);

    return KeyelStateMessage(
      kind: KeyelStateMessageKind.empty,
      icon: Icons.delete_outline_rounded,
      title: l10n.trashEmpty,
      message: l10n.trashEmptyMessage,
    );
  }
}

/// Informational banner shown above the trash list.
class TrashInfoBanner extends StatelessWidget {
  /// Creates a trash info banner.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KeyelSpacing.lg,
        KeyelSpacing.xs,
        KeyelSpacing.lg,
        KeyelSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Text(
              l10nOf(context).trashBannerMessage,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
