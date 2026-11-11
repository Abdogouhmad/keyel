import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/detail/detail_bar.dart';
import 'package:keyel/features/entry/widgets/detail/detail_content.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

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
    required this.onBack,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleRevealPassword,
    required this.onToggleRevealCard,
    required this.onToggleRevealNote,
    required this.onCopy,
    required this.onCopyPassword,
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

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  /// Copies the password, revealing it first if needed.
  final VoidCallback onCopyPassword;

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
                onToggleRevealPassword: onToggleRevealPassword,
                onToggleRevealCard: onToggleRevealCard,
                onToggleRevealNote: onToggleRevealNote,
                onCopy: onCopy,
                onCopyPassword: onCopyPassword,
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
            VaultEntryKind.card => 'Edit card',
            VaultEntryKind.note => 'Edit note',
            VaultEntryKind.login => 'Edit login',
          },
          icon: Icons.edit_rounded,
          tone: KeyelButtonTone.tonal,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
