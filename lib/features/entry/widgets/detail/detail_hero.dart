import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Large avatar, title and folder badges of the entry detail view.
class DetailHero extends StatelessWidget {
  /// Creates the hero header.
  const new({required this.entry, super.key});

  /// Entry being displayed.
  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: KeyelSpacing.sm,
        bottom: KeyelSpacing.md + 4,
      ),
      child: Column(
        children: [
          KeyelAvatar(
            icon: entry.icon,
            tone: entry.avatarTone,
            shape: entry.avatarShape,
            size: 72,
          ),
          const SizedBox(height: KeyelSpacing.md),
          Text(
            entry.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(
              color: scheme.onSurface,
              fontSize: 28,
              height: 36 / 28,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: KeyelSpacing.sm,
            runSpacing: KeyelSpacing.sm,
            children: [
              KeyelBadge(
                label: entry.folder,
                icon: Icons.folder_rounded,
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
              ),
              if (entry.hasTotp)
                KeyelBadge(
                  label: l10nOf(context).entry2FaEnabled,
                  icon: Icons.verified_user_rounded,
                  background: scheme.surfaceContainerHigh,
                  foreground: scheme.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
