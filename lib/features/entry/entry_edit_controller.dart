import 'package:flutter/material.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/entry_edit_callbacks.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/generator.dart' as generator_api;
import 'package:keyel/src/rust/api/models.dart';

/// Kind and favorite flags restored from an existing entry.
class LoadedEntry {
  /// Creates the summary.
  const new({
    required this.kind,
    required this.favorite,
    this.folderId,
    this.icon,
    this.customFields = const [],
  });

  /// Entry kind restored from the vault.
  final VaultEntryKind kind;

  /// Favorite flag restored from the vault.
  final bool favorite;

  /// Folder id restored from the vault, if any.
  final String? folderId;

  /// Optional icon key slug restored from the vault.
  final String? icon;

  /// Custom fields restored from the vault, as drafts.
  final List<CustomFieldDraft> customFields;
}

/// Owns the text controllers and persistence behind the entry editor.
class EntryEditController {
  /// Creates an editor controller with fresh text controllers.
  new({
    required this.repository,
    required this.entryId,
    required this.callbacks,
  });

  /// Vault repository used for all data access.
  final VaultRepository repository;

  /// Existing entry id, or `null` for a new entry.
  final String? entryId;

  /// Optional icon slug chosen by the user.
  String? iconKey;

  /// Custom fields preserved/edited for this entry.
  List<CustomFieldDraft> customFields = const [];

  /// Updates the icon key and requests a rebuild.
  void setIconKey(String? key) {
    iconKey = key;
    callbacks.rebuild();
  }

  /// Screen callbacks for rebuilds and user feedback.
  final EntryEditCallbacks callbacks;

  /// Controller for the entry title field.
  final TextEditingController title = TextEditingController();

  /// Controller for the username field.
  final TextEditingController username = TextEditingController();

  /// Controller for the password field.
  final TextEditingController password = TextEditingController();

  /// Controller for the TOTP shared secret (base32 or `otpauth://` URI).
  final TextEditingController totpSecret = TextEditingController();

  /// Whether the loaded entry already had TOTP configured, so clearing the
  /// field can remove it.
  bool _hadTotp = false;

  TotpAlgorithmDto _totpAlgorithm = TotpAlgorithmDto.sha1;
  int _totpDigits = 6;
  int _totpPeriod = 30;

  /// Apply a validated TOTP configuration from the setup dialog.
  void setTotpConfig(TotpConfigDto config) {
    totpSecret.text = config.secret;
    _totpAlgorithm = config.algorithm;
    _totpDigits = config.digits;
    _totpPeriod = config.period;
  }

  /// Controller for the website field.
  final TextEditingController website = TextEditingController();

  /// Controller for the notes field.
  final TextEditingController notes = TextEditingController();

  /// Controller for the card number field.
  final TextEditingController cardNumber = TextEditingController();

  /// Controller for the card expiry field.
  final TextEditingController cardExpiry = TextEditingController();

  /// Controller for the cardholder field.
  final TextEditingController cardholder = TextEditingController();

