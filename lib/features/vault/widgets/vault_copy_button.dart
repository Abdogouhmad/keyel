import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/primary_secret_copy.dart';
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
    final entry = widget.entry;
    unawaited(Haptics.light());

    // Notes and passkeys have no primary secret: open them for inspection.
    if (entry.kind != VaultEntryKind.login &&
        entry.kind != VaultEntryKind.card) {
      unawaited(context.push(KeyelRoutes.entryDetail(entry.id)));
      return;
    }

    try {
      final result = await PrimarySecretCopy.resolve(
        entry,
        repository: ref.read(vaultRepositoryProvider),
        l10n: l10nOf(context),
      );
      if (!mounted) return;
      if (!result.hasValue) {
        showKeyelSnack(
          context,
          result.message,
          icon: Icons.info_outline_rounded,
        );
        return;
      }
      unawaited(SensitiveClipboard.instance.copy(result.value!));
      showKeyelSnack(context, result.message, icon: Icons.content_copy_rounded);
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
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
