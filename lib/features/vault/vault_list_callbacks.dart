import 'package:flutter/material.dart';

import 'package:keyel/features/folders/folder_picker_sheet.dart';

/// Hooks a vault list controller uses to drive the owning screen.
class VaultListCallbacks {
  /// Creates the callback bundle.
  const new({
    required this.rebuild,
    required this.notify,
    required this.notifyError,
    required this.copy,
    required this.confirmDelete,
    required this.pickFolder,
  });

  /// Rebuilds the screen after controller state changes.
  final VoidCallback rebuild;

  /// Shows an informational snack bar, optionally with an undo action.
  final void Function(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  })
  notify;

  /// Shows a snack bar formatted for a vault failure.
  final void Function(Object error) notifyError;

  /// Copies a value to the sensitive clipboard with feedback.
  final void Function(String value, String message) copy;

  /// Asks the user to confirm deleting count items.
  final Future<bool> Function(int count) confirmDelete;

  /// Opens the folder picker and resolves with the user's choice.
  final Future<FolderSelection?> Function() pickFolder;
}
