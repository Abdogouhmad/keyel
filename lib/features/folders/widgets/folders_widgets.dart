import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A single folder row with rename and delete actions.
class FolderTile extends StatelessWidget {
  /// Creates a folder tile.
  const new({
    required this.folder,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  /// Folder to display.
  final FolderDto folder;

  /// Starts folder rename flow.
  final VoidCallback onRename;

  /// Starts folder delete flow.
  final VoidCallback onDelete;

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
              color: scheme.primaryFixed,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(Icons.folder_rounded, color: scheme.onPrimaryFixed),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          KeyelIconHull(
            icon: Icons.edit_rounded,
            tooltip: l10n.fldRenameFolder,
            onPressed: onRename,
            size: 40,
            iconSize: 20,
          ),
          KeyelIconHull(
            icon: Icons.delete_outline_rounded,
            tooltip: l10n.fldDeleteFolder,
            onPressed: onDelete,
            foreground: scheme.error,
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

/// Empty-state view for the folders screen.
class FoldersEmptyState extends StatelessWidget {
  /// Creates a folders empty state.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);

    return KeyelStateMessage(
      kind: KeyelStateMessageKind.empty,
      icon: Icons.folder_open_rounded,
      title: l10n.folderEmpty,
      message: l10n.fldEmptyMessage,
    );
  }
}
