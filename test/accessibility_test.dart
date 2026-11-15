import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/ui/design_system/pressable_scale.dart';
import 'package:keyel/ui/theme/keyel_colors.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Wraps [child] in a [MediaQuery] with the accessibility flags under test.
Widget _withMedia({
  required Widget child,
  bool highContrast = false,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      highContrast: highContrast,
      disableAnimations: disableAnimations,
    ),
    child: child,
  );
}

void main() {
  group('KeyelMotion.resolve', () {
    testWidgets('returns the duration when motion is allowed', (tester) async {
      late Duration resolved;
      await tester.pumpWidget(
        _withMedia(
          child: Builder(
            builder: (context) {
              resolved = KeyelMotion.resolve(context, KeyelMotion.medium);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, KeyelMotion.medium);
    });

    testWidgets('collapses to zero when the platform disables animations', (
      tester,
    ) async {
      late Duration resolved;
      await tester.pumpWidget(
        _withMedia(
          disableAnimations: true,
          child: Builder(
            builder: (context) {
              resolved = KeyelMotion.resolve(context, KeyelMotion.medium);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, Duration.zero);
    });
  });

  group('KeyelTheme.highContrast', () {
    test('promotes secondary text and boundaries to full contrast', () {
      final base = KeyelTheme.light();
      final hc = KeyelTheme.highContrast(base);

      expect(hc.colorScheme.onSurfaceVariant, base.colorScheme.onSurface);
      expect(hc.colorScheme.outline, KeyelColors.onSurfaceVariantLight);
      expect(hc.colorScheme.outlineVariant, KeyelColors.onSurfaceVariantLight);
      expect(hc.dividerColor, KeyelColors.onSurfaceVariantLight);
      expect(hc.dividerTheme.thickness, greaterThan(1));
    });

    test('draws visible input borders', () {
      final hc = KeyelTheme.highContrast(KeyelTheme.light());
      final border = hc.inputDecorationTheme.enabledBorder;
      expect(border, isA<OutlineInputBorder>());
      expect((border! as OutlineInputBorder).borderSide.width, greaterThan(1));
    });

    test('uses the dark rule on the dark theme', () {
      final hc = KeyelTheme.highContrast(KeyelTheme.dark());
      expect(hc.colorScheme.outline, KeyelColors.onSurfaceVariantDark);
    });

    testWidgets('builder applies the stronger theme only when asked', (
      tester,
    ) async {
      ThemeData? captured;

      Widget probe() => Builder(
        builder: (context) {
          captured = Theme.of(context);
          return const SizedBox.shrink();
        },
      );

      await tester.pumpWidget(
        _withMedia(
          child: MaterialApp(theme: KeyelTheme.light(), home: probe()),
        ),
      );
      expect(
        captured!.colorScheme.outline,
        isNot(KeyelColors.onSurfaceVariantLight),
      );

      await tester.pumpWidget(
        _withMedia(
          highContrast: true,
          child: MaterialApp(
            theme: KeyelTheme.light(),
            builder: (context, child) =>
                KeyelTheme.highContrastBuilder(child: child!),
            home: probe(),
          ),
        ),
      );
      expect(captured!.colorScheme.outline, KeyelColors.onSurfaceVariantLight);
    });
  });

  group('PressableScale reduced motion', () {
    Widget host() => _withMedia(
      disableAnimations: true,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: PressableScale(
          onTap: _noop,
          child: SizedBox(width: 48, height: 48),
        ),
      ),
    );

    testWidgets('does not scale the surface when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableScale)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 1, reason: 'press must not move under reduce motion');

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('scales the surface when animations are allowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _withMedia(
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: PressableScale(
              onTap: _noop,
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableScale)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, KeyelMotion.pressedScale);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

void _noop() {}
