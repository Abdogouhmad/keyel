import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/quick_actions/quick_actions_sheet.dart';
import 'package:keyel/features/vault/widgets/vault_list_pane.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

const _summary = EntrySummaryDto(
  id: 'e1',
  kind: EntryKindDto.login,
  title: 'Alpha',
  subtitle: 'alpha@example.test',
  favorite: false,
  hasTotp: false,
);

final _detail = EntryDetailDto(
  id: 'e1',
  kind: EntryKindDto.login,
  title: 'Alpha',
  tags: const [],
  favorite: false,
  createdAt: BigInt.zero,
  updatedAt: BigInt.zero,
  hasNotes: false,
  customFields: const [],
);

class _RepositoryFake extends VaultRepository {
  @override
  bool get vaultExists => true;

  @override
  bool get isUnlocked => true;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<List<EntrySummaryDto>> listEntries({
    String query = '',
    EntryKindDto? kind,
    bool? favorite,
    bool includeDeleted = false,
  }) async => query.isEmpty ? [_summary] : const [];

  @override
  Future<List<FolderDto>> listFolders() async => const [];

  @override
  Future<EntryDetailDto> getEntry(String id) async => _detail;
}

class _SessionFake extends VaultSessionNotifier {
  new(this._status);

  final VaultStatus _status;

  @override
  VaultSessionState build() => VaultSessionState(status: _status);
}

class _InitialRouteFake extends InitialRouteNotifier {
  new(this.location);

  final String location;

  @override
  String build() => location;
}

Future<void> _surface(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host(
  ProviderContainer container, {
  required double width,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(size: Size(width, 900), textScaler: textScaler),
      child: MaterialApp.router(
        theme: KeyelTheme.light(),
        routerConfig: container.read(appRouterProvider),
        builder: (context, child) => Directionality(
          textDirection: direction,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

ProviderContainer _container(String location) => ProviderContainer(
  overrides: [
    vaultRepositoryProvider.overrideWithValue(_RepositoryFake()),
    vaultSessionProvider.overrideWith(() => _SessionFake(VaultStatus.unlocked)),
    initialRouteProvider.overrideWith(() => _InitialRouteFake(location)),
  ],
);

void main() {
  setUp(() {
    quickActionsOpen.value = false;
    AppPreferences.instance.vaultPaneRatio = 0.34;
  });

  tearDown(() {
    quickActionsOpen.value = false;
    AppPreferences.instance.vaultPaneRatio = 0.34;
  });

  Future<GoRouter> pumpVault(
    WidgetTester tester, {
    required double width,
    String location = KeyelRoutes.vault,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection direction = TextDirection.ltr,
  }) async {
    await _surface(tester, width);
    final container = _container(location);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _host(
        container,
        width: width,
        textScaler: textScaler,
        direction: direction,
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);
    return router;
  }

  /// Entry rows sit below the six actions in the scrolling result list.
  Future<void> scrollPaletteToEntries(WidgetTester tester) async {
    final list = find.descendant(
      of: find.byType(QuickActionsSheet),
      matching: find.byType(ListView),
    );
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
  }

  Future<void> sendCtrlK(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl/Cmd+K toggles the palette', (tester) async {
    await pumpVault(tester, width: 1400);

    await sendCtrlK(tester);
    expect(find.byType(QuickActionsSheet), findsOneWidget);

    await sendCtrlK(tester);
    expect(find.byType(QuickActionsSheet), findsNothing);
  });

  testWidgets('mobile top-bar action opens the same palette', (tester) async {
    await pumpVault(tester, width: 400);

    await tester.tap(find.byIcon(Icons.bolt_rounded).first);
    await tester.pumpAndSettle();

    expect(find.byType(QuickActionsSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QuickActionsSheet),
        matching: find.text('Quick actions'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('palette offers six static actions and entry results', (
    tester,
  ) async {
    await pumpVault(tester, width: 1400);
    await sendCtrlK(tester);

    final palette = find.byType(QuickActionsSheet);
    final l10n = l10nOf(tester.element(palette));
    for (final label in [
      l10n.quickActionOpenEntry,
      l10n.vaultNewItem,
      l10n.actionLockVault,
      l10n.navGenerator,
      l10n.navSettings,
      l10n.softwareUpdate,
    ]) {
      // Scope to the palette: the shell rail repeats some of these labels.
      expect(
        find.descendant(of: palette, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }

    await scrollPaletteToEntries(tester);
    expect(
      find.descendant(of: palette, matching: find.text('Alpha')),
      findsOneWidget,
    );
  });

  testWidgets('palette result navigates through the canonical route', (
    tester,
  ) async {
    final router = await pumpVault(tester, width: 1400);
    await sendCtrlK(tester);
    await scrollPaletteToEntries(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(QuickActionsSheet),
        matching: find.text('Alpha'),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vault/entry/e1');
    expect(find.byType(QuickActionsSheet), findsNothing);
    expect(find.byType(EntryDetailScreen), findsOneWidget);
  });

  testWidgets('dragging the divider persists the pane ratio', (tester) async {
    await pumpVault(tester, width: 1400, location: '/vault/entry/e1');
    final handle = find.byKey(const Key('vault-pane-resize-handle'));
    expect(handle, findsOneWidget);

    final before = tester.element(find.byType(VaultListPane)).size!.width;
    await tester.drag(handle, const Offset(120, 0));
    await tester.pumpAndSettle();
    final after = tester.element(find.byType(VaultListPane)).size!.width;

    expect(after, greaterThan(before));
    expect(AppPreferences.instance.vaultPaneRatio, greaterThan(0.34));
    expect(AppPreferences.instance.vaultPaneRatio, lessThanOrEqualTo(0.5));
  });

  testWidgets('RTL keeps the list pane at the reading start', (tester) async {
    await pumpVault(
      tester,
      width: 1400,
      location: '/vault/entry/e1',
      direction: TextDirection.rtl,
    );

    final list = tester.element(find.byType(VaultListPane)).size!;
    final detail = tester.element(find.byType(EntryDetailScreen)).size!;
    final listCenter = tester.getCenter(find.byType(VaultListPane));
    final detailCenter = tester.getCenter(find.byType(EntryDetailScreen));

    expect(list.width, greaterThan(300));
    expect(detail.width, greaterThan(300));
    expect(
      listCenter.dx,
      greaterThan(detailCenter.dx),
      reason: 'the list is physically on the right in RTL',
    );
  });

  testWidgets('200% text scale collapses the split panes', (tester) async {
    await pumpVault(
      tester,
      width: 1400,
      location: '/vault/entry/e1',
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byKey(const Key('vault-pane-resize-handle')), findsNothing);
    expect(find.byType(VaultListPane), findsNothing);
    expect(find.byType(EntryDetailScreen), findsOneWidget);
  });
}
