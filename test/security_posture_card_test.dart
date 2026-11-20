import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/security_dashboard/widgets/security_posture_card.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

SecurityPostureSeal _seal({
  required String label,
  required String value,
  required IconData icon,
  required bool active,
}) => SecurityPostureSeal(
  label: label,
  value: value,
  icon: icon,
  active: active,
  semanticsLabel: '$label: $value.',
);

SecurityPosture _posture({
  bool clipboardActive = true,
  bool breachActive = true,
}) => SecurityPosture(
  autoLock: _seal(
    label: 'Auto-lock',
    value: 'After 1 minute',
    icon: Icons.lock_clock_rounded,
    active: true,
  ),
  clipboard: _seal(
    label: 'Clipboard wipe',
    value: clipboardActive ? '30 seconds' : 'On lock only',
    icon: Icons.content_paste_off_rounded,
    active: clipboardActive,
  ),
  screenshot: _seal(
    label: 'Screenshot blocking',
    value: 'Always on',
    icon: Icons.no_photography_rounded,
    active: true,
  ),
  breach: _seal(
    label: 'Breach check',
    value: breachActive ? 'Enabled' : 'Off',
    icon: Icons.gpp_good_rounded,
    active: breachActive,
  ),
);

Widget _host(
  SecurityPosture posture, {
  bool disableAnimations = false,
  VoidCallback? onReview,
}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: SecurityPostureCard(
        posture: posture,
        onReviewSettings: onReview ?? () {},
      ),
    ),
  ),
);

void main() {
  group('SecurityPostureCard', () {
    testWidgets('shows all four protections when every seal is active', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_posture()));
      await tester.pumpAndSettle();

      expect(find.text('Vault posture'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      for (final label in [
        'Auto-lock',
        'Clipboard wipe',
        'Screenshot blocking',
        'Breach check',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('After 1 minute'), findsOneWidget);
      expect(find.text('30 seconds'), findsOneWidget);
      expect(find.text('Always on'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Review settings'), findsOneWidget);
    });

    testWidgets('reflects a mixed posture with weaker states', (tester) async {
      await tester.pumpWidget(
        _host(_posture(clipboardActive: false, breachActive: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('On lock only'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('30 seconds'), findsNothing);
      expect(find.text('Enabled'), findsNothing);
    });

    testWidgets('the review action is wired', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(_posture(), onReview: () => tapped++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review settings'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('has no overflow at 200% text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _host(_posture(clipboardActive: false, breachActive: false)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Vault posture'), findsOneWidget);
    });

    testWidgets('reduced motion resolves the stagger immediately', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_posture(), disableAnimations: true));
      // No frame pumping: the seals must already be fully visible.
      for (var i = 0; i < 4; i++) {
        final transition = tester.widget<FadeTransition>(
          find.byKey(ValueKey<String>('posture-seal-$i')),
        );
        expect(transition.opacity.value, 1.0);
      }
    });

    testWidgets('normal motion reveals seals in a stagger', (tester) async {
      await tester.pumpWidget(_host(_posture()));
      await tester.pump(const Duration(milliseconds: 150));

      double opacity(int index) => tester
          .widget<FadeTransition>(
            find.byKey(ValueKey<String>('posture-seal-$index')),
          )
          .opacity
          .value;
      expect(
        opacity(0),
        greaterThan(opacity(3)),
        reason: 'the first seal should lead the last one',
      );
    });
  });
}
