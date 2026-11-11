import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';

/// Human label for an entry kind, used in editor titles.
String editKindLabel(VaultEntryKind kind) => switch (kind) {
  VaultEntryKind.login => 'Login',
  VaultEntryKind.card => 'Card',
  VaultEntryKind.note => 'Note',
};

/// Glyph representing an entry kind, used for the editor avatar.
IconData editKindIcon(VaultEntryKind kind) => switch (kind) {
  VaultEntryKind.login => Icons.shield_rounded,
  VaultEntryKind.card => Icons.credit_card_rounded,
  VaultEntryKind.note => Icons.description_rounded,
};
