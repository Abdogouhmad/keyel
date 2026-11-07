import 'package:flutter/material.dart';
import 'package:keyel/features/generator/widgets/secret_display.dart';
import 'package:keyel/ui/keyel.dart';

/// A card displaying the generated secret with copy and regenerate actions.
class GeneratorResultCard extends StatelessWidget {
  /// Creates a generator result card.
  const new({
    required this.value,
    required this.modeName,
    required this.onRegenerate,
    required this.onCopy,
    super.key,
  });

  /// The generated secret text.
  final String value;

  /// The name of the generation mode (e.g., 'Password' or 'Passphrase').
  final String modeName;

  /// Callback triggered when the regenerate button is pressed.
  final VoidCallback onRegenerate;

  /// Callback triggered when the copy button is pressed.
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.lg - 4),
      decoration: BoxDecoration(
        color: isLight
            ? scheme.secondaryFixed.withValues(alpha: 0.55)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KeyelSpacing.sm + 4,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 15, color: scheme.primary),
                  const SizedBox(width: KeyelSpacing.xs + 2),
                  Text(
                    'Generated locally on device',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          SecretDisplay(
            value: value,
            textKey: const ValueKey('generatorSecret'),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Row(
            children: [
              KeyelIconHull(
                icon: Icons.refresh_rounded,
                tooltip: 'Regenerate',
                onPressed: onRegenerate,
                background: scheme.surfaceContainerLowest,
                foreground: scheme.primary,
              ),
              const SizedBox(width: KeyelSpacing.sm + 4),
              Expanded(
                child: KeyelPillButton(
                  label: 'Copy $modeName',
                  icon: Icons.content_copy_rounded,
                  height: 48,
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
