import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/features/settings/appearance_screen.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

String _labelStartingWith(WidgetTester tester, String prefix) {
  final labels = tester
      .widgetList<Semantics>(
        find.byWidgetPredicate((widget) => widget is Semantics),
      )
      .map((widget) => widget.properties.label ?? '');
  return labels.firstWhere(
    (label) => label.startsWith(prefix),
    orElse: () => '',
  );
}

String _previewLabel(WidgetTester tester) =>
    _labelStartingWith(tester, 'Theme preview');

void main() {
  final prefs = AppPreferences.instance;

  setUp(() {
    prefs
      ..themeMode = 'system'
      ..paletteId = 'indigo'
      ..amoledBlack = false
      ..animationsEnabled = true
      ..hapticsEnabled = true;
  });

  testWidgets('theme screen shows a live preview with real state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: KeyelTheme.light(),
          home: const AppearanceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live preview'), findsOneWidget);
    expect(find.text('Example login'), findsOneWidget);
    expect(find.text('Changes apply instantly across Keyel.'), findsOneWidget);
    expect(
      _previewLabel(tester),
      contains('Theme preview: Indigo, System mode'),
    );
    expect(
      find.text('Follows your device appearance and changes along with it.'),
      findsOneWidget,
    );
  });

  testWidgets('changing mode updates the preview and its caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: KeyelTheme.light(),
          home: const AppearanceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The richer cards push the Dark option below the fold.
    final darkDescription = find.text(
      'Stays dark even when your device uses light mode.',
    );
    await tester.ensureVisible(darkDescription);
    await tester.pumpAndSettle();
    await tester.tap(darkDescription);
    await tester.pumpAndSettle();
    expect(prefs.themeMode, 'dark');

    await tester.scrollUntilVisible(find.text('Live preview'), -200);
    await tester.pumpAndSettle();
    expect(_previewLabel(tester), contains('Theme preview: Indigo, Dark mode'));
    expect(
      find.text('Stays dark even when your device uses light mode.'),
      findsOneWidget,
    );
  });

  testWidgets('theme screen has no overflow at 200% text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: KeyelTheme.light(),
          home: const AppearanceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Live preview'), findsOneWidget);
  });
}
