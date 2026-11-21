import 'package:flutter/material.dart';
import 'package:keyel/features/generator/widgets/character_rule.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A column of switches for configuring passphrase generation options.
class PassphraseRules extends StatelessWidget {
  /// Creates a passphrase rules widget.
  const new({
    required this.capitalizeFirst,
    required this.includeNumber,
    required this.separator,
    required this.onCapitalizeFirstChanged,
    required this.onIncludeNumberChanged,
    required this.onSeparatorChanged,
    super.key,
  });

  /// Whether to capitalize the first letter of each word.
  final bool capitalizeFirst;

  /// Whether to include a random number at the end of the passphrase.
  final bool includeNumber;

  /// Word separator between passphrase words.
  final String separator;

  /// Callback triggered when the capitalize switch changes.
  final ValueChanged<bool> onCapitalizeFirstChanged;

  /// Callback triggered when the include number switch changes.
  final ValueChanged<bool> onIncludeNumberChanged;

  /// Callback triggered when the separator changes.
  final ValueChanged<String> onSeparatorChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyelSectionLabel(
          label: l10n.genPassphraseOptions,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: 'Aa',
          title: l10n.genCapitalizeFirst,
          subtitle: l10n.genCapitalizeExample,
          switchValue: capitalizeFirst,
          onSwitchChanged: onCapitalizeFirstChanged,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        CharacterRule(
          sample: '12',
          title: l10n.genIncludeNumber,
          subtitle: l10n.genIncludeNumberSubtitle,
          switchValue: includeNumber,
          onSwitchChanged: onIncludeNumberChanged,
        ),
        const SizedBox(height: KeyelSpacing.md),
        KeyelSectionLabel(
          label: l10n.genWordSeparator,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        KeyelSegmentedControl<String>(
          selected: separator,
          onChanged: onSeparatorChanged,
          options: [
            const KeyelSegmentOption(value: '-', label: '-'),
            const KeyelSegmentOption(value: '.', label: '.'),
            const KeyelSegmentOption(value: '_', label: '_'),
            KeyelSegmentOption(value: ' ', label: l10n.genSeparatorSpace),
          ],
        ),
      ],
    );
  }
}
