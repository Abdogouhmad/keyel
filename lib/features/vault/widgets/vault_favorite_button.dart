import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Star button that toggles the favorite flag of a vault entry.
class VaultFavoriteButton extends ConsumerStatefulWidget {
  /// Creates the favorite button.
  const new({required this.entry, required this.onRefresh, super.key});

  /// The entry whose favorite flag is toggled.
  final VaultEntry entry;

  /// Called after the flag was persisted so the list can reload.
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<VaultFavoriteButton> createState() =>
      _VaultFavoriteButtonState();
}

class _VaultFavoriteButtonState extends ConsumerState<VaultFavoriteButton> {
  Future<void> _toggle() async {
    final entry = widget.entry;
    try {
      final repo = ref.read(vaultRepositoryProvider);
      final detail = await repo.getEntry(entry.id);
      final newFav = !entry.favorite;

      await repo.upsertEntry(
        EntryDraft(
          id: detail.id,
          kind: detail.kind,
          title: detail.title,
          tags: detail.tags,
          folderId: detail.folderId,
          favorite: newFav,
          username: detail.login?.username ?? '',
          url: detail.login?.url ?? '',
          totpAlgorithm: detail.login?.totpAlgorithm ?? TotpAlgorithmDto.sha1,
          totpDigits: detail.login?.totpDigits ?? 6,
          totpPeriod: detail.login?.totpPeriod ?? 30,
          cardholder: detail.card?.cardholder ?? '',
          cardExpiry: detail.card?.expiry ?? '',
          cardBrand: detail.card?.brand,
          customFields: [
            for (final f in detail.customFields)
              CustomFieldDraft(
                id: f.id,
                label: f.label,
                kind: f.kind,
                value: f.kind == CustomFieldKindDto.hidden ? null : f.value,
              ),
          ],
        ),
      );

      await widget.onRefresh();
      if (!mounted) return;
      final l10n = l10nOf(context);
      showKeyelSnack(
        context,
        newFav
            ? l10n.vaultEntryPinnedToFavorites(entry.title)
            : l10n.vaultEntryRemovedFromFavorites(entry.title),
        icon: newFav ? Icons.star_rounded : Icons.star_outline_rounded,
      );
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final favorite = widget.entry.favorite;

    return KeyelIconHull(
      icon: favorite ? Icons.star_rounded : Icons.star_outline_rounded,
      tooltip: favorite
          ? l10n.vaultRemoveFromFavorites
          : l10n.vaultAddToFavorites,
      onPressed: () => unawaited(_toggle()),
      foreground: favorite ? scheme.primary : scheme.outline,
    );
  }
}
