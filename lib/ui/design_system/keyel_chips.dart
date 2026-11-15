import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/pressable_scale.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A 40 dp filter pill used for vault categories.
class KeyelFilterChip extends StatelessWidget {
  /// Creates a filter pill.
  const new({
    required this.label,
    required this.selected,
    this.count,
    this.onTap,
    super.key,
  });

  /// Chip copy.
  final String label;

  /// Whether this chip is the active filter.
  final bool selected;

  /// Optional result count shown inside the pill.
  final int? count;

  /// Tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.pill),
      semanticLabel: label,
      child: AnimatedContainer(
        duration: KeyelMotion.resolve(context, KeyelMotion.fast),
        curve: Curves.easeOut,
        height: 40,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? KeyelSpacing.md + 2 : KeyelSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KeyelRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 18, color: foreground),
              const SizedBox(width: KeyelSpacing.xs + 2),
            ],
            Text(
              count == null ? label : '$label ($count)',
              style: textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable option in a [KeyelSegmentedControl].
class KeyelSegmentOption<T> {
  /// Creates a segment option.
  const new({required this.value, required this.label, this.icon});

  /// Value reported when selected.
  final T value;

  /// Segment copy.
  final String label;

  /// Optional leading glyph.
  final IconData? icon;
}

/// A full-pill segmented control with a raised tonal thumb.
class KeyelSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const new({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.background,
    super.key,
  });

  /// Available segments.
  final List<KeyelSegmentOption<T>> options;

  /// The currently selected value.
  final T selected;

  /// Selection handler.
  final ValueChanged<T> onChanged;

  /// Optional container fill.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.xs),
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.pill),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: PressableScale(
                onTap: () => onChanged(option.value),
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
                semanticLabel: option.label,
                child: AnimatedContainer(
                  duration: KeyelMotion.resolve(context, KeyelMotion.fast),
                  curve: Curves.easeOut,
                  height: 40,
                  decoration: BoxDecoration(
                    color: option.value == selected
                        ? scheme.surfaceContainerLowest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                    boxShadow: option.value == selected
                        ? [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (option.icon != null) ...[
                        Icon(
                          option.icon,
                          size: 18,
                          color: option.value == selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: KeyelSpacing.xs + 2),
                      ],
                      Flexible(
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: option.value == selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: option.value == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
