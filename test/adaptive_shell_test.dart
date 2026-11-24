import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/focus/keyel_search_focus.dart';
import 'package:keyel/ui/keyel.dart';

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
  TextDirection textDirection = TextDirection.ltr,
}) {
  return ProviderScope(
    child: MediaQuery(
      data: MediaQueryData(size: Size(width, 800), textScaler: textScaler),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.light
            ? KeyelTheme.light()
            : KeyelTheme.dark(),
        routerConfig: _testRouter,
        builder: (context, child) => Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  double width,
  Brightness brightness, {
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
}) => tester.pumpWidget(
  _harness(
    width,
    brightness,
    textScaler: textScaler,
    textDirection: textDirection,
  ),
);

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
    // The 76 dp rail must contain its items (the old 80 dp item overflowed).
    expect(tester.takeException(), isNull);
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

  testWidgets('RTL rail keeps every destination reachable', (tester) async {
    await _pump(
      tester,
      1000,
      Brightness.light,
      textDirection: TextDirection.rtl,
    );
    await tester.pumpAndSettle();

    // The shared test router may be on a later branch from a previous test,
    // so assert that *some* branch body renders rather than a fixed one.
    expect(
      _markers.values.any((marker) => find.text(marker).evaluate().isNotEmpty),
      isTrue,
      reason: 'a branch body must render in RTL',
    );
    for (final label in ['Vault', 'Generator', 'Security', 'Settings']) {
      expect(find.text(label), findsOneWidget, reason: 'RTL rail label');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL drawer has no overflow at 200% text scale', (tester) async {
    await _pump(
      tester,
      1200,
      Brightness.light,
      textDirection: TextDirection.rtl,
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();

    expect(
      _markers.values.any((marker) => find.text(marker).evaluate().isNotEmpty),
      isTrue,
      reason: 'a branch body must render in RTL',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer chrome is reflected in the page layout scope', (
    tester,
  ) async {
    late EffectiveLayoutData observed;
    final router = GoRouter(
      initialLocation: '/vault',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              KeyelShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/vault',
                  builder: (context, state) {
                    observed = context.maybeEffectiveLayout!;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A 280 dp drawer and two 32 dp margins leave 856 dp, so a page must not
    // decide its columns from the raw 1200 dp window width.
    expect(observed.chromeWidth, 280);
    expect(observed.contentWidth, 856);
    expect(observed.supportsTwoColumns, isFalse);
  });

  testWidgets('Ctrl+F focuses the vault search field through the shell', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/vault',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              KeyelShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/vault',
                  builder: (context, state) => const _SearchProbe(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
      reason: 'the global find shortcut must focus the vault search field',
    );
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

/// Minimal vault-branch content: a real search field bound to the shared focus
/// node, so the shortcut test exercises the same wiring as production.
class _SearchProbe extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = ref.watch(vaultSearchFocusProvider);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: KeyelSearchField(focusNode: focusNode, hintText: 'Find items'),
        ),
      ),
    );
  }
}
