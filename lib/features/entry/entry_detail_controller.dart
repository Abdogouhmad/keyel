import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_url.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Owns the loading, reveal and mutation logic behind the detail screen.
class EntryDetailController {
  /// Creates a controller for the entry with the given id.
  new({
    required this.entryId,
    required this.repository,
    required this.callbacks,
  });

  /// Identifier of the entry being shown.
  final String entryId;

  /// Vault repository used for all data access.
  final VaultRepository repository;

  /// Screen callbacks for rebuilds and user feedback.
  final EntryDetailCallbacks callbacks;

  EntryDetailDto? _detail;
  VaultEntry? _entry;
  bool _loading = true;
  String? _revealedPassword;
  String? _revealedCardNumber;
  String? _revealedCvv;
  String? _revealedNote;
  Timer? _hideTimer;

  /// Latest loaded detail record, or `null` while missing.
  EntryDetailDto? get detail => _detail;

  /// Presentation model derived from the detail record.
  VaultEntry? get entry => _entry;

  /// Whether the initial load is still in flight.
  bool get loading => _loading;

  /// Revealed login password, or `null` when hidden.
  String? get revealedPassword => _revealedPassword;

  /// Revealed card number, or `null` when hidden.
  String? get revealedCardNumber => _revealedCardNumber;

  /// Revealed card security code, or `null` when hidden.
  String? get revealedCvv => _revealedCvv;

  /// Revealed note content, or `null` when hidden.
  String? get revealedNote => _revealedNote;

  /// Loads the entry from the vault repository.
  Future<void> load() async {
    _loading = true;
    callbacks.rebuild();
    try {
      final record = await repository.getEntry(entryId);
      var folderNames = const <String, String>{};
      try {
        folderNames = {
          for (final folder in await repository.listFolders())
            folder.id: folder.name,
        };
      } on Object catch (_) {
        // Folder lookup is cosmetic; the entry still renders without it.
      }
      _loading = false;
      _detail = record;
      _entry = VaultEntry.fromDetail(record, folderNames: folderNames);
      callbacks.rebuild();
    } on Object catch (error) {
      _loading = false;
      _detail = null;
      _entry = null;
      callbacks.rebuild();
      callbacks.notifyError(error);
    }
  }

  /// Reveals or hides the login password with an auto-hide timer.
  Future<void> toggleRevealPassword() async {
    if (_revealedPassword != null) {
      _revealedPassword = null;
      _hideTimer?.cancel();
      callbacks.rebuild();
      return;
    }

    try {
      final plain = await repository.revealField(
        entryId,
        SecretFieldDto.loginPassword,
      );
      _revealedPassword = plain;
      callbacks.rebuild();
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 15), () {
        _revealedPassword = null;
        callbacks.rebuild();
      });
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Reveals or hides the card number and security code.
  Future<void> toggleRevealCard() async {
    if (_revealedCardNumber != null) {
      _revealedCardNumber = null;
      _revealedCvv = null;
      callbacks.rebuild();
      return;
    }

    try {
      final number = await repository.revealField(
        entryId,
        SecretFieldDto.cardNumber,
      );
      String? cvv;
      try {
        cvv = await repository.revealField(entryId, SecretFieldDto.cardCvv);
      } on Object catch (_) {}

      _revealedCardNumber = number;
      _revealedCvv = cvv;
      callbacks.rebuild();
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Reveals or hides the note content.
  Future<void> toggleRevealNote() async {
    if (_revealedNote != null) {
      _revealedNote = null;
      callbacks.rebuild();
      return;
    }

    try {
      final content = await repository.revealField(
        entryId,
        SecretFieldDto.noteContent,
      );
      _revealedNote = content;
      callbacks.rebuild();
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Copies the password, revealing it first if needed.
  Future<void> copyPassword() async {
    if (_revealedPassword != null) {
      callbacks.copy(
        _revealedPassword!,
        'Password copied${SensitiveClipboard.instance.clearHint}',
      );
      return;
    }

    try {
      final plain = await repository.revealField(
        entryId,
        SecretFieldDto.loginPassword,
      );
      callbacks.copy(
        plain,
        'Password copied${SensitiveClipboard.instance.clearHint}',
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Opens a URL shown on the detail screen in the default external app.
  ///
  /// Bare hosts are upgraded to https first; the user is told when the value
  /// is not a launchable website address or the platform refuses to open it.
  Future<void> openUrl(String rawUrl) async {
    final uri = normalizeEntryUrl(rawUrl);
    if (uri == null) {
      callbacks.notify('Invalid website address', icon: Icons.link_off_rounded);
      return;
    }
    final launched = await callbacks.launchUrl(uri);
    if (!launched) {
      callbacks.notify('Could not open website', icon: Icons.link_off_rounded);
    }
  }

  /// Toggles the entry's favorite flag in the vault.
  Future<void> toggleFavorite() async {
    final detail = _detail;
    if (detail == null) return;

    final newFav = !detail.favorite;
    try {
      await repository.upsertEntry(
        EntryDraft(
          id: detail.id,
          kind: detail.kind,
          title: detail.title,
          tags: detail.tags,
          folderId: detail.folderId,
          favorite: newFav,
          username: detail.login?.username ?? '',
          url: detail.login?.url ?? '',
          totpAlgorithm: detail.login?.totpAlgorithm ?? TotpAlgorithmDto.sha1,
          totpDigits: detail.login?.totpDigits ?? 6,
          totpPeriod: detail.login?.totpPeriod ?? 30,
          cardholder: detail.card?.cardholder ?? '',
          cardExpiry: detail.card?.expiry ?? '',
          cardBrand: detail.card?.brand,
          customFields: [
            for (final f in detail.customFields)
              CustomFieldDraft(
                id: f.id,
                label: f.label,
                kind: f.kind,
                value: f.kind == CustomFieldKindDto.hidden ? null : f.value,
              ),
          ],
        ),
      );
      await load();
      callbacks.notify(
        newFav ? '${detail.title} pinned to favorites' : 'Favorite removed',
        icon: newFav ? Icons.star_rounded : Icons.star_outline_rounded,
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Deletes the entry after explicit user confirmation.
  Future<void> confirmDelete() async {
    final detail = _detail;
    if (detail == null) return;

    final confirmed = await callbacks.confirmDelete(detail.title);
    if (!confirmed) return;
    try {
      await repository.deleteEntry(detail.id);
      callbacks.notify(
        '${detail.title} moved to trash',
        icon: Icons.delete_outline_rounded,
      );
      callbacks.onDeleted?.call();
      callbacks.closeEntry();
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Opens the editor route and reloads the entry when it returns.
  Future<void> openEdit() async {
    final detail = _detail;
    if (detail == null) return;

    await callbacks.pushEdit(detail.id);
    await load();
    callbacks.onEdited?.call();
  }

  /// Cancels the pending auto-hide timer.
  void dispose() {
    _hideTimer?.cancel();
  }
}
