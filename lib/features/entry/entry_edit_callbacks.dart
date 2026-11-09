import 'package:flutter/material.dart';

/// Hooks the edit controller uses to drive the owning screen.
class EntryEditCallbacks {
  /// Creates the callback bundle.
  const new({
    required this.rebuild,
    required this.notify,
    required this.notifyError,
    required this.close,
  });

  /// Rebuilds the screen after controller state changes.
  final VoidCallback rebuild;

  /// Shows an informational snack bar.
  final void Function(String message, {IconData? icon}) notify;

  /// Shows a snack bar formatted for a vault failure.
  final void Function(Object error) notifyError;

  /// Pops the editor after a successful save.
  final VoidCallback close;
}
