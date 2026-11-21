import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
    final l10n = l10nOf(context);
    final entry = widget.entry;
    unawaited(Haptics.light());
    if (entry.kind == VaultEntryKind.login) {
      if (entry.username.isNotEmpty) {
        unawaited(SensitiveClipboard.instance.copy(entry.username));
        showKeyelSnack(
          context,
          l10n.vaultCopiedUsername,
          icon: Icons.content_copy_rounded,
        );
      } else {
        try {
          final pass = await ref
              .read(vaultRepositoryProvider)
              .revealField(entry.id, SecretFieldDto.loginPassword);
          if (!mounted) return;
          if (pass.isEmpty) {
            showKeyelSnack(
              context,
              l10n.vaultNothingToCopy,
              icon: Icons.info_outline_rounded,
            );
            return;
          }
          unawaited(SensitiveClipboard.instance.copy(pass));
          showKeyelSnack(
            context,
            '${l10n.vaultCopiedPassword}'
            '${SensitiveClipboard.instance.clearHint}',
            icon: Icons.content_copy_rounded,
          );
        } on Object catch (error) {
          if (mounted) showKeyelSnack(context, describeVaultError(error));
        }
      }
    } else if (entry.kind == VaultEntryKind.card) {
      try {
        final cardNum = await ref
            .read(vaultRepositoryProvider)
            .revealField(entry.id, SecretFieldDto.cardNumber);
        if (!mounted) return;
        if (cardNum.isEmpty) {
          showKeyelSnack(
            context,
            l10n.vaultNothingToCopy,
            icon: Icons.info_outline_rounded,
          );
          return;
        }
        unawaited(SensitiveClipboard.instance.copy(cardNum));
        showKeyelSnack(
          context,
          l10n.vaultCopiedCardNumber,
          icon: Icons.content_copy_rounded,
        );
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
    final l10n = l10nOf(context);

    return KeyelIconHull(
      icon: Icons.content_copy_rounded,
      tooltip: switch (entry.kind) {
        VaultEntryKind.card => l10n.vaultCopyCard,
        VaultEntryKind.login => l10n.vaultCopyCredential,
        VaultEntryKind.note => l10n.vaultViewNote,
        VaultEntryKind.passkey => l10n.vaultViewPasskey,
      },
      onPressed: () => unawaited(_copy()),
    );
  }
}