  /// Loads an existing entry into the text controllers.
  Future<LoadedEntry?> load() async {
    final id = entryId;
    if (id == null) return null;
    try {
      final detail = await repository.getEntry(id);
      title.text = detail.title;

      final kind = switch (detail.kind) {
        EntryKindDto.login => VaultEntryKind.login,
        EntryKindDto.card => VaultEntryKind.card,
        EntryKindDto.note => VaultEntryKind.note,
      };

      if (detail.login != null) {
        username.text = detail.login!.username;
        website.text = detail.login!.url;
        if (detail.login!.hasPassword) {
          try {
            password.text = await repository.revealField(
              id,
              SecretFieldDto.loginPassword,
            );
          } on Object catch (_) {}
        }
        if (detail.login!.totpAlgorithm != null) {
          _hadTotp = true;
          _totpAlgorithm = detail.login!.totpAlgorithm!;
          _totpDigits = detail.login!.totpDigits ?? 6;
          _totpPeriod = detail.login!.totpPeriod ?? 30;
          try {
            totpSecret.text = await repository.revealField(
              id,
              SecretFieldDto.loginTotpSecret,
            );
          } on Object catch (_) {}
        }
      }

      if (detail.card != null) {
        cardholder.text = detail.card!.cardholder;
        cardExpiry.text = detail.card!.expiry;
        if (detail.card!.hasNumber) {
          try {
            cardNumber.text = await repository.revealField(
              id,
              SecretFieldDto.cardNumber,
            );
          } on Object catch (_) {}
        }
      }

      if (detail.hasNotes) {
        try {
          notes.text = await repository.revealField(
            id,
            detail.kind == EntryKindDto.note
                ? SecretFieldDto.noteContent
                : SecretFieldDto.entryNotes,
          );
        } on Object catch (_) {}
      }

      iconKey = detail.icon;
      customFields = [
        for (final f in detail.customFields)
          CustomFieldDraft(
            id: f.id,
            label: f.label,
            kind: f.kind,
            value: f.kind == CustomFieldKindDto.hidden ? null : f.value,
          ),
      ];

      return LoadedEntry(
        kind: kind,
        favorite: detail.favorite,
        folderId: detail.folderId,
        icon: detail.icon,
        customFields: customFields,
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
      return null;
    }
  }

  /// Generates a strong random password; returns null when generation fails.
  String? generatePassword() {
    try {
      return generator_api.generatePassword(
        length: 20,
        lowercase: true,
        uppercase: true,
        digits: true,
        symbols: true,
        excludeAmbiguous: true,
      );
    } on Object catch (_) {
      callbacks.notify(
        'Could not generate a password right now.',
        icon: Icons.error_rounded,
      );
      return null;
    }
  }

  /// The TOTP value to persist: `null` keeps the stored secret, an empty
  /// string removes it, and a non-empty string replaces it.
  String? _totpDraftValue() {
    final value = totpSecret.text.trim();
    if (value.isNotEmpty) return value;
    return _hadTotp ? '' : null;
  }

  /// Builds a draft from the editors and persists it to the vault.
  Future<void> save({
    required VaultEntryKind kind,
    required bool favorite,
    String? folderId,
  }) async {
    final entryTitle = title.text.trim();
    if (entryTitle.isEmpty) {
      callbacks.notify(
        'Give this entry a title first.',
        icon: Icons.error_rounded,
      );
      return;
    }

    final entryKind = switch (kind) {
      VaultEntryKind.login => EntryKindDto.login,
      VaultEntryKind.card => EntryKindDto.card,
      VaultEntryKind.note => EntryKindDto.note,
    };

    final draft = EntryDraft(
      id: entryId,
      kind: entryKind,
      title: entryTitle,
      notes: kind != VaultEntryKind.note && notes.text.isNotEmpty
          ? notes.text
          : null,
      tags: const [],
      folderId: folderId,
      favorite: favorite,
      icon: iconKey,
      username: username.text.trim(),
      password: password.text.isNotEmpty ? password.text : null,
      url: website.text.trim(),
      totpSecret: _totpDraftValue(),
      totpAlgorithm: _totpAlgorithm,
      totpDigits: _totpDigits,
      totpPeriod: _totpPeriod,
      cardholder: cardholder.text.trim(),
      cardNumber: cardNumber.text.isNotEmpty ? cardNumber.text.trim() : null,
      cardExpiry: cardExpiry.text.trim(),
      noteContent: kind == VaultEntryKind.note && notes.text.isNotEmpty
          ? notes.text
          : null,
      customFields: customFields,
    );

    try {
      await repository.upsertEntry(draft);
      callbacks.notify(
        entryId == null ? 'Entry created in vault.' : 'Entry updated.',
      );
      callbacks.close();
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Releases the text controllers.
  void dispose() {
    title.dispose();
    username.dispose();
    password.dispose();
    totpSecret.dispose();
    website.dispose();
    notes.dispose();
    cardNumber.dispose();
    cardExpiry.dispose();
    cardholder.dispose();
  }
}
