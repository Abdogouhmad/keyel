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
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

final _entries = [
  const EntrySummaryDto(
    id: 'alpha',
    kind: EntryKindDto.login,
    title: 'Alpha Bank',
    subtitle: 'ada@example.test',
    favorite: false,
    hasTotp: false,
  ),
  const EntrySummaryDto(
    id: 'beta',
    kind: EntryKindDto.login,
    title: 'Beta Mail',
    subtitle: 'ada@mail.test',
    favorite: false,
    hasTotp: false,
  ),
  const EntrySummaryDto(
    id: 'manager',
    kind: EntryKindDto.login,
    title: 'Account Manager',
    subtitle: 'ops@example.test',
    favorite: false,
    hasTotp: false,
  ),
];

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
  }) async => _entries;

  @override
  Future<List<FolderDto>> listFolders() async => const [];

  @override
  Future<EntryDetailDto> getEntry(String id) async => EntryDetailDto(
    id: id,
    kind: EntryKindDto.login,
    title: _entries.firstWhere((entry) => entry.id == id).title,
    tags: const [],
    favorite: false,
    createdAt: BigInt.zero,
    updatedAt: BigInt.zero,
    hasNotes: false,
    customFields: const [],
  );
}

class _SessionFake extends VaultSessionNotifier {
  @override
  VaultSessionState build() =>
      const VaultSessionState(status: VaultStatus.unlocked);
}

class _InitialRouteFake extends InitialRouteNotifier {
  @override
  String build() => KeyelRoutes.vault;
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

void main() {
  setUp(() {
    quickActionsOpen.value = false;
    AppPreferences.instance.recentQuickActionIds = const [];
  });

  tearDown(() {
    quickActionsOpen.value = false;
    AppPreferences.instance.recentQuickActionIds = const [];
  });

  Future<GoRouter> pumpVault(
    WidgetTester tester, {
    double width = 1400,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        vaultRepositoryProvider.overrideWithValue(_RepositoryFake()),
        vaultSessionProvider.overrideWith(_SessionFake.new),
        initialRouteProvider.overrideWith(_InitialRouteFake.new),
      ],
    );
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
    return await Future.value(container.read(appRouterProvider));
  }

  Future<void> openPalette(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
    expect(find.byType(QuickActionsSheet), findsOneWidget);
  }

  Future<void> typeQuery(WidgetTester tester, String query) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(QuickActionsSheet),
        matching: find.byType(TextField),
      ),
      query,
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendDown(WidgetTester tester, int count) async {
    for (var index = 0; index < count; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
  }

  Future<void> scrollPaletteToEntries(WidgetTester tester) async {
    final list = find.descendant(
      of: find.byType(QuickActionsSheet),
      matching: find.byType(ListView),
    );
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
  }

  Finder tileWithText(String text) => find.ancestor(
    of: find.descendant(
      of: find.byType(QuickActionsSheet),
      matching: find.text(text),
    ),
    matching: find.byType(ListTile),
  );

  testWidgets('fuzzy token finds an entry a substring query would miss', (
    tester,
  ) async {
    await pumpVault(tester);
    await openPalette(tester);
    await typeQuery(tester, 'atm');

    final palette = find.byType(QuickActionsSheet);
    expect(
      find.descendant(of: palette, matching: find.text('Account Manager')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: palette, matching: find.text('Alpha Bank')),
      findsNothing,
    );
  });

  testWidgets('arrow keys move the selection and Enter opens the entry', (
    tester,
  ) async {
    final router = await pumpVault(tester);
    await openPalette(tester);

    // Six static actions precede the entries in the unfiltered palette.
    await sendDown(tester, 6);
    expect(
      tester.widget<ListTile>(tileWithText('Alpha Bank')).selected,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vault/entry/alpha');
    expect(find.byType(QuickActionsSheet), findsNothing);
    expect(find.byType(EntryDetailScreen), findsOneWidget);
  });

  testWidgets('opening an entry remembers it for the next palette', (
    tester,
  ) async {
    final router = await pumpVault(tester);
    await openPalette(tester);
    await typeQuery(tester, 'beta');
    await tester.tap(tileWithText('Beta Mail'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/vault/entry/beta');

    await openPalette(tester);
    expect(AppPreferences.instance.recentQuickActionIds, ['beta']);
    await scrollPaletteToEntries(tester);
    expect(
      tester.getCenter(tileWithText('Beta Mail')).dy,
      lessThan(tester.getCenter(tileWithText('Alpha Bank')).dy),
    );
  });

  testWidgets('palette stays usable in RTL at 200% text scale', (tester) async {
    final router = await pumpVault(
      tester,
      width: 900,
      textScaler: const TextScaler.linear(2),
      direction: TextDirection.rtl,
    );
    await openPalette(tester);

    expect(
      find.descendant(
        of: find.byType(QuickActionsSheet),
        matching: find.text(
          l10nOf(tester.element(find.byType(QuickActionsSheet)))
              .quickActionsKeyboardHint,
        ),
      ),
      findsOneWidget,
    );

    await sendDown(tester, 6);
    expect(
      tester.widget<ListTile>(tileWithText('Alpha Bank')).selected,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/vault/entry/alpha');
    expect(tester.takeException(), isNull);
  });
}
