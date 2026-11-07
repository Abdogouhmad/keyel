import 'package:flutter/material.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Displays a secret with syntax highlighting for digits and symbols.
class SecretDisplay extends StatelessWidget {
  /// Creates a secret display.
  const new({required this.value, required this.textKey, super.key});

  /// The secret text to display.
  final String value;

  /// Key for testing/identification of the text widget.
  final Key textKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spans = <TextSpan>[];

    for (final character in value.split('')) {
      final isDigit = RegExp('[0-9]').hasMatch(character);
      final isSymbol = RegExp('[^A-Za-z0-9]').hasMatch(character);

      final color = isDigit
          ? scheme.primary
          : isSymbol
          ? scheme.tertiary
          : scheme.onSurface;

      spans.add(
        TextSpan(
          text: character,
          style: TextStyle(
            color: color,
            fontWeight: isDigit || isSymbol ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text.rich(
          TextSpan(children: spans),
          key: textKey,
          textAlign: TextAlign.center,
          style: KeyelTheme.mono(
            context,
            fontSize: 26,
            height: 1.35,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
