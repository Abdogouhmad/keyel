import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Sentinel selection for entries that are not assigned to a folder.
const noFolderSelection = '';

/// Horizontally scrolling folder filter used above the vault list.
class VaultFolderBar extends StatelessWidget {
  /// Creates the folder filter bar.
  const new({
    required this.folders,
    required this.selectedFolderId,
    required this.onFolderChanged,
    super.key,
  });

  /// Folders from the vault, in display order.
  final List<FolderDto> folders;

  /// `null` for all folders, [noFolderSelection] for unfiled entries, or an id.
  final String? selectedFolderId;

  /// Called with the newly selected folder selection.
  final ValueChanged<String?> onFolderChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
      child: Row(
        children: [
          KeyelFilterChip(
            label: l10n.vaultAllFolders,
            selected: selectedFolderId == null,
            onTap: () => onFolderChanged(null),
          ),
          const SizedBox(width: KeyelSpacing.sm),
          KeyelFilterChip(
            label: l10n.vaultNoFolder,
            selected: selectedFolderId == noFolderSelection,
            onTap: () => onFolderChanged(noFolderSelection),
          ),
          for (final folder in folders) ...[
            const SizedBox(width: KeyelSpacing.sm),
            KeyelFilterChip(
              label: folder.name,
              selected: selectedFolderId == folder.id,
              onTap: () => onFolderChanged(folder.id),
            ),
          ],
        ],
      ),
    );
  }
}
