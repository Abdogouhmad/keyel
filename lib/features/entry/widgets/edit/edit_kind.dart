import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Human label for an entry kind, used in editor titles.
String editKindLabel(VaultEntryKind kind) => switch (kind) {
  VaultEntryKind.login => currentL10n.entryKindLogin,
  VaultEntryKind.card => currentL10n.entryKindCard,
  VaultEntryKind.note => currentL10n.entryKindNote,
  VaultEntryKind.passkey => currentL10n.entryKindPasskey,
};

/// Glyph representing an entry kind, used for the editor avatar.
IconData editKindIcon(VaultEntryKind kind) => switch (kind) {
  VaultEntryKind.login => Icons.shield_rounded,
  VaultEntryKind.card => Icons.credit_card_rounded,
  VaultEntryKind.note => Icons.description_rounded,
  VaultEntryKind.passkey => Icons.vpn_key_rounded,
};
