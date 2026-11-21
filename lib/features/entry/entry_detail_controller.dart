import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart' show describeVaultError;
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_url.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/error.dart';
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
  bool _missing = false;
  String? _loadError;
  String? _revealedPassword;
  String? _revealedCardNumber;
  String? _revealedCvv;
  String? _revealedNote;
  final Map<String, String> _revealedCustomFields = <String, String>{};
  Timer? _hideTimer;
  final Map<String, Timer> _customFieldHideTimers = <String, Timer>{};

  /// Latest loaded detail record, or `null` while missing.
  EntryDetailDto? get detail => _detail;

  /// Presentation model derived from the detail record.
  VaultEntry? get entry => _entry;

  /// Whether the initial load is still in flight.
  bool get loading => _loading;

  /// Whether the repository proved that this entry id does not exist.
  ///
  /// Kept distinct from [loadError]: a failed read is not a missing entry.
  bool get missing => _missing;

  /// Human-readable message for a failed load, or `null` on success.
  String? get loadError => _loadError;

  /// Revealed login password, or `null` when hidden.
  String? get revealedPassword => _revealedPassword;

  /// Revealed card number, or `null` when hidden.
  String? get revealedCardNumber => _revealedCardNumber;

  /// Revealed card security code, or `null` when hidden.
  String? get revealedCvv => _revealedCvv;

  /// Revealed note content, or `null` when hidden.
  String? get revealedNote => _revealedNote;

  /// Revealed hidden custom-field values keyed by custom-field id.
  Map<String, String> get revealedCustomFields => _revealedCustomFields;

  /// Loads the entry from the vault repository.
  Future<void> load() async {
    _loading = true;
    _missing = false;
    _loadError = null;
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
      if (error == VaultApiError.notFound) {
        _missing = true;
      } else {
        // The inline retry message is the feedback; a snack would fire before
        // the error state has a Scaffold to present it in.
        _loadError = describeVaultError(error);
      }
      callbacks.rebuild();
    }
  }

  /// How long any revealed secret stays on screen.
  static const revealDuration = Duration(seconds: 15);

  /// Schedules (or refreshes) the single timer that hides all plain-text
  /// reveals. Card, CVV and note values are just as sensitive as passwords and
  /// must not be the exception.
  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(revealDuration, () {
      _hideTimer = null;
      _revealedPassword = null;
      _revealedCardNumber = null;
      _revealedCvv = null;
      _revealedNote = null;
      callbacks.rebuild();
    });
  }

  void _cancelHideIfEmpty() {
    if (_revealedPassword == null &&
        _revealedCardNumber == null &&
        _revealedCvv == null &&
        _revealedNote == null) {
      _hideTimer?.cancel();
      _hideTimer = null;
    }
  }

  /// Immediately hides every revealed secret. Called on lock/background.
  void hideAll() {
    final hadReveals =
        _revealedPassword != null ||
        _revealedCardNumber != null ||
        _revealedCvv != null ||
        _revealedNote != null ||
        _revealedCustomFields.isNotEmpty;
    _hideTimer?.cancel();
    _hideTimer = null;
    for (final timer in _customFieldHideTimers.values) {
      timer.cancel();
    }
    _customFieldHideTimers.clear();
    _revealedPassword = null;
    _revealedCardNumber = null;
    _revealedCvv = null;
    _revealedNote = null;
    _revealedCustomFields.clear();
    if (hadReveals) callbacks.rebuild();
  }

  /// Reveals or hides the login password with an auto-hide timer.
  Future<void> toggleRevealPassword() async {
    if (_revealedPassword != null) {
      _revealedPassword = null;
      _cancelHideIfEmpty();
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
      _scheduleHide();
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Reveals or hides the card number and security code.
  Future<void> toggleRevealCard() async {
    if (_revealedCardNumber != null) {
      _revealedCardNumber = null;
      _revealedCvv = null;
      _cancelHideIfEmpty();
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
      _scheduleHide();
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Reveals or hides the note content.
  Future<void> toggleRevealNote() async {
    if (_revealedNote != null) {
      _revealedNote = null;
      _cancelHideIfEmpty();
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
      _scheduleHide();
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

  /// Reveals or hides a hidden custom field with an auto-hide timer.
  Future<void> toggleRevealCustomField(String fieldId) async {
    if (_revealedCustomFields.containsKey(fieldId)) {
      _revealedCustomFields.remove(fieldId);
      _customFieldHideTimers.remove(fieldId)?.cancel();
      callbacks.rebuild();
      return;
    }

    try {
      final plain = await repository.revealCustomField(entryId, fieldId);
      _revealedCustomFields[fieldId] = plain;
      callbacks.rebuild();
      _customFieldHideTimers.remove(fieldId)?.cancel();
      _customFieldHideTimers[fieldId] = Timer(revealDuration, () {
        _revealedCustomFields.remove(fieldId);
        _customFieldHideTimers.remove(fieldId);
        callbacks.rebuild();
      });
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Copies a custom-field value, revealing hidden values first if needed.
  Future<void> copyCustomField(CustomFieldDetailDto field) async {
    if (field.kind == CustomFieldKindDto.hidden) {
      final revealed = _revealedCustomFields[field.id];
      if (revealed != null) {
        callbacks.copy(
          revealed,
          '${_customFieldLabel(field)} copied${SensitiveClipboard.instance.clearHint}',
        );
        return;
      }
      try {
        final plain = await repository.revealCustomField(entryId, field.id);
        callbacks.copy(
          plain,
          '${_customFieldLabel(field)} copied${SensitiveClipboard.instance.clearHint}',
        );
      } on Object catch (error) {
        callbacks.notifyError(error);
      }
      return;
    }

    callbacks.copy(field.value, '${_customFieldLabel(field)} copied');
  }

  String _customFieldLabel(CustomFieldDetailDto field) {
    final label = field.label.trim();
    return label.isEmpty ? 'Field' : label;
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
      // The repository owns the "flip one flag without touching secrets"
      // reconstruction; duplicating it here risks dropping a secret field.
      await repository.setFavorite(detail.id, favorite: newFav);
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

  /// Cancels pending auto-hide timers.
  void dispose() {
    _hideTimer?.cancel();
    for (final timer in _customFieldHideTimers.values) {
      timer.cancel();
    }
    _customFieldHideTimers.clear();
  }
}
