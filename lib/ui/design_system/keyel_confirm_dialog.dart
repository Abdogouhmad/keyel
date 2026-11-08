import 'package:flutter/material.dart';

import 'package:keyel/ui/theme/keyel_theme.dart';

/// A destructive-action confirmation dialog (28 dp corners,
/// red-danger copy for destructive variants).
class KeyelConfirmDialog extends StatelessWidget {
  /// Creates a confirmation dialog.
  const new({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    super.key,
  });

  /// The question ("Delete these items?").
  final String title;

  /// One-line explanation of the consequence.
  final String body;

  /// Confirm button copy ("Delete forever").
  final String confirmLabel;

  /// Cancel button copy.
  final String cancelLabel;

  /// Whether confirm is destructive (danger colours).
  final bool destructive;

  /// Shows the dialog and returns whether the action was confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => KeyelConfirmDialog(
            title: title,
            body: body,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            destructive: destructive,
          ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Text(
        body,
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor:
                destructive ? scheme.error : scheme.primary,
            foregroundColor:
                destructive ? scheme.onError : scheme.onPrimary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
