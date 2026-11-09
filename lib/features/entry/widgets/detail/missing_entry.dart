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
      appBar: AppBar(title: const Text('Item not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KeyelSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 56),
              const SizedBox(height: KeyelSpacing.md),
              Text(
                'No entry with ID "$entryId" exists.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KeyelSpacing.md),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
