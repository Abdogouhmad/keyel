import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Entry notes loaded on demand from the vault repository.
class NotesCard extends ConsumerWidget {
  /// Creates the notes card.
  const new({required this.entryId, required this.onCopy, super.key});

  /// Identifier of the entry whose notes are shown.
  final String entryId;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: ref
          .read(vaultRepositoryProvider)
          .revealField(entryId, SecretFieldDto.entryNotes),
      builder: (context, snapshot) {
        final notes = snapshot.data;
        if (notes == null || notes.isEmpty) return const SizedBox.shrink();

        return KeyelSectionCard(
          title: l10nOf(context).entryNotes,
          icon: Icons.notes_rounded,
          showBorder: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KeyelSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: SelectableText(
              notes,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurface, height: 1.5),
            ),
          ),
        );
      },
    );
  }
}
