import 'package:flutter/material.dart';

/// Hooks an entry controller uses to drive the owning screen.
class EntryDetailCallbacks {
  /// Creates the callback bundle.
  const new({
    required this.rebuild,
    required this.notify,
    required this.notifyError,
    required this.copy,
    required this.launchUrl,
    required this.confirmDelete,
    required this.pushEdit,
    required this.closeEntry,
    this.onDeleted,
    this.onEdited,
  });

  /// Rebuilds the screen after controller state changes.
  final VoidCallback rebuild;

  /// Shows an informational snack bar.
  final void Function(String message, {IconData? icon}) notify;

  /// Shows a snack bar formatted for a vault failure.
  final void Function(Object error) notifyError;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) copy;

  /// Launches a URI in the default external application; resolves false
  /// when the platform cannot open it.
  final Future<bool> Function(Uri uri) launchUrl;

  /// Asks the user to confirm deletion; resolves true when confirmed.
  final Future<bool> Function(String title) confirmDelete;

  /// Opens the editor route for an entry id and resolves on return.
  final Future<void> Function(String entryId) pushEdit;

  /// Pops the detail view after a confirmed deletion, when appropriate.
  final VoidCallback closeEntry;

  /// Optional callback when the entry was deleted.
  final VoidCallback? onDeleted;

  /// Optional callback when the entry was edited.
  final VoidCallback? onEdited;
}
