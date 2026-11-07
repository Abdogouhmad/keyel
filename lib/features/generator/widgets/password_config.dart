import 'package:flutter/material.dart';

import 'package:keyel/features/generator/widgets/config_card.dart';

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
    return ConfigCard(
      title: 'Password length',
      subtitle: 'Recommended 16+ characters',
      valueLabel: '$length characters',
      value: length.toDouble(),
      min: 8,
      max: 64,
      divisions: 56,
      trackLabels: const ['8 chars', '36 chars', '64 chars'],
      onChanged: (value) => onChanged(value.round()),
      onChangeEnd: onChangeEnd,
    );
  }
}
