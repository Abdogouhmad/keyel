import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/detail/card_details.dart';
import 'package:keyel/features/entry/widgets/detail/credentials_card.dart';
import 'package:keyel/features/entry/widgets/detail/custom_fields_card.dart';
import 'package:keyel/features/entry/widgets/detail/detail_hero.dart';
import 'package:keyel/features/entry/widgets/detail/health_card.dart';
import 'package:keyel/features/entry/widgets/detail/note_details.dart';
import 'package:keyel/features/entry/widgets/detail/notes_card.dart';
import 'package:keyel/features/entry/widgets/detail/totp_card.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Scrollable detail body: hero, kind-specific blocks and health cards.
class DetailContent extends StatelessWidget {
  /// Creates the detail body.
  const new({
    required this.entry,
    required this.detail,
    required this.revealedPassword,
    required this.revealedCardNumber,
    required this.revealedCvv,
    required this.revealedNote,
    required this.revealedCustomFields,
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
    return KeyelContent(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.pageMargin,
          0,
          context.pageMargin,
          KeyelSpacing.lg,
        ),
        children: [
          DetailHero(entry: entry),
          if (entry.kind == VaultEntryKind.card)
            CardDetails(
              entry: entry,
              detail: detail,
              revealedNumber: revealedCardNumber,
              revealedCvv: revealedCvv,
              onToggleReveal: onToggleRevealCard,
              onCopy: onCopy,
            )
          else if (entry.kind == VaultEntryKind.login)
            CredentialsCard(
              entry: entry,
              detail: detail,
              revealedPassword: revealedPassword,
              onToggleReveal: onToggleRevealPassword,
              onCopy: onCopy,
              onCopyPassword: onCopyPassword,
              onOpenUrl: onOpenUrl,
            )
          else
            NoteDetails(
              entry: entry,
              detail: detail,
              revealedContent: revealedNote,
              onToggleReveal: onToggleRevealNote,
              onCopy: onCopy,
            ),
          if (entry.kind == VaultEntryKind.login &&
              detail.login?.totpAlgorithm != null) ...[
            const SizedBox(height: KeyelSpacing.md),
            EntryTotpCard(
              entryId: detail.id,
              period: detail.login?.totpPeriod ?? 30,
              onCopy: onCopy,
            ),
          ],
          if (detail.customFields.isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.md),
            CustomFieldsCard(
              fields: detail.customFields,
              revealedValues: revealedCustomFields,
              onToggleReveal: onToggleRevealCustomField,
              onCopyField: onCopyCustomField,
              onOpenUrl: onOpenUrl,
            ),
          ],
          const SizedBox(height: KeyelSpacing.md),
          HealthCard(entry: entry, revealedPassword: revealedPassword),
          if (detail.hasNotes) ...[
            const SizedBox(height: KeyelSpacing.md),
            NotesCard(entryId: detail.id, onCopy: onCopy),
          ],
          const SizedBox(height: KeyelSpacing.lg),
        ],
      ),
    );
  }
}
