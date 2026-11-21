import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Revealable secure-note content block.
class NoteDetails extends StatelessWidget {
  /// Creates the note content block.
  const new({
    required this.entry,
    required this.detail,
    required this.revealedContent,
    required this.onToggleReveal,
    required this.onCopy,
    super.key,
  });

  /// Entry being displayed.
  final VaultEntry entry;

  /// Detail record of the entry.
  final EntryDetailDto detail;

  /// Plaintext note content when revealed, otherwise `null`.
  final String? revealedContent;

  /// Called to reveal or hide the note content.
  final VoidCallback onToggleReveal;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return KeyelSectionCard(
      title: l10n.entrySecureNoteContent,
      icon: Icons.description_rounded,
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                revealedContent != null
                    ? l10n.entryDecryptedNote
                    : l10n.entryEncryptedContent,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              KeyelPillButton(
                label: revealedContent != null
                    ? l10n.entryHideContent
                    : l10n.entryRevealNote,
                icon: revealedContent != null
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                tone: KeyelButtonTone.tonal,
                onPressed: onToggleReveal,
              ),
            ],
          ),
          if (revealedContent != null) ...[
            const SizedBox(height: KeyelSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KeyelSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.field),
              ),
              child: SelectableText(
                revealedContent!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onCopy(revealedContent!, l10n.entryNoteCopied),
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                label: Text(l10n.entryCopyFullNote),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
