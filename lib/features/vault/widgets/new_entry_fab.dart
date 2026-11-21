import 'package:flutter/material.dart';

import 'package:keyel/ui/l10n/l10n.dart';

/// Extended floating action button that opens the new entry flow.
class NewEntryFab extends StatelessWidget {
  /// Creates the floating action button.
  const new({required this.onTap, super.key});

  /// Called when the user taps the button.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: onTap,
      elevation: 3,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        l10nOf(context).vaultNewItem,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
