import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/detail/detail_bar.dart';
import 'package:keyel/features/entry/widgets/detail/detail_content.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Scaffold chrome around the entry detail body.
///
/// Composes the top action bar, the kind-specific content list and the edit
/// call-to-action docked below the body on narrow layouts.
class DetailScaffold extends StatelessWidget {
  /// Creates the detail scaffold.
  const new({
    required this.entry,
    required this.detail,
    required this.isEmbedded,
    required this.revealedPassword,
    required this.revealedCardNumber,
    required this.revealedCvv,
    required this.revealedNote,
    required this.revealedCustomFields,
    required this.onBack,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleRevealPassword,
    required this.onToggleRevealCard,
    required this.onToggleRevealNote,
    required this.onToggleRevealCustomField,
    required this.onCopy,
    required this.onCopyPassword,
    required this.onCopyCustomField,
    required this.onOpenUrl,
    super.key,
  });

  /// Entry being displayed.
  final VaultEntry entry;

  /// Detail record of the entry.
  final EntryDetailDto detail;

  /// Whether this view is embedded in a wide-screen multi-pane layout.
  final bool isEmbedded;

  /// Revealed login password, or `null` when hidden.
  final String? revealedPassword;

  /// Revealed card number, or `null` when hidden.
  final String? revealedCardNumber;

  /// Revealed card security code, or `null` when hidden.
  final String? revealedCvv;

  /// Revealed note content, or `null` when hidden.
  final String? revealedNote;

  /// Revealed hidden custom-field values keyed by custom-field id.
  final Map<String, String> revealedCustomFields;

  /// Called when the back button is tapped.
  final VoidCallback onBack;

  /// Toggles the entry's favorite flag.
  final VoidCallback onFavorite;

  /// Opens the entry editor.
  final VoidCallback onEdit;

  /// Deletes the entry after confirmation.
  final VoidCallback onDelete;

  /// Reveals or hides the login password.
  final VoidCallback onToggleRevealPassword;

  /// Reveals or hides the card number and security code.
  final VoidCallback onToggleRevealCard;

  /// Reveals or hides the note content.
  final VoidCallback onToggleRevealNote;

  /// Reveals or hides a hidden custom field.
  final void Function(String fieldId) onToggleRevealCustomField;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  /// Copies the password, revealing it first if needed.
  final VoidCallback onCopyPassword;

  /// Copies a custom-field value, revealing hidden values first if needed.
  final void Function(CustomFieldDetailDto field) onCopyCustomField;

  /// Opens a URL shown on the detail screen.
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailBar(
              favorite: detail.favorite,
              isEmbedded: isEmbedded,
              onBack: onBack,
              onFavorite: onFavorite,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
            Expanded(
              child: DetailContent(
                entry: entry,
                detail: detail,
                revealedPassword: revealedPassword,
                revealedCardNumber: revealedCardNumber,
                revealedCvv: revealedCvv,
                revealedNote: revealedNote,
                revealedCustomFields: revealedCustomFields,
                onToggleRevealPassword: onToggleRevealPassword,
                onToggleRevealCard: onToggleRevealCard,
                onToggleRevealNote: onToggleRevealNote,
                onToggleRevealCustomField: onToggleRevealCustomField,
                onCopy: onCopy,
                onCopyPassword: onCopyPassword,
                onCopyCustomField: onCopyCustomField,
                onOpenUrl: onOpenUrl,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isEmbedded
          ? null
          : _DetailEditBar(kind: entry.kind, onPressed: onEdit),
    );
  }
}

/// The edit call-to-action docked below the detail body on narrow layouts.
class _DetailEditBar extends StatelessWidget {
  /// Creates the edit bar.
  const new({required this.kind, required this.onPressed});

  /// Kind of the entry being edited; drives the button copy.
  final VaultEntryKind kind;

  /// Opens the editor.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.md,
          KeyelSpacing.sm,
          KeyelSpacing.md,
          KeyelSpacing.md,
        ),
        child: KeyelPillButton(
          label: switch (kind) {
            VaultEntryKind.card => l10n.entryEditCard,
            VaultEntryKind.note => l10n.entryEditNote,
            VaultEntryKind.login => l10n.entryEditLogin,
            VaultEntryKind.passkey => l10n.entryEditPasskey,
          },
          icon: Icons.edit_rounded,
          tone: KeyelButtonTone.tonal,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
