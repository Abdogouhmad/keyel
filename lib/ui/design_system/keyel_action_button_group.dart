import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/pressable_scale.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// The action row under an entry name on the detail screen:
/// reveal/copy/paste style pills, wrapping on narrow panes.
class KeyelActionButtonGroup extends StatelessWidget {
  /// Creates an action group.
  const new({
    required this.actions,
    this.alignment = WrapAlignment.start,
    super.key,
  });

  /// The actions, in logical order.
  final List<KeyelActionSpec> actions;

  /// Layout alignment when the row wraps.
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: KeyelSpacing.sm,
      runSpacing: KeyelSpacing.sm,
      children: [for (final action in actions) _ActionButton(spec: action)],
    );
  }
}

/// One action in a [KeyelActionButtonGroup].
final class KeyelActionSpec {
  /// Creates an action spec.
  const new({required this.label, required this.icon, this.onPressed});

  /// Button copy.
  final String label;

  /// Leading glyph.
  final IconData icon;

  /// Handler (null disables the pill).
  final VoidCallback? onPressed;
}

class _ActionButton extends StatelessWidget {
  const new({required this.spec});

  final KeyelActionSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = spec.onPressed != null;

    return PressableScale(
      onTap: spec.onPressed,
      borderRadius: BorderRadius.circular(KeyelRadii.pill),
      semanticLabel: spec.label,
      child: AnimatedContainer(
        duration: KeyelMotion.resolve(context, KeyelMotion.fast),
        curve: Curves.easeOut,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KeyelRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spec.icon,
              size: 18,
              color: enabled
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.38),
            ),
            const SizedBox(width: KeyelSpacing.xs),
            Text(
              spec.label,
              style: textTheme.labelLarge?.copyWith(
                color: enabled
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
