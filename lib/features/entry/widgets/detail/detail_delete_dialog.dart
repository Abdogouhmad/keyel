import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Asks the user to confirm deleting [title]; resolves true when confirmed.
///
/// The entry is only moved to the trash, so the copy says so explicitly.
Future<bool> confirmEntryDelete(BuildContext context, String title) =>
    KeyelConfirmDialog.show(
      context,
      title: 'Delete $title?',
      body: 'This item will be moved to the trash.',
      confirmLabel: 'Delete',
      destructive: true,
    );
