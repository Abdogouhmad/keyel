import 'package:flutter/material.dart';

import 'package:keyel/features/folders/folder_picker_sheet.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Asks the user to confirm deleting [count] selected vault items.
Future<bool> confirmVaultDelete(BuildContext context, int count) {
  final l10n = l10nOf(context);
  return KeyelConfirmDialog.show(
    context,
    title: l10n.vaultDeleteItemsTitle(count),
    body: count == 1
        ? l10n.vaultDeleteOneItemBody
        : l10n.vaultDeleteManyItemsBody,
    confirmLabel: l10n.actionDelete,
    destructive: true,
  );
}

/// Opens the folder picker used by the "move to folder" bulk action.
Future<FolderSelection?> pickVaultFolder(
  BuildContext context,
  List<FolderDto> folders,
) => showFolderPicker(context: context, folders: folders, selectedId: null);
