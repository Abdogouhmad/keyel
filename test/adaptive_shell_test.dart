import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/ui/adaptive/keyel_shell.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

// ---------------------------------------------------------------------------
// Test harness: the real KeyelShell with four static branch screens so the
// adaptive layouts can be exercised without the Rust bridge.
// ---------------------------------------------------------------------------

const _markers = {
  '/vault': 'vault-content',
  '/generator': 'generator-content',
  '/security': 'security-content',
  '/settings': 'settings-content',
};

final _testRouter = GoRouter(
  initialLocation: '/vault',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => KeyelShell(navigationShell: shell),
      branches: [
        for (final location in _markers.keys)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: location,
                builder: (context, state) =>
                    Scaffold(body: Center(child: Text(_markers[location]!))),
              ),
            ],
          ),
      ],
    ),
  ],
);

Widget _harness(
  double width,
  Brightness brightness, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800), textScaler: textScaler),
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light
          ? KeyelTheme.light()
          : KeyelTheme.dark(),
      routerConfig: _testRouter,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  double width,
  Brightness brightness, {
  TextScaler textScaler = TextScaler.noScaling,
}) => tester.pumpWidget(_harness(width, brightness, textScaler: textScaler));

Future<void> _golden(
  WidgetTester tester,
  double width,
  Brightness brightness,
  String name,
) async {
  await _pump(tester, width, brightness);
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/shell_$name.png'),
  );
}

void main() {
  testWidgets('compact window shows the bottom navigation bar', (tester) async {
    await _pump(tester, 400, Brightness.light);
    await tester.pumpAndSettle();

    // Bottom nav shows all four labelled destinations.
    for (final label in ['Vault', 'Generator', 'Security', 'Settings']) {
      expect(find.text(label), findsOneWidget, reason: 'bottom bar label');
    }
    // Vault branch content is on screen.
    expect(find.text('vault-content'), findsOneWidget);
  });

  testWidgets('medium window shows an icon-only rail', (tester) async {
    await _pump(tester, 700, Brightness.light);
    await tester.pumpAndSettle();

    // Rail keeps the selected key glyph but no labels. Two glyphs: the
    // brand logo and the selected (vault) destination.
    expect(find.text('Vault'), findsNothing);
    expect(find.byIcon(Icons.key_rounded), findsNWidgets(2));
    expect(find.text('vault-content'), findsOneWidget);
  });

  testWidgets('expanded window shows a labelled rail', (tester) async {
    await _pump(tester, 1000, Brightness.light);
    await tester.pumpAndSettle();

    expect(find.text('Vault'), findsOneWidget);
    // Brand logo + selected destination glyph.
    expect(find.byIcon(Icons.key_rounded), findsNWidgets(2));
    expect(find.text('vault-content'), findsOneWidget);
  });

  testWidgets('large window shows the drawer navigation', (tester) async {
    await _pump(tester, 1200, Brightness.light);
    await tester.pumpAndSettle();

    expect(find.text('Keyel'), findsOneWidget); // Brand header.
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('vault-content'), findsOneWidget);
  });

  testWidgets('resizing keeps the selected branch and its content', (
    tester,
  ) async {
    await _pump(tester, 400, Brightness.light);
    await tester.pumpAndSettle();

    // Jump to the generator branch via the bottom bar.
    await tester.tap(find.text('Generator'));
    await tester.pumpAndSettle();
    expect(find.text('generator-content'), findsOneWidget);

    // Resize from phone width to tablet width: no state loss.
    await _pump(tester, 1000, Brightness.light);
    await tester.pumpAndSettle();
    expect(find.text('generator-content'), findsOneWidget);
    expect(find.text('vault-content'), findsNothing);
  });

  testWidgets('compact shell has no overflow at 200% text scale', (
    tester,
  ) async {
    await _pump(
      tester,
      400,
      Brightness.light,
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Every destination stays reachable.
    for (final label in ['Vault', 'Generator', 'Security', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  // -----------------------------------------------------------------------
  // Goldens: 400 / 700 / 1000 dp in light and dark.
  // -----------------------------------------------------------------------
  testWidgets('golden: 400 dp compact, light', (tester) async {
    await _golden(tester, 400, Brightness.light, '400_light');
  });

  testWidgets('golden: 400 dp compact, dark', (tester) async {
    await _golden(tester, 400, Brightness.dark, '400_dark');
  });

  testWidgets('golden: 700 dp medium, light', (tester) async {
    await _golden(tester, 700, Brightness.light, '700_light');
  });

  testWidgets('golden: 700 dp medium, dark', (tester) async {
    await _golden(tester, 700, Brightness.dark, '700_dark');
  });

  testWidgets('golden: 1000 dp expanded, light', (tester) async {
    await _golden(tester, 1000, Brightness.light, '1000_light');
  });

  testWidgets('golden: 1000 dp expanded, dark', (tester) async {
    await _golden(tester, 1000, Brightness.dark, '1000_dark');
  });
}
