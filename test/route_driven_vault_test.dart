import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/vault/vault_screen.dart';
import 'package:keyel/features/vault/widgets/vault_list_pane.dart';
import 'package:keyel/src/rust/api/models.dart';
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

class _VaultRepositoryFake extends VaultRepository {
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

class _InitialRouteFake extends InitialRouteNotifier {
  new(this.location);

  final String location;

  @override
  String build() => location;
}

class _SessionFake extends VaultSessionNotifier {
  new(this._status);

  VaultStatus _status;

  @override
  VaultSessionState build() => VaultSessionState(status: _status);

  void setStatus(VaultStatus status) {
    _status = status;
    state = VaultSessionState(status: status);
  }
}

Future<void> _surface(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host(ProviderContainer container, double width) =>
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: MaterialApp.router(
          theme: KeyelTheme.light(),
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );

ProviderContainer _container(String initialLocation, _SessionFake session) =>
    ProviderContainer(
      overrides: [
        vaultRepositoryProvider.overrideWithValue(_VaultRepositoryFake()),
        vaultSessionProvider.overrideWith(() => session),
        initialRouteProvider.overrideWith(
          () => _InitialRouteFake(initialLocation),
        ),
      ],
    );

void main() {
  testWidgets('canonical route renders full-screen detail on a phone', (
    tester,
  ) async {
    const width = 400.0;
    await _surface(tester, width);
    final container = _container(
      '/vault/entry/e1',
      _SessionFake(VaultStatus.unlocked),
    );
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, width));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vault/entry/e1');
    expect(find.byType(EntryDetailScreen), findsOneWidget);
    expect(find.byType(VaultListPane), findsNothing);
  });

  testWidgets('canonical route renders a master/detail pair on a wide window', (
    tester,
  ) async {
    const width = 1400.0;
    await _surface(tester, width);
    final container = _container(
      '/vault/entry/e1',
      _SessionFake(VaultStatus.unlocked),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, width));
    await tester.pumpAndSettle();

    expect(find.byType(VaultScreen), findsOneWidget);
    expect(find.byType(VaultListPane), findsOneWidget);
    expect(find.byType(EntryDetailScreen), findsOneWidget);
  });

  testWidgets('selecting a row updates the URL instead of local-only state', (
    tester,
  ) async {
    const width = 1400.0;
    await _surface(tester, width);
    final container = _container('/vault', _SessionFake(VaultStatus.unlocked));
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, width));
    await tester.pumpAndSettle();
    expect(find.byType(EntryDetailScreen), findsNothing);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vault/entry/e1');
    expect(find.byType(EntryDetailScreen), findsOneWidget);
  });

  testWidgets('legacy entry link canonicalises to the vault route', (
    tester,
  ) async {
    const width = 400.0;
    await _surface(tester, width);
    final container = _container(
      '/entry/e1',
      _SessionFake(VaultStatus.unlocked),
    );
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, width));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vault/entry/e1');
  });

  testWidgets('locked deep link resumes at the requested entry after unlock', (
    tester,
  ) async {
    const width = 400.0;
    await _surface(tester, width);
    final session = _SessionFake(VaultStatus.locked);
    final container = _container('/vault/entry/e1', session);
    final router = container.read(appRouterProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, width));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/unlock');
    expect(router.state.uri.queryParameters['from'], '/vault/entry/e1');

    session.setStatus(VaultStatus.unlocked);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/vault/entry/e1');
    expect(find.byType(EntryDetailScreen), findsOneWidget);
  });

  test('unlock helper encodes the original location', () {
    final route = KeyelRoutes.unlockFor('/vault/entry/abc?x=1');
    final uri = Uri.parse(route);
    expect(uri.path, '/unlock');
    expect(uri.queryParameters['from'], '/vault/entry/abc?x=1');
  });
}
