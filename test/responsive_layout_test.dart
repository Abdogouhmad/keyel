import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/health_provider.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/autofill/autofill_picker_screen.dart';
import 'package:keyel/features/autofill/autofill_save_screen.dart';
import 'package:keyel/features/import_export/import_export_screen.dart';
import 'package:keyel/features/security_dashboard/security_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/adaptive/columns.dart';
import 'package:keyel/ui/adaptive/content.dart';
import 'package:keyel/ui/adaptive/direction.dart';
import 'package:keyel/ui/adaptive/keyel_shell.dart';
import 'package:keyel/ui/adaptive/window.dart';
import 'package:keyel/ui/design_system/keyel_adaptive_sheet.dart';
import 'package:keyel/ui/design_system/keyel_top_bar.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

const _cleanReport = HealthReportDto(
  score: 100,
  totalLogins: 0,
  weak: [],
  reused: [],
  old: [],
  noTwoFactor: [],
  insecureUrl: [],
);

/// A repository that never touches Rust: the import/export hub only needs the
/// provider to resolve at build time.
class _FakeRepository extends VaultRepository {
  new();

  @override
  bool get vaultExists => true;

  @override
  bool get isUnlocked => true;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<List<AutofillMatchDto>> findAutofillMatches({
    String? package,
    String? webDomain,
    String query = '',
    bool requireVerified = false,
  }) async => const [];
}

/// A vault session pinned to `locked`: the autofill picker only needs the
/// status to build its locked state without touching Rust.
class _LockedSession extends VaultSessionNotifier {
  @override
  VaultSessionState build() =>
      const VaultSessionState(status: VaultStatus.locked);
}

/// An in-memory file transfer service: no picker, no share sheet, no disk.
class _FakeFiles implements FileTransferService {
  new();

  @override
  Future<PickedFile?> pickFile({String? dialogTitle}) async => null;

  @override
  Future<String> temporaryFilePath(String fileName) async =>
      '/tmp/keyel/$fileName';

  @override
  Future<void> writeTextFile(String path, String contents) async {}

  @override
  Future<void> clearTemporaryExports() async {}

  @override
  Future<void> shareFile(String path, {String? subject}) async {}

  @override
  Future<void> deleteFile(String path) async {}
}

void _sizeTo(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _securityHost() => ProviderScope(
  overrides: [healthProvider.overrideWith((ref) => _cleanReport)],
  child: MaterialApp(theme: KeyelTheme.light(), home: const SecurityScreen()),
);

Widget _importExportHost() => ProviderScope(
  overrides: [
    vaultRepositoryProvider.overrideWithValue(_FakeRepository()),
    fileTransferServiceProvider.overrideWithValue(_FakeFiles()),
  ],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: const ImportExportScreen(),
  ),
);

/// Real screens inside the shell's effective-layout scope. Without this scope
/// `supportsTwoColumns` is forced false and a desktop test would only ever see
/// the single-column fallback, hiding a broken multi-column composition.
Widget _scopedPage(Widget child) => MaterialApp(
  theme: KeyelTheme.light(),
  home: EffectiveLayoutScope(
    chrome: const LayoutChrome(width: 280),
    child: child,
  ),
);

Widget _scopedSecurityHost() => ProviderScope(
  overrides: [healthProvider.overrideWith((ref) => _cleanReport)],
  child: _scopedPage(const SecurityScreen()),
);

Widget _scopedImportExportHost() => ProviderScope(
  overrides: [
    vaultRepositoryProvider.overrideWithValue(_FakeRepository()),
    fileTransferServiceProvider.overrideWithValue(_FakeFiles()),
  ],
  child: _scopedPage(const ImportExportScreen()),
);

Widget _pickerHost() => ProviderScope(
  overrides: [
    vaultRepositoryProvider.overrideWithValue(_FakeRepository()),
    vaultSessionProvider.overrideWith(_LockedSession.new),
  ],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: const AutofillPickerScreen(),
  ),
);

