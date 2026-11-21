import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Shown in the wide vault layout when no entry is selected.
class VaultDetailPlaceholder extends StatelessWidget {
  /// Creates the placeholder view.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KeyelContentWidth.form),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(KeyelRadii.card),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 36,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: KeyelSpacing.md),
              Text(
                l10n.vaultNoItemSelected,
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: KeyelSpacing.xs),
              Text(
                l10n.vaultSelectItemHint,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
