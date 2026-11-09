import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/design_system/keyel_avatar.dart';

/// The kind of secret stored in a vault entry.
enum VaultEntryKind {
  /// Username, password and optional TOTP.
  login,

  /// Payment card details.
  card,

  /// A free-form secure note.
  note,
}

/// Presentation model for a vault row.
class VaultEntry {
  /// Creates a vault entry.
  const new({
    required this.id,
    required this.title,
    required this.kind,
    required this.icon,
    this.username = '',
    this.password = '',
    this.website,
    this.folder = 'No folder',
    this.notes,
    this.favorite = false,
    this.hasTotp = false,
    this.totpCode,
    this.avatarTone = KeyelAvatarTone.neutral,
    this.avatarShape = KeyelAvatarShape.squircle,
    this.cardNumber,
    this.cardExpiry,
    this.cardholder,
  });

  /// Build a presentation model from a secret-free summary.
  ///
  /// [folderNames] maps folder ids to display names; unknown ids fall back to
  /// the generic "Folder" label so a raw UUID never leaks into the UI.
  factory fromSummary(
    EntrySummaryDto summary, {
    Map<String, String> folderNames = const {},
  }) {
    final shape = KeyelAvatarShape
        .values[summary.id.hashCode.abs() % KeyelAvatarShape.values.length];
    final tone = KeyelAvatarTone
        .values[summary.title.hashCode.abs() % KeyelAvatarTone.values.length];
    final kind = switch (summary.kind) {
      EntryKindDto.login => VaultEntryKind.login,
      EntryKindDto.card => VaultEntryKind.card,
      EntryKindDto.note => VaultEntryKind.note,
    };
    final icon = switch (summary.kind) {
      EntryKindDto.login => Icons.key_rounded,
      EntryKindDto.card => Icons.credit_card_rounded,
      EntryKindDto.note => Icons.sticky_note_2_rounded,
    };

    return VaultEntry(
      id: summary.id,
      title: summary.title,
      kind: kind,
      icon: icon,
      username: summary.subtitle,
      favorite: summary.favorite,
      hasTotp: summary.hasTotp,
      avatarTone: tone,
      avatarShape: shape,
      folder: _folderLabel(summary.folderId, folderNames),
    );
  }

  /// Build a presentation model from entry detail.
  factory fromDetail(
    EntryDetailDto detail, {
    Map<String, String> folderNames = const {},
  }) {
    final shape = KeyelAvatarShape
        .values[detail.id.hashCode.abs() % KeyelAvatarShape.values.length];
    final tone = KeyelAvatarTone
        .values[detail.title.hashCode.abs() % KeyelAvatarTone.values.length];
    final kind = switch (detail.kind) {
      EntryKindDto.login => VaultEntryKind.login,
      EntryKindDto.card => VaultEntryKind.card,
      EntryKindDto.note => VaultEntryKind.note,
    };
    final icon = switch (detail.kind) {
      EntryKindDto.login => Icons.key_rounded,
      EntryKindDto.card => Icons.credit_card_rounded,
      EntryKindDto.note => Icons.sticky_note_2_rounded,
    };

    return VaultEntry(
      id: detail.id,
      title: detail.title,
      kind: kind,
      icon: icon,
      username: detail.login?.username ?? '',
      website: detail.login?.url,
      folder: _folderLabel(detail.folderId, folderNames),
      notes: detail.hasNotes ? '•' : null,
      favorite: detail.favorite,
      hasTotp: detail.login?.totpDigits != null,
      avatarTone: tone,
      avatarShape: shape,
      cardholder: detail.card?.cardholder,
      cardExpiry: detail.card?.expiry,
      cardNumber: detail.card != null
          ? (detail.card!.hasNumber ? '••••' : '')
          : null,
    );
  }

  /// Stable identifier used by the detail and editor routes.
  final String id;

  /// Service or item name.
  final String title;

  /// Entry kind.
  final VaultEntryKind kind;

  /// Service glyph.
  final IconData icon;

  /// Login account name, empty for cards and notes.
  final String username;

  /// Demo secret, empty for cards and notes.
  final String password;

  /// Optional website shown on the detail screen.
  final String? website;

  /// Folder label shown in badges.
  final String folder;

  /// Optional secure note copy.
  final String? notes;

  /// Whether the entry is pinned to the favourites section.
  final bool favorite;

  /// Whether the entry has a TOTP token.
  final bool hasTotp;

  /// Demo TOTP code.
  final String? totpCode;

  /// Avatar colour family.
  final KeyelAvatarTone avatarTone;

  /// Avatar shape family.
  final KeyelAvatarShape avatarShape;

  /// Masked card number for card entries.
  final String? cardNumber;

  /// Card expiry for card entries.
  final String? cardExpiry;

  /// Cardholder name for card entries.
  final String? cardholder;

  /// Whether the entry has a password secret.
  bool get hasPassword => password.isNotEmpty;

  /// One-line supporting copy for list rows.
  String get subtitle => switch (kind) {
    VaultEntryKind.login => username,
    VaultEntryKind.card => '•••• ${_lastFour()}',
    VaultEntryKind.note => 'Secure note',
  };

  /// Lower-cased haystack used by the vault search field.
  String get searchTerms => [
    title,
    username,
    folder,
    website ?? '',
    notes ?? '',
  ].join(' ').toLowerCase();

  String _lastFour() {
    final digits = (cardNumber ?? '').replaceAll(' ', '');
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }
}

String _folderLabel(String? id, Map<String, String> names) {
  if (id == null) return 'No folder';
  return names[id] ?? 'Folder';
}

/// Active entries cache / empty fallback when unpopulated.
const sampleVaultEntries = <VaultEntry>[];

/// Looks up an entry in [sampleVaultEntries] by id, or returns `null`.
VaultEntry? vaultEntryById(String id) {
  for (final entry in sampleVaultEntries) {
    if (entry.id == id) return entry;
  }
  return null;
}
