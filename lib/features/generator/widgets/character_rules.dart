import 'package:flutter/material.dart';
import 'package:keyel/features/generator/widgets/character_rule.dart';
import 'package:keyel/ui/keyel.dart';

/// A column of character type switches for password generation.
class CharacterRules extends StatelessWidget {
  /// Creates a character rules widget.
  const new({
    required this.includeUppercase,
    required this.includeLowercase,
    required this.includeNumbers,
    required this.includeSymbols,
    required this.excludeAmbiguous,
    required this.onUppercaseChanged,
    required this.onLowercaseChanged,
    required this.onNumbersChanged,
    required this.onSymbolsChanged,
    required this.onExcludeAmbiguousChanged,
    super.key,
  });

  /// Whether to include uppercase letters.
  final bool includeUppercase;

  /// Whether to include lowercase letters.
  final bool includeLowercase;

  /// Whether to include numbers.
  final bool includeNumbers;

  /// Whether to include symbols.
  final bool includeSymbols;

  /// Whether to exclude ambiguous characters.
  final bool excludeAmbiguous;

  /// Callback triggered when the uppercase switch changes.
  final ValueChanged<bool> onUppercaseChanged;

  /// Callback triggered when the lowercase switch changes.
  final ValueChanged<bool> onLowercaseChanged;

  /// Callback triggered when the numbers switch changes.
  final ValueChanged<bool> onNumbersChanged;

  /// Callback triggered when the symbols switch changes.
  final ValueChanged<bool> onSymbolsChanged;

  /// Callback triggered when the exclude ambiguous switch changes.
  final ValueChanged<bool> onExcludeAmbiguousChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyelSectionLabel(
          label: 'Character types',
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: 'AB',
          title: 'Uppercase letters',
          subtitle: 'A-Z',
          switchValue: includeUppercase,
          onSwitchChanged: onUppercaseChanged,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: 'ab',
          title: 'Lowercase letters',
          subtitle: 'a-z',
          switchValue: includeLowercase,
          onSwitchChanged: onLowercaseChanged,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: '09',
          title: 'Numbers',
          subtitle: '0-9',
          switchValue: includeNumbers,
          onSwitchChanged: onNumbersChanged,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: '#@',
          title: 'Symbols',
          subtitle: r'!@#$%^&*',
          switchValue: includeSymbols,
          onSwitchChanged: onSymbolsChanged,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: '0O',
          title: 'Exclude ambiguous',
          subtitle: 'Avoids 0, O, 1, l and I confusion',
          switchValue: excludeAmbiguous,
          onSwitchChanged: onExcludeAmbiguousChanged,
        ),
      ],
    );
  }
}
