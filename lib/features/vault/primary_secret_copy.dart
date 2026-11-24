import 'package:flutter/foundation.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/l10n/generated/app_localizations.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Which value a row's copy action resolved to.
enum PrimarySecretKind {
  /// A revealed login password.
  password,

  /// A revealed card number.
  cardNumber,

  /// The entry's username (fallback when there is no password).
  username,

  /// Nothing was available to copy.
  none,
}

/// The single source of truth for "copy the primary secret of a row".
///
/// Precedence for logins is **password first, username as fallback**: the row
/// button and the swipe action used to disagree on this. Notes and passkeys
/// have no primary secret and open their detail screen instead. Every secret
/// still goes through [VaultRepository.revealField]; only the resolved value
/// is handed to the clipboard sink, never a masked DTO placeholder.
@immutable
class PrimarySecretCopy {
  /// Creates a resolution result. Callers use [resolve].
  const new({required this.kind, required this.value, required this.message});

  /// What was resolved.
  final PrimarySecretKind kind;

  /// The exact text to copy, or `null` when there is nothing to copy.
  final String? value;

  /// Feedback message for the user, including the clipboard clear hint for
  /// actual secrets.
  final String message;

  /// Whether a clipboard write should follow this resolution.
  bool get hasValue => value != null;

  /// Resolves the primary secret without touching the clipboard.
  ///
  /// Repository failures propagate so each caller can keep its own error UX.
  static Future<PrimarySecretCopy> resolve(
    VaultEntry entry, {
    required VaultRepository repository,
    required AppLocalizations l10n,
  }) async {
    switch (entry.kind) {
      case VaultEntryKind.login:
        final password = await repository.revealField(
          entry.id,
          SecretFieldDto.loginPassword,
        );
        if (password.isNotEmpty) {
          return PrimarySecretCopy(
            kind: PrimarySecretKind.password,
            value: password,
            message:
                '${l10n.vaultCopiedPassword}'
                '${SensitiveClipboard.instance.clearHint}',
          );
        }
        if (entry.username.isNotEmpty) {
          return PrimarySecretCopy(
            kind: PrimarySecretKind.username,
            value: entry.username,
            message: l10n.vaultCopiedUsername,
          );
        }
      case VaultEntryKind.card:
        final number = await repository.revealField(
          entry.id,
          SecretFieldDto.cardNumber,
        );
        if (number.isNotEmpty) {
          return PrimarySecretCopy(
            kind: PrimarySecretKind.cardNumber,
            value: number,
            message:
                '${l10n.vaultCopiedCardNumber}'
                '${SensitiveClipboard.instance.clearHint}',
          );
        }
      case VaultEntryKind.note:
      case VaultEntryKind.passkey:
        break;
    }

    return PrimarySecretCopy(
      kind: PrimarySecretKind.none,
      value: null,
      message: l10n.vaultNothingToCopy,
    );
  }
}
