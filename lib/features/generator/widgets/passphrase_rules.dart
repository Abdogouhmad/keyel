import 'package:flutter/material.dart';
import 'package:keyel/features/generator/widgets/character_rule.dart';
import 'package:keyel/ui/keyel.dart';

/// A column of switches for configuring passphrase generation options.
class PassphraseRules extends StatelessWidget {
  /// Creates a passphrase rules widget.
  const new({
    required this.capitalizeFirst,
    required this.includeNumber,
    required this.onCapitalizeFirstChanged,
    required this.onIncludeNumberChanged,
    super.key,
  });

  /// Whether to capitalize the first letter of each word.
  final bool capitalizeFirst;

  /// Whether to include a random number at the end of the passphrase.
  final bool includeNumber;

  /// Callback triggered when the capitalize switch changes.
  final ValueChanged<bool> onCapitalizeFirstChanged;

  /// Callback triggered when the include number switch changes.
  final ValueChanged<bool> onIncludeNumberChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyelSectionLabel(
          label: 'Passphrase options',
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: 'Aa',
          title: 'Capitalize first letter',
          subtitle: 'e.g., Apple-Tree-House',
          switchValue: capitalizeFirst,
          onSwitchChanged: onCapitalizeFirstChanged,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: '12',
          title: 'Include a number',
          subtitle: 'Adds two random digits at the end',
          switchValue: includeNumber,
          onSwitchChanged: onIncludeNumberChanged,
        ),
      ],
    );
  }
}
