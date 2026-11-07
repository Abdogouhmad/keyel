import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A single character rule switch row for the password generator.
class CharacterRule extends StatelessWidget {
  /// Creates a character rule widget.
  const new({
    required this.sample,
    required this.title,
    required this.subtitle,
    required this.switchValue,
    required this.onSwitchChanged,
    super.key,
  });

  /// The sample characters to display in the icon.
  final String sample;

  /// The title of the rule.
  final String title;

  /// The subtitle describing the rule.
  final String subtitle;

  /// The current value of the switch.
  final bool switchValue;

  /// Callback triggered when the switch value changes.
  final ValueChanged<bool> onSwitchChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              sample,
              style: KeyelTheme.mono(
                context,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm),
          Switch(value: switchValue, onChanged: onSwitchChanged),
        ],
      ),
    );
  }
}
