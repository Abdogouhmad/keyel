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
import 'package:keyel/ui/adaptive/content.dart';
import 'package:keyel/ui/adaptive/keyel_shell.dart';
import 'package:keyel/ui/adaptive/window.dart';
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
}
