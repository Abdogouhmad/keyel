import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Asks the user to confirm deleting [title]; resolves true when confirmed.
///
/// The entry is only moved to the trash, so the copy says so explicitly.
Future<bool> confirmEntryDelete(BuildContext context, String title) {
  final l10n = l10nOf(context);
  return KeyelConfirmDialog.show(
    context,
    title: l10n.entryDeleteTitle(title),
    body: l10n.entryDeleteBody,
    confirmLabel: l10n.actionDelete,
    destructive: true,
  );
}
