import 'package:flutter/material.dart';

import 'package:keyel/features/generator/widgets/config_card.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
    final l10n = l10nOf(context);

    return ConfigCard(
      title: l10n.genWordCount,
      subtitle: l10n.genWordCountSubtitle,
      valueLabel: l10n.genWordCountValue(wordCount),
      value: wordCount.toDouble(),
      min: 4,
      max: 12,
      divisions: 8,
      trackLabels: [
        l10n.genWordCountValue(4),
        l10n.genWordCountValue(8),
        l10n.genWordCountValue(12),
      ],
      onChanged: (value) => onChanged(value.round()),
      onChangeEnd: onChangeEnd,
    );
  }
}
