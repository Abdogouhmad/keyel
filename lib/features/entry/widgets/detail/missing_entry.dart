import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Fallback shown when an entry id does not resolve in the vault.
class MissingEntry extends StatelessWidget {
  /// Creates the fallback view.
  const new({required this.entryId, this.onBack, super.key});

  /// Identifier that could not be found.
  final String entryId;

  /// Returns to the previous screen. Defaults to a route pop.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    void goBack() {
      final onBack = this.onBack;
      if (onBack != null) {
        onBack();
      } else if (context.canPop()) {
        context.pop();
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: l10n.entryItemNotFound,
              icon: context.backArrow,
              iconTooltip: l10n.actionBack,
              onIconTap: goBack,
            ),
            const SizedBox(height: KeyelSpacing.lg),
            Expanded(
              child: KeyelStateMessage(
                kind: KeyelStateMessageKind.empty,
                message: l10n.entryMissingMessage(entryId),
                actionLabel: l10n.entryGoBack,
                actionIcon: context.backArrow,
                onAction: goBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
