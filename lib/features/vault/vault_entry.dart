import 'package:flutter/material.dart';

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
///
/// The encrypted storage layer is not wired yet, so these entries are local
/// demo data — they keep the redesigned surfaces honest while the Rust vault
/// lands. Every value here is fictional.
class VaultEntry {
  /// Creates a demo vault entry.
  const new({
    required this.id,
    required this.title,
    required this.kind,
    required this.icon,
    this.username = '',
    this.password = '',
    this.website,
    this.folder = 'Personal',
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

/// The fictional vault shown until encrypted storage lands.
const sampleVaultEntries = <VaultEntry>[
  VaultEntry(
    id: 'github',
    title: 'GitHub',
    kind: VaultEntryKind.login,
    icon: Icons.code_rounded,
    username: 'alex.dev@hey.com',
    password: 'ghp_K92jMxV84Lqz99!',
    website: 'github.com',
    folder: 'Work / Development',
    favorite: true,
    hasTotp: true,
    totpCode: '749204',
    avatarTone: KeyelAvatarTone.indigo,
    avatarShape: KeyelAvatarShape.cookie,
    notes: 'SSH recovery codes backed up in local vault note #04.',
  ),
  VaultEntry(
    id: 'protonmail',
    title: 'ProtonMail',
    kind: VaultEntryKind.login,
    icon: Icons.mail_rounded,
    username: 'alex@proton.me',
    password: 'pr0ton!Mail#2026',
    website: 'proton.me',
    favorite: true,
    avatarTone: KeyelAvatarTone.plum,
    notes: 'Recovery phrase stored offline in the safe.',
  ),
  VaultEntry(
    id: 'amazon',
    title: 'Amazon',
    kind: VaultEntryKind.login,
    icon: Icons.shopping_cart_rounded,
    username: 'alex.shopping',
    password: r'Amzn$hop#7721',
    website: 'amazon.com',
    folder: 'Shopping',
  ),
  VaultEntry(
    id: 'apple-id',
    title: 'Apple ID',
    kind: VaultEntryKind.login,
    icon: Icons.cloud_rounded,
    username: 'alex.cloud@icloud.com',
    password: r'App1e!Cloud$88',
    website: 'appleid.apple.com',
    notes: 'Trusted device: Pixel 8 Pro.',
  ),
  VaultEntry(
    id: 'chase-sapphire',
    title: 'Chase Sapphire',
    kind: VaultEntryKind.card,
    icon: Icons.credit_card_rounded,
    folder: 'Finance',
    cardNumber: '4532 8811 9024 1176',
    cardExpiry: '08/29',
    cardholder: 'Alex Morgan',
    avatarTone: KeyelAvatarTone.indigo,
    notes: 'Travel card. Fraud alerts are enabled.',
  ),
  VaultEntry(
    id: 'figma',
    title: 'Figma',
    kind: VaultEntryKind.login,
    icon: Icons.design_services_rounded,
    username: 'alex.design',
    password: 'F1gma@Design!7',
    website: 'figma.com',
    folder: 'Work / Development',
    avatarTone: KeyelAvatarTone.plum,
    avatarShape: KeyelAvatarShape.cookie,
  ),
  VaultEntry(
    id: 'google-workspace',
    title: 'Google Workspace',
    kind: VaultEntryKind.login,
    icon: Icons.work_rounded,
    username: 'work@keyel.org',
    password: r'gW0rk$pace!26',
    website: 'workspace.google.com',
    folder: 'Work / Development',
    hasTotp: true,
    totpCode: '318557',
    avatarTone: KeyelAvatarTone.slate,
  ),
  VaultEntry(
    id: 'passport',
    title: 'Passport',
    kind: VaultEntryKind.note,
    icon: Icons.badge_rounded,
    folder: 'Identity',
    notes:
        'Passport number and renewal date are stored in the fireproof '
        'document folder. Renewal reminder set for March 2028.',
    avatarTone: KeyelAvatarTone.indigo,
    avatarShape: KeyelAvatarShape.cookie,
  ),
  VaultEntry(
    id: 'recovery-codes',
    title: 'Recovery codes',
    kind: VaultEntryKind.note,
    icon: Icons.description_rounded,
    folder: 'Work / Development',
    notes:
        'Single-use backup codes for the work identity provider. '
        'Printed copy is in the office safe.',
  ),
  VaultEntry(
    id: 'spotify',
    title: 'Spotify',
    kind: VaultEntryKind.login,
    icon: Icons.music_note_rounded,
    username: 'music_lover',
    password: 'Mus1c!L0ver#9',
    website: 'spotify.com',
  ),
];

/// Looks up a demo entry by id, or returns `null` when it does not exist.
VaultEntry? vaultEntryById(String id) {
  for (final entry in sampleVaultEntries) {
    if (entry.id == id) return entry;
  }
  return null;
}