Widget _saveHost() => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(_FakeRepository())],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: const AutofillSaveScreen(),
  ),
);

/// A sub-page host: [KeyelSubShell] around a bare marker, with no router (the
/// shell only reaches for one when a nav item is tapped). Size the window with
/// `_sizeTo` before pumping.
Widget _subShellHost({int tabIndex = KeyelTab.settings}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: KeyelSubShell(tabIndex: tabIndex, child: const Text('sub-page')),
);

void main() {
  group('WindowSizeClass', () {
    test('maps widths to the Material window size classes', () {
      expect(WindowSizeClass.fromWidth(320), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1199.9), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(2560), WindowSizeClass.large);
    });

    test('only expanded and large windows support a two-pane layout', () {
      expect(WindowSizeClass.compact.supportsListDetail, isFalse);
      expect(WindowSizeClass.medium.supportsListDetail, isFalse);
      expect(WindowSizeClass.expanded.supportsListDetail, isTrue);
      expect(WindowSizeClass.large.supportsListDetail, isTrue);
    });

    test('page margins grow from phone to tablet to desktop', () {
      expect(WindowSizeClass.compact.pageMargin, 16);
      expect(WindowSizeClass.medium.pageMargin, 24);
      expect(WindowSizeClass.expanded.pageMargin, 24);
      expect(WindowSizeClass.large.pageMargin, 32);
    });

    test('card gaps widen past the compact phone', () {
      expect(WindowSizeClass.compact.contentGap, 16);
      expect(WindowSizeClass.medium.contentGap, 24);
      expect(WindowSizeClass.large.contentGap, 24);
    });
  });

  group('KeyelContent', () {
    const probe = Key('probe');

    Future<double> probeWidth(
      WidgetTester tester,
      double window,
      double maxWidth,
    ) async {
      _sizeTo(tester, window);
      await tester.pumpWidget(
        MaterialApp(
          theme: KeyelTheme.light(),
          home: Scaffold(
            body: KeyelContent(
              maxWidth: maxWidth,
              child: Container(key: probe, height: 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byKey(probe)).width;
    }

    testWidgets('is a no-op on a phone narrower than the cap', (tester) async {
      expect(await probeWidth(tester, 400, KeyelContentWidth.reading), 400);
    });

    testWidgets('caps the column on a tablet', (tester) async {
      expect(
        await probeWidth(tester, 1000, KeyelContentWidth.form),
        KeyelContentWidth.form,
      );
    });

    testWidgets('caps the column on a desktop window', (tester) async {
      expect(
        await probeWidth(tester, 1600, KeyelContentWidth.reading),
        KeyelContentWidth.reading,
      );
    });

    testWidgets('never grows past a window narrower than the cap', (
      tester,
    ) async {
      expect(await probeWidth(tester, 700, KeyelContentWidth.page), 700);
    });
  });

  group('screens cap their content column', () {
    testWidgets('security dashboard fills a phone', (tester) async {
      _sizeTo(tester, 400);
      await tester.pumpWidget(_securityHost());
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ListView)).width, 400);
    });

    testWidgets('security dashboard caps at 720 on a desktop window', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_securityHost());
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ListView)).width,
        KeyelContentWidth.reading,
      );
    });

    testWidgets('security dashboard has no overflow at 200% text scale', (
      tester,
    ) async {
      _sizeTo(tester, 1400);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_securityHost());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('import/export hub caps at 720 on a desktop window', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_importExportHost());
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ListView)).width,
        KeyelContentWidth.reading,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('real screens use multi-column compositions inside the shell', () {
    testWidgets('security dashboard splits into two columns on desktop', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_scopedSecurityHost());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('import/export hub splits into two columns on desktop', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_scopedImportExportHost());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('KeyelSubShell keeps the nav chrome on wide windows', () {
    testWidgets('compact is a pass-through: no shell chrome', (tester) async {
      _sizeTo(tester, 400);
      await tester.pumpWidget(_subShellHost());
      await tester.pumpAndSettle();

      expect(find.text('sub-page'), findsOneWidget);
      // The page is returned directly, not wrapped in a rail/drawer scaffold.
      expect(find.byType(Scaffold), findsNothing);
      expect(find.text('Vault'), findsNothing);
    });

    testWidgets('medium shows the icon-only rail', (tester) async {
      _sizeTo(tester, 700);
      await tester.pumpWidget(_subShellHost());
      await tester.pumpAndSettle();

      expect(find.text('sub-page'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      // Icon-only: the labels are hidden.
      expect(find.text('Vault'), findsNothing);
      expect(find.byIcon(Icons.key_outlined), findsOneWidget);
    });

    testWidgets('expanded shows the labelled rail and highlights its tab', (
      tester,
    ) async {
      _sizeTo(tester, 1000);
      await tester.pumpWidget(_subShellHost());
      await tester.pumpAndSettle();

      expect(find.text('sub-page'), findsOneWidget);
      expect(find.text('Vault'), findsOneWidget);
      // The sub-page's own tab (settings) is the selected one.
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('large shows the drawer navigation', (tester) async {
      _sizeTo(tester, 1200);
      await tester.pumpWidget(_subShellHost());
      await tester.pumpAndSettle();

      expect(find.text('sub-page'), findsOneWidget);
      expect(find.text('Keyel'), findsOneWidget); // Drawer brand header.
      expect(find.text('Vault'), findsOneWidget);
    });
  });

  group('autofill screens cap their content column', () {
    testWidgets('picker caps at 720 on a desktop window', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_pickerHost());
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(KeyelTopBar)).width,
        KeyelContentWidth.reading,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('save screen caps at 560 on a desktop window', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_saveHost());
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(KeyelTopBar)).width,
        KeyelContentWidth.form,
      );
      expect(
        tester.getSize(find.byType(ListView)).width,
        KeyelContentWidth.form,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('save screen fills a phone', (tester) async {
      _sizeTo(tester, 400);
      await tester.pumpWidget(_saveHost());
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ListView)).width, 400);
      expect(tester.takeException(), isNull);
    });
  });

  group('EffectiveLayoutScope', () {
    test('subtracts chrome and margins before dividing by text scale', () {
      const withDrawer = EffectiveLayoutData(
        windowWidth: 1200,
        chromeWidth: 280,
        pageMargin: 32,
        textScale: 1,
      );
      expect(withDrawer.contentWidth, 856);
      expect(withDrawer.capacity, 856);
      expect(withDrawer.supportsTwoColumns, isFalse);
      // A 1200 dp window with a 280 dp drawer still fits a list/detail pair.
      expect(
        WindowSizeClass.fromWidth(withDrawer.width).supportsListDetail,
        isTrue,
      );

      const scaled = EffectiveLayoutData(
        windowWidth: 1600,
        chromeWidth: 0,
        pageMargin: 32,
        textScale: 2,
      );
      expect(scaled.contentWidth, 1536);
      expect(scaled.capacity, 768);
      expect(scaled.supportsTwoColumns, isFalse);
    });

    test('page margins follow the physical window class', () {
      expect(EffectiveLayoutScope.pageMarginFor(400), 16);
      expect(EffectiveLayoutScope.pageMarginFor(700), 24);
      expect(EffectiveLayoutScope.pageMarginFor(1000), 24);
      expect(EffectiveLayoutScope.pageMarginFor(1200), 32);
    });

    Future<EffectiveLayoutData> probe(
      WidgetTester tester, {
      required double window,
      required double chrome,
      double textScale = 1,
    }) async {
      _sizeTo(tester, window);
      if (textScale != 1) {
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      late EffectiveLayoutData observed;
      await tester.pumpWidget(
        MaterialApp(
          theme: KeyelTheme.light(),
          home: Scaffold(
            body: EffectiveLayoutScope(
              chrome: LayoutChrome(width: chrome),
              child: Builder(
                builder: (context) {
                  observed = context.maybeEffectiveLayout!;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return observed;
    }

    testWidgets('reports the width left after the drawer', (tester) async {
      final layout = await probe(tester, window: 1200, chrome: 280);
      expect(layout.windowWidth, 1200);
      expect(layout.chromeWidth, 280);
      expect(layout.pageMargin, 32);
      expect(layout.contentWidth, 856);
      expect(layout.width, 856);
      expect(layout.supportsTwoColumns, isFalse);
    });

    testWidgets('a 200% text scale collapses two-column layouts', (
      tester,
    ) async {
      final layout = await probe(tester, window: 1600, chrome: 0, textScale: 2);
      expect(layout.contentWidth, 1536);
      expect(layout.capacity, 768);
      expect(layout.supportsTwoColumns, isFalse);
    });

    testWidgets('falls back to the raw window width outside a shell', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      late double width;
      late bool twoColumns;
      await tester.pumpWidget(
        MaterialApp(
          theme: KeyelTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                width = context.effectiveWidth;
                twoColumns = context.supportsTwoColumns;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(width, 1600);
      expect(twoColumns, isFalse);
    });
  });

  group('KeyelResponsiveColumns', () {
    Widget host({required bool scoped}) {
      const columns = KeyelResponsiveColumns(
        leading: [Text('lead-card')],
        trailing: [Text('trail-card')],
      );
      return MaterialApp(
        theme: KeyelTheme.light(),
        home: Scaffold(
          body: scoped
              ? const EffectiveLayoutScope(
                  chrome: LayoutChrome(),
                  child: columns,
                )
              : columns,
        ),
      );
    }

    testWidgets('stacks both groups in one column without a shell', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(host(scoped: false));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('lead-card'), findsOneWidget);
      expect(find.text('trail-card'), findsOneWidget);
    });

    testWidgets('lays out two columns when effective capacity allows', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(host(scoped: true));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNWidgets(2));
      final lead = tester.getRect(find.text('lead-card'));
      final trail = tester.getRect(find.text('trail-card'));
      expect(lead.left, lessThan(trail.left));
      expect(lead.top, closeTo(trail.top, 1));
    });

    testWidgets('returns to one column when text is scaled to 200%', (
      tester,
    ) async {
      _sizeTo(tester, 1600);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(host(scoped: true));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('DirectionalChrome', () {
    Future<List<String>> report(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KeyelTheme.light(),
          home: Directionality(
            textDirection: direction,
            child: Builder(
              builder: (context) => Text(
                key: const Key('direction-report'),
                [
                  context.isRtl.toString(),
                  context.backArrow.codePoint.toString(),
                  context.forwardArrow.codePoint.toString(),
                  context.forwardChevron.codePoint.toString(),
                  context.alignStart.toString(),
                  context.alignEnd.toString(),
                ].join('|'),
              ),
            ),
          ),
        ),
      );
      return tester
          .widget<Text>(find.byKey(const Key('direction-report')))
          .data!
          .split('|');
    }

    testWidgets('uses physical back/forward glyphs in LTR', (tester) async {
      final values = await report(tester, TextDirection.ltr);
      expect(values[0], 'false');
      expect(values[1], Icons.arrow_back_rounded.codePoint.toString());
      expect(values[2], Icons.arrow_forward_rounded.codePoint.toString());
      expect(values[3], Icons.chevron_right_rounded.codePoint.toString());
      expect(values[4], 'Alignment.centerLeft');
      expect(values[5], 'Alignment.centerRight');
    });

    testWidgets('mirrors back/forward glyphs and edges in RTL', (tester) async {
      final values = await report(tester, TextDirection.rtl);
      expect(values[0], 'true');
      expect(values[1], Icons.arrow_forward_rounded.codePoint.toString());
      expect(values[2], Icons.arrow_back_rounded.codePoint.toString());
      expect(values[3], Icons.chevron_left_rounded.codePoint.toString());
      expect(values[4], 'Alignment.centerRight');
      expect(values[5], 'Alignment.centerLeft');
    });
  });

  group('showKeyelAdaptiveSheet', () {
    const sheetProbe = Key('sheet-probe');

    Future<void> start(
      WidgetTester tester, {
      required double width,
      TextDirection direction = TextDirection.ltr,
    }) async {
      _sizeTo(tester, width);
      await tester.pumpWidget(
        MaterialApp(
          theme: KeyelTheme.light(),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showKeyelAdaptiveSheet<void>(
                      context: context,
                      builder: (_) => const SizedBox(
                        key: sheetProbe,
                        width: 200,
                        height: 120,
                      ),
                    ),
                    child: const Text('open sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open sheet'));
      // Stop mid-transition so the slide direction is observable.
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('phones get a bottom sheet', (tester) async {
      await start(tester, width: 400);
      await tester.pumpAndSettle();

      expect(find.byKey(sheetProbe), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('wide windows get a bounded, end-aligned side sheet', (
      tester,
    ) async {
      await start(tester, width: 1600);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      final probe = find.byKey(sheetProbe);
      expect(probe, findsOneWidget);

      final constrained = tester.widget<ConstrainedBox>(
        find.ancestor(of: probe, matching: find.byType(ConstrainedBox)).first,
      );
      expect(constrained.constraints.maxWidth, 480);
      // LTR end edge is the physical right edge.
      expect(tester.getRect(probe).right, closeTo(1600, 1));

      final surface = tester.widget<ClipRRect>(
        find.ancestor(of: probe, matching: find.byType(ClipRRect)).first,
      );
      final radius = surface.borderRadius as BorderRadius;
      expect(radius.topLeft.x, greaterThan(0));
      expect(radius.topRight.x, 0);
    });

    testWidgets('RTL sheets anchor and round towards the left edge', (
      tester,
    ) async {
      await start(tester, width: 1200, direction: TextDirection.rtl);
      await tester.pumpAndSettle();

      final probe = find.byKey(sheetProbe);
      expect(tester.getRect(probe).left, closeTo(0, 1));

      final surface = tester.widget<ClipRRect>(
        find.ancestor(of: probe, matching: find.byType(ClipRRect)).first,
      );
      final radius = surface.borderRadius as BorderRadius;
      expect(radius.topLeft.x, 0);
      expect(radius.topRight.x, greaterThan(0));
    });

    testWidgets('side sheets slide in from the right in LTR', (tester) async {
      await start(tester, width: 1200);
      final slide = tester.widget<SlideTransition>(
        find
            .ancestor(
              of: find.byKey(sheetProbe),
              matching: find.byType(SlideTransition),
            )
            .first,
      );
      expect(slide.position.value.dx, greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('side sheets slide in from the left in RTL', (tester) async {
      await start(tester, width: 1200, direction: TextDirection.rtl);
      final slide = tester.widget<SlideTransition>(
        find
            .ancestor(
              of: find.byKey(sheetProbe),
              matching: find.byType(SlideTransition),
            )
            .first,
      );
      expect(slide.position.value.dx, lessThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('side sheets stay bounded after navigation chrome', (
      tester,
    ) async {
      _sizeTo(tester, 600);
      await tester.pumpWidget(
        MaterialApp(
          theme: KeyelTheme.light(),
          home: EffectiveLayoutScope(
            chrome: const LayoutChrome(width: 280),
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showKeyelAdaptiveSheet<void>(
                      context: context,
                      builder: (_) =>
                          const SizedBox(key: sheetProbe, height: 120),
                    ),
                    child: const Text('open sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      final constrained = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.byKey(sheetProbe),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      // (600 - 280 - 2*24) * 0.9 = 244.8, raised to the 320 dp floor.
      expect(constrained.constraints.maxWidth, 320);
    });
  });
}
