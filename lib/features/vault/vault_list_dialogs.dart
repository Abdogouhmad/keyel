import 'package:flutter/material.dart';

import 'package:keyel/features/folders/folder_picker_sheet.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Asks the user to confirm deleting [count] selected vault items.
Future<bool> confirmVaultDelete(BuildContext context, int count) =>
    KeyelConfirmDialog.show(
      context,
      title: 'Delete $count ${count == 1 ? 'item' : 'items'}?',
      body: count == 1
          ? 'This item will be moved to the trash.'
          : 'These items will be moved to the trash.',
      confirmLabel: 'Delete',
      destructive: true,
    );

/// Opens the folder picker used by the "move to folder" bulk action.
Future<FolderSelection?> pickVaultFolder(
  BuildContext context,
  List<FolderDto> folders,
) => showFolderPicker(context: context, folders: folders, selectedId: null);
