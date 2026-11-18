import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Selectable color palette tile used on the appearance screen.
class AppearancePaletteTile extends StatelessWidget {
  /// Creates a palette tile.
  const new({
    required this.palette,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Palette represented by this tile.
  final KeyelPalette palette;

  /// Whether this palette is currently selected.
  final bool selected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final swatchScheme = Theme.of(context).brightness == Brightness.dark
        ? palette.darkScheme()
        : palette.lightScheme();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.sm,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KeyelRadii.field),
                gradient: LinearGradient(
                  colors: [swatchScheme.primary, swatchScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: KeyelSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    palette.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
