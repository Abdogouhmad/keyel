import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/ui/theme/keyel_colors.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

void main() {
  group('KeyelTheme', () {
    test('light theme matches the static brand palette', () {
      final scheme = KeyelTheme.light().colorScheme;
      expect(scheme.primary, const Color(0xFF293CA0));
      expect(scheme.primaryContainer, const Color(0xFF4355B9));
      expect(scheme.secondaryContainer, const Color(0xFFDCDEF7));
      expect(scheme.onSecondaryContainer, const Color(0xFF5E6177));
      expect(
        scheme.tertiaryContainer,
        const Color(0xFF76546E),
        reason: 'tertiary-container must match the Stitch light spec',
      );
      expect(scheme.surface, const Color(0xFFFBF8FF));
      expect(scheme.surfaceContainerHigh, const Color(0xFFEAE7EE));
    });

    test('dark theme matches the static brand palette', () {
      final scheme = KeyelTheme.dark().colorScheme;
      expect(scheme.primary, const Color(0xFFBAC3FF));
      expect(scheme.primaryContainer, const Color(0xFF293CA0));
      expect(scheme.secondaryContainer, const Color(0xFF424559));
      expect(
        scheme.tertiaryContainer,
        const Color(0xFF5D3D56),
        reason: 'tertiary-container must match the Stitch dark spec',
      );
      expect(scheme.surface, const Color(0xFF121318));
      expect(scheme.surfaceContainerHigh, const Color(0xFF2A2A30));
    });

    test('themes are fixed and never derived from the device palette', () {
      expect(KeyelTheme.light().colorScheme, KeyelColors.lightScheme);
      expect(KeyelTheme.dark().colorScheme, KeyelColors.darkScheme);

      // The two schemes are complete, explicit role maps rather than seeds.
      expect(
        KeyelColors.lightScheme.primary,
        isNot(KeyelColors.darkScheme.primary),
      );
      expect(KeyelColors.lightScheme.brightness, Brightness.light);
      expect(KeyelColors.darkScheme.brightness, Brightness.dark);
    });

    test('uses Material 3 and the RobotoFlex family', () {
      expect(KeyelTheme.light().useMaterial3, isTrue);
      expect(
        KeyelTheme.dark().textTheme.titleLarge?.fontFamily,
        KeyelTheme.fontFamily,
      );
    });

    test('buttons are pill shaped at 56dp height', () {
      final style = KeyelTheme.light().filledButtonTheme.style!;
      expect(style.minimumSize!.resolve({})!.height, 56);
      final shape = style.shape!.resolve({});
      expect(
        shape is RoundedRectangleBorder &&
            shape.borderRadius == BorderRadius.circular(9999),
        isTrue,
        reason: 'CTA buttons must be full pills (design.md §Buttons)',
      );
    });
  });
}
