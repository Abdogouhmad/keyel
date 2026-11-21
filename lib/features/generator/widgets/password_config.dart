import 'package:flutter/material.dart';

import 'package:keyel/features/generator/widgets/config_card.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A configuration card specifically for password length.
class PasswordConfig extends StatelessWidget {
  /// Creates a password configuration card.
  const new({
    required this.length,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  /// The current length of the generated password.
  final int length;

  /// Callback triggered when the length changes.
  final ValueChanged<int> onChanged;

  /// Callback triggered when the user stops interacting with the slider.
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);

    return ConfigCard(
      title: l10n.genPasswordLength,
      subtitle: l10n.genPasswordLengthSubtitle,
      valueLabel: l10n.genLengthValue(length),
      value: length.toDouble(),
      min: 8,
      max: 64,
      divisions: 56,
      trackLabels: [
        l10n.genCharsShort(8),
        l10n.genCharsShort(36),
        l10n.genCharsShort(64),
      ],
      onChanged: (value) => onChanged(value.round()),
      onChangeEnd: onChangeEnd,
    );
  }
}
