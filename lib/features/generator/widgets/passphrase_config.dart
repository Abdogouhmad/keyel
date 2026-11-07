import 'package:flutter/material.dart';

import 'package:keyel/features/generator/widgets/config_card.dart';

/// A configuration card specifically for passphrase word count.
class PassphraseConfig extends StatelessWidget {
  /// Creates a passphrase configuration card.
  const new({
    required this.wordCount,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  /// The current number of words in the passphrase.
  final int wordCount;

  /// Callback triggered when the word count changes.
  final ValueChanged<int> onChanged;

  /// Callback triggered when the user stops interacting with the slider.
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return ConfigCard(
      title: 'Word count',
      subtitle: 'Each word adds about 10 bits of entropy',
      valueLabel: '$wordCount words',
      value: wordCount.toDouble(),
      min: 4,
      max: 12,
      divisions: 8,
      trackLabels: const ['4 words', '8 words', '12 words'],
      onChanged: (value) => onChanged(value.round()),
      onChangeEnd: onChangeEnd,
    );
  }
}
