import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Fallback shown when an entry id does not resolve in the vault.
class MissingEntry extends StatelessWidget {
  /// Creates the fallback view.
  const new({required this.entryId, super.key});

  /// Identifier that could not be found.
  final String entryId;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: l10n.entryItemNotFound,
              icon: Icons.arrow_back_rounded,
              iconTooltip: l10n.actionBack,
              onIconTap: () => context.pop(),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            Expanded(
              child: KeyelStateMessage(
                kind: KeyelStateMessageKind.empty,
                message: l10n.entryMissingMessage(entryId),
                actionLabel: l10n.entryGoBack,
                actionIcon: Icons.arrow_back_rounded,
                onAction: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
