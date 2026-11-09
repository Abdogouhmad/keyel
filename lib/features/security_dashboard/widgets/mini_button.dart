import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Compact pill-shaped action button with a trailing chevron.
class MiniButton extends StatelessWidget {
  /// Creates a mini button.
  const new({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    super.key,
  });

  /// Text shown inside the pill.
  final String label;

  /// Fill color of the pill.
  final Color background;

  /// Color of the label and chevron icon.
  final Color foreground;

  /// Invoked when the button is pressed.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.pill),
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(KeyelRadii.pill),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelWidget = Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            );

            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // In a constrained card the label may ellipsize; in the
                // audit row the button is a non-flex child of a Row and gets
                // unbounded width, where Flexible would assert.
                if (constraints.hasBoundedWidth)
                  Flexible(child: labelWidget)
                else
                  labelWidget,
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: foreground),
              ],
            );
          },
        ),
      ),
    );
  }
}
