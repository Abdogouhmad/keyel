import 'package:flutter/material.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/vault_row.dart' show VaultRow;
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Title and subtitle column shown inside a [VaultRow].
class VaultRowDetails extends StatelessWidget {
  /// Creates the row details column.
  const new({required this.entry, super.key});

  /// The entry whose title and subtitle are displayed.
  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (entry.hasTotp) ...[
              const SizedBox(width: KeyelSpacing.sm),
              KeyelBadge(
                label: l10n.vaultFilterTwoFactor,
                compact: true,
                background: scheme.primaryFixed,
                foreground: scheme.onPrimaryFixed,
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          entry.subtitle.isNotEmpty
              ? entry.subtitle
              : switch (entry.kind) {
                  VaultEntryKind.login => l10n.vaultKindLogin,
                  VaultEntryKind.card => l10n.vaultKindCard,
                  VaultEntryKind.note => l10n.vaultKindNote,
                  VaultEntryKind.passkey => l10n.vaultKindPasskey,
                },
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFamily: entry.kind == VaultEntryKind.login
                ? KeyelTheme.monoFamily
                : null,
          ),
        ),
      ],
    );
  }
}
