import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/ui/keyel.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('shows the message and fires the optional action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        const KeyelStateMessage(
          kind: KeyelStateMessageKind.error,
          title: 'Could not load',
          message: 'The vault file could not be read.',
          actionLabel: 'Retry',
        ),
      ),
    );

    // No action handler: the button is not shown.
    expect(find.text('Could not load'), findsOneWidget);
    expect(find.text('The vault file could not be read.'), findsOneWidget);
    expect(find.byType(KeyelPillButton), findsNothing);

    await tester.pumpWidget(
      _host(
        KeyelStateMessage(
          kind: KeyelStateMessageKind.error,
          title: 'Could not load',
          message: 'The vault file could not be read.',
          actionLabel: 'Retry',
          onAction: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KeyelPillButton), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(taps, 1);
  });

  testWidgets('loading kind shows a progress indicator', (tester) async {
    await tester.pumpWidget(
      _host(
        const KeyelStateMessage(
          kind: KeyelStateMessageKind.loading,
          message: 'Loading your vault…',
        ),
      ),
    );

    expect(find.text('Loading your vault…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('fits at 200% text scale and respects reduced motion', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _host(
        KeyelStateMessage(
          kind: KeyelStateMessageKind.error,
          title: 'Could not load',
          message:
              'The vault file could not be read because the storage is '
              'temporarily unavailable on this device.',
          actionLabel: 'Retry',
          onAction: () {},
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Retry'), findsOneWidget);
  });
}
