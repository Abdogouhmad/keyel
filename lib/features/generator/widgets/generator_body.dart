import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/generator/widgets/character_rules.dart';
import 'package:keyel/features/generator/widgets/generator_result_card.dart';
import 'package:keyel/features/generator/widgets/passphrase_config.dart';
import 'package:keyel/features/generator/widgets/passphrase_rules.dart';
import 'package:keyel/features/generator/widgets/passphrase_tip.dart';
import 'package:keyel/features/generator/widgets/password_config.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Mode of generation: password or passphrase.
enum GeneratorMode {
  /// Random character password.
  password,

  /// Word-based passphrase.
  passphrase,
}

/// Scrollable generator configuration and result body.
class GeneratorBody extends StatelessWidget {
  /// Creates the generator body.
  const new({
    required this.mode,
    required this.onModeChanged,
    required this.display,
    required this.modeName,
    required this.strength,
    required this.onRegenerate,
    required this.onCopy,
    required this.length,
    required this.onLengthChanged,
    required this.onLengthChangeEnd,
    required this.wordCount,
    required this.onWordCountChanged,
    required this.onWordCountChangeEnd,
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
    required this.capitalizeFirst,
    required this.includeNumber,
    required this.separator,
    required this.onCapitalizeFirstChanged,
    required this.onIncludeNumberChanged,
    required this.onSeparatorChanged,
    super.key,
  });

  /// Selected generation mode.
  final GeneratorMode mode;

  /// Called when the mode changes.
  final ValueChanged<GeneratorMode> onModeChanged;

  /// Current generated secret to display.
  final String display;

  /// Human-readable mode name.
  final String modeName;

  /// Strength estimate for the current secret/settings.
  final PasswordStrength strength;

  /// Regenerates the current secret.
  final VoidCallback onRegenerate;

  /// Copies the current secret.
  final VoidCallback onCopy;

  /// Password length.
  final int length;

  /// Updates password length.
  final ValueChanged<int> onLengthChanged;

  /// Finalizes password length changes.
  final VoidCallback onLengthChangeEnd;

  /// Passphrase word count.
  final int wordCount;

  /// Updates passphrase word count.
  final ValueChanged<int> onWordCountChanged;

  /// Finalizes word-count changes.
  final VoidCallback onWordCountChangeEnd;

  /// Whether uppercase letters are included.
  final bool includeUppercase;

  /// Whether lowercase letters are included.
  final bool includeLowercase;

  /// Whether digits are included.
  final bool includeNumbers;

  /// Whether symbols are included.
  final bool includeSymbols;

  /// Whether ambiguous characters are excluded.
  final bool excludeAmbiguous;

  /// Updates uppercase inclusion.
  final ValueChanged<bool> onUppercaseChanged;

  /// Updates lowercase inclusion.
  final ValueChanged<bool> onLowercaseChanged;

  /// Updates digit inclusion.
  final ValueChanged<bool> onNumbersChanged;

  /// Updates symbol inclusion.
  final ValueChanged<bool> onSymbolsChanged;

  /// Updates ambiguous-character exclusion.
  final ValueChanged<bool> onExcludeAmbiguousChanged;

  /// Whether passphrase words are capitalized.
  final bool capitalizeFirst;

  /// Whether a number is appended to passphrases.
  final bool includeNumber;

  /// Separator between passphrase words.
  final String separator;

  /// Updates capitalization option.
  final ValueChanged<bool> onCapitalizeFirstChanged;

  /// Updates number-inclusion option.
  final ValueChanged<bool> onIncludeNumberChanged;

  /// Updates passphrase separator.
  final ValueChanged<String> onSeparatorChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);

    return Expanded(
      child: KeyelContent(
        maxWidth: context.supportsTwoColumns
            ? KeyelContentWidth.page
            : KeyelContentWidth.form,
        child: KeyelResponsiveColumns(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.pageMargin,
            KeyelSpacing.xs,
            context.pageMargin,
            KeyelSpacing.xl,
          ),
          leading: [
            KeyelSegmentedControl<GeneratorMode>(
              selected: mode,
              onChanged: onModeChanged,
              options: [
                KeyelSegmentOption(
                  value: GeneratorMode.password,
                  label: l10n.genPassword,
                ),
                KeyelSegmentOption(
                  value: GeneratorMode.passphrase,
                  label: l10n.genPassphrase,
                ),
              ],
            ),
            const SizedBox(height: KeyelSpacing.lg),
            GeneratorResultCard(
              value: display,
              modeName: modeName,
              onRegenerate: onRegenerate,
              onCopy: onCopy,
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelStrengthMeter(strength: strength),
            const SizedBox(height: KeyelSpacing.lg),
          ],
          trailing: [
            if (mode == GeneratorMode.password)
              PasswordConfig(
                length: length,
                onChanged: onLengthChanged,
                onChangeEnd: onLengthChangeEnd,
              )
            else
              PassphraseConfig(
                wordCount: wordCount,
                onChanged: onWordCountChanged,
                onChangeEnd: onWordCountChangeEnd,
              ),
            const SizedBox(height: KeyelSpacing.lg),
            if (mode == GeneratorMode.password)
              CharacterRules(
                includeUppercase: includeUppercase,
                includeLowercase: includeLowercase,
                includeNumbers: includeNumbers,
                includeSymbols: includeSymbols,
                excludeAmbiguous: excludeAmbiguous,
                onUppercaseChanged: onUppercaseChanged,
                onLowercaseChanged: onLowercaseChanged,
                onNumbersChanged: onNumbersChanged,
                onSymbolsChanged: onSymbolsChanged,
                onExcludeAmbiguousChanged: onExcludeAmbiguousChanged,
              )
            else
              Column(
                children: [
                  PassphraseRules(
                    capitalizeFirst: capitalizeFirst,
                    includeNumber: includeNumber,
                    separator: separator,
                    onCapitalizeFirstChanged: onCapitalizeFirstChanged,
                    onIncludeNumberChanged: onIncludeNumberChanged,
                    onSeparatorChanged: onSeparatorChanged,
                  ),
                  const SizedBox(height: KeyelSpacing.lg),
                  const PassphraseTip(),
                ],
              ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: mode == GeneratorMode.password
                  ? l10n.genUsePassword
                  : l10n.genUsePassphrase,
              icon: Icons.check_rounded,
              onPressed: onCopy,
            ),
            const SizedBox(height: KeyelSpacing.lg),
          ],
        ),
      ),
    );
  }
}
