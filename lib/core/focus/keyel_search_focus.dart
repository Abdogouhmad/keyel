import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Focus node for the vault search field.
///
/// Owned by the app-wide provider scope rather than by any one screen so the
/// root shell's Ctrl/Cmd+F action can focus the field without needing a
/// BuildContext from inside the vault tab.
final vaultSearchFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'vault-search');
  ref.onDispose(node.dispose);
  return node;
});

/// Focuses the vault search field for the global find shortcut.
void focusVaultSearch(WidgetRef ref) =>
    ref.read(vaultSearchFocusProvider).requestFocus();
