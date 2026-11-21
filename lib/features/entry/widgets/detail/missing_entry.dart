import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/ui/keyel.dart';

/// Fallback shown when an entry id does not resolve in the vault.
class MissingEntry extends StatelessWidget {
  /// Creates the fallback view.
  const new({required this.entryId, super.key});

  /// Identifier that could not be found.
  final String entryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Item not found',
              icon: Icons.arrow_back_rounded,
              iconTooltip: 'Back',
              onIconTap: () => context.pop(),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            Expanded(
              child: KeyelStateMessage(
                kind: KeyelStateMessageKind.empty,
                message: 'No entry with ID "$entryId" exists.',
                actionLabel: 'Go back',
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
