import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A note block whose plaintext is only rendered after an explicit reveal.
///
/// Used both for a secure note's body and for the free-form notes attached to
/// any other entry kind. Keeping one widget for both means one set of reveal,
/// auto-hide and copy rules, and no repository reads from `build()`.
class NotesCard extends StatelessWidget {
  /// Creates a gated note card.
  const new({
    required this.title,
    required this.icon,
    required this.revealedContent,
    required this.onToggleReveal,
    required this.onCopy,
    this.copyMessage,
    super.key,
  });

  /// Card heading, already localized.
  final String title;

  /// Heading glyph.
  final IconData icon;

  /// Plaintext note content when revealed, otherwise `null`.
  final String? revealedContent;

  /// Called to reveal or hide the note content.
  final VoidCallback onToggleReveal;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  /// Message shown after a successful copy. Defaults to the generic note copy.
  final String? copyMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final content = revealedContent;

    return KeyelSectionCard(
      title: title,
      icon: icon,
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                content != null
                    ? l10n.entryDecryptedNote
                    : l10n.entryEncryptedContent,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              KeyelPillButton(
                label: content != null
                    ? l10n.entryHideContent
                    : l10n.entryRevealNote,
                icon: content != null
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                tone: KeyelButtonTone.tonal,
                // Row children get unbounded width; a self-sizing pill avoids
                // forcing an infinite-width SizedBox inside the heading row.
                expand: false,
                onPressed: onToggleReveal,
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: KeyelSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KeyelSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.field),
              ),
              child: SelectableText(
                content,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    onCopy(content, copyMessage ?? l10n.entryNoteCopied),
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
