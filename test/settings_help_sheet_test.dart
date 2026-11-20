import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/settings/widgets/settings_help_sheet.dart';
import 'package:keyel/ui/keyel.dart';

void main() {
  Future<void> openSheet(WidgetTester tester, {double textScale = 1}) async {
    if (textScale != 1) {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: KeyelTheme.light(),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSettingsHelpSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('help sheet shows local, accurate topics', (tester) async {
    await openSheet(tester);

    expect(find.text('Keyel help'), findsOneWidget);
    expect(find.text('Your vault stays local'), findsOneWidget);
    expect(find.text('Auto-lock and clipboard'), findsOneWidget);
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(find.text('Recovery'), findsOneWidget);
    // The old placeholder copy must be gone for good.
    expect(find.textContaining('future update'), findsNothing);
  });

  testWidgets('help sheet closes from its close button', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Keyel help'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('help sheet has no overflow at 200% text scale', (tester) async {
    await openSheet(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Keyel help'), findsOneWidget);
  });
}
