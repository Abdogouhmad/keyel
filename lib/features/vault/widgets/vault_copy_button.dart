import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Copy button shown on a vault entry row.
/// Copies the primary secret of a vault entry to the clipboard.
class VaultCopyButton extends ConsumerStatefulWidget {
  /// Creates the copy button.
  const new({required this.entry, super.key});

  /// The entry whose primary secret is copied.
  final VaultEntry entry;

  @override
  ConsumerState<VaultCopyButton> createState() => _VaultCopyButtonState();
}

class _VaultCopyButtonState extends ConsumerState<VaultCopyButton> {
  Future<void> _copy() async {
    final entry = widget.entry;
    if (entry.kind == VaultEntryKind.login) {
      if (entry.username.isNotEmpty) {
        unawaited(Clipboard.setData(ClipboardData(text: entry.username)));
        showKeyelSnack(
          context,
          'Username copied to clipboard',
          icon: Icons.content_copy_rounded,
        );
      } else {
        try {
          final pass = await ref
              .read(vaultRepositoryProvider)
              .revealField(entry.id, SecretFieldDto.loginPassword);
          unawaited(Clipboard.setData(ClipboardData(text: pass)));
          if (mounted) {
            showKeyelSnack(
              context,
              'Password copied • Clears in 30s',
              icon: Icons.content_copy_rounded,
            );
          }
        } on Object catch (error) {
          if (mounted) showKeyelSnack(context, describeVaultError(error));
        }
      }
    } else if (entry.kind == VaultEntryKind.card) {
      try {
        final cardNum = await ref
            .read(vaultRepositoryProvider)
            .revealField(entry.id, SecretFieldDto.cardNumber);
        unawaited(Clipboard.setData(ClipboardData(text: cardNum)));
        if (mounted) {
          showKeyelSnack(
            context,
            'Card number copied to clipboard',
            icon: Icons.content_copy_rounded,
          );
        }
      } on Object catch (_) {
        if (mounted) {
          unawaited(context.push(KeyelRoutes.entryDetail(entry.id)));
        }
      }
    } else {
      unawaited(context.push(KeyelRoutes.entryDetail(entry.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return KeyelIconHull(
      icon: Icons.content_copy_rounded,
      tooltip: entry.kind == VaultEntryKind.card
          ? 'Copy card'
          : 'Copy credential',
      onPressed: () => unawaited(_copy()),
    );
  }
}
