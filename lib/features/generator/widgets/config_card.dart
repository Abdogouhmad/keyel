import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';

/// A reusable configuration card containing a slider and labels.
class ConfigCard extends StatelessWidget {
  /// Creates a configuration card.
  const new({
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.trackLabels,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  /// The title of the configuration.
  final String title;

  /// The subtitle describing the configuration.
  final String subtitle;

  /// The current value displayed as a label.
  final String valueLabel;

  /// The current numeric value of the slider.
  final double value;

  /// The minimum value of the slider.
  final double min;

  /// The maximum value of the slider.
  final double max;

  /// The number of discrete divisions on the slider.
  final int divisions;

  /// The labels displayed below the slider track.
  final List<String> trackLabels;

  /// Callback triggered when the slider value changes.
  final ValueChanged<double> onChanged;

  /// Callback triggered when the user stops interacting with the slider.
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
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
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.sm + 4,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(KeyelRadii.pill),
                ),
                child: Text(
                  valueLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.round().toString(),
            onChanged: onChanged,
            onChangeEnd: (_) => onChangeEnd(),
          ),
          Row(
            children: [
              for (var index = 0; index < trackLabels.length; index++) ...[
                if (index > 0) const Spacer(),
                Text(
                  trackLabels[index],
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
