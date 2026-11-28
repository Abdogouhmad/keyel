import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_revision_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/sync/local_network.dart';
import 'package:keyel/features/sync/sync_folder_service.dart';
import 'package:keyel/features/sync/sync_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

final _enabled = SyncStatusDto(
  enabled: true,
  syncId: 'a' * 32,
  deviceId: 'b' * 32,
  folderHint: '/tmp/keyel-sync',
  lastSyncAt: BigInt.from(1_760_000_000),
  sequence: BigInt.from(3),
);

final _disabled = SyncStatusDto(
  enabled: false,
  folderHint: '',
  lastSyncAt: BigInt.zero,
  sequence: BigInt.zero,
);

const _report = SyncReportDto(
  pulledFiles: 2,
  pushedFile: true,
  entriesAdded: 1,
  entriesUpdated: 1,
  foldersAdded: 0,
  foldersUpdated: 0,
  conflictsCreated: 1,
  tombstonesApplied: 0,
  errors: [],
);

/// A repository whose sync calls are recorded instead of hitting Rust.
class _FakeRepository extends VaultRepository {
  new({required this.status});

  SyncStatusDto status;

  String? enableFolder;
  String? joinCode;
  String? joinFolder;
  String? syncFolder;
  bool didDisable = false;
  bool didPairingCode = false;

  @override
  Future<SyncStatusDto> syncStatus() async => status;

  @override
  Future<String> syncEnable(String folderHint) async {
    enableFolder = folderHint;
    return 'KYSYNC1-TESTCODE';
  }

  @override
  Future<String> syncPairingCode() async {
    didPairingCode = true;
    return 'KYSYNC1-TESTCODE';
  }

  @override
  Future<SyncStatusDto> syncJoin(String code, String folderHint) async {
    joinCode = code;
    joinFolder = folderHint;
    return status = _enabled;
  }

  @override
  Future<void> syncDisable() async {
    didDisable = true;
    status = _disabled;
  }

  @override
  Future<SyncReportDto> syncNow(String folderPath) async {
    syncFolder = folderPath;
    return _report;
  }
}

class _FakeFolders implements SyncFolderService {
  const new();

  @override
  Future<String?> pickFolder() async => '/tmp/keyel-sync';

  @override
  Future<String> appSyncFolder() async => '/tmp/keyel-sync';
}

final class _FakeDiscovery implements LocalNetworkDiscovery {
  const new({this.peers = const []});

  final List<LocalNetworkPeer> peers;

  @override
  Future<List<LocalNetworkPeer>> discover({
    Duration timeout = kLocalNetworkDiscoveryTimeout,
  }) async => peers;

  @override
  Future<void> startPresence() => Future<void>.value();

  @override
  Future<void> stopPresence() => Future<void>.value();
}

Widget _host(
  Widget child, {
  required VaultRepository repository,
  LocalNetworkDiscovery? discovery,
  ProviderContainer? container,
}) {
  final app = MaterialApp(theme: KeyelTheme.light(), home: child);
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(
    overrides: [
      vaultRepositoryProvider.overrideWithValue(repository),
      syncFolderServiceProvider.overrideWithValue(const _FakeFolders()),
      if (discovery != null)
        localNetworkDiscoveryProvider.overrideWithValue(discovery),
    ],
    child: app,
  );
}

ProviderContainer _container(
  VaultRepository repository, {
  LocalNetworkDiscovery? discovery,
}) => ProviderContainer(
  overrides: [
    vaultRepositoryProvider.overrideWithValue(repository),
    syncFolderServiceProvider.overrideWithValue(const _FakeFolders()),
    if (discovery != null)
      localNetworkDiscoveryProvider.overrideWithValue(discovery),
  ],
);

void main() {
  testWidgets('disabled state offers enable and join', (tester) async {
    await tester.pumpWidget(
      _host(const SyncScreen(), repository: _FakeRepository(status: _disabled)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sync is off'), findsOneWidget);
    expect(find.text('Create a sync group'), findsOneWidget);
    expect(find.text('Or join an existing group'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);
  });

  testWidgets('enabled state shows status and actions', (tester) async {
    await tester.pumpWidget(
      _host(const SyncScreen(), repository: _FakeRepository(status: _enabled)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sync enabled'), findsOneWidget);
    expect(find.text('/tmp/keyel-sync'), findsOneWidget);
    expect(find.text('b' * 32), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Show pairing code'), findsOneWidget);
    expect(find.text('Disable sync'), findsOneWidget);
  });

  testWidgets('enabling picks a folder and shows the pairing code once', (
    tester,
  ) async {
    final repo = _FakeRepository(status: _disabled);
    await tester.pumpWidget(_host(const SyncScreen(), repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a sync group'));
    await tester.pumpAndSettle();

    expect(repo.enableFolder, '/tmp/keyel-sync');
    expect(find.text('Save this pairing code'), findsOneWidget);
    expect(find.text('KYSYNC1-TESTCODE'), findsOneWidget);

    // Done stays disabled until the user confirms they stored the code.
    final done = find.widgetWithText(FilledButton, 'Done');
    expect(tester.widget<FilledButton>(done).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<FilledButton>(done).onPressed, isNotNull);
  });

  testWidgets('nearby discovery lists peers without weakening pairing', (
    tester,
  ) async {
    final repo = _FakeRepository(status: _disabled);
    const discovery = _FakeDiscovery(
      peers: <LocalNetworkPeer>[
        LocalNetworkPeer(
          peerId: '1122334455667788',
          displayName: 'Laptop',
          address: '192.168.1.7',
          port: kLocalNetworkKeyelPort,
          isSameSubnet: true,
        ),
      ],
    );
    await tester.pumpWidget(
      _host(const SyncScreen(), repository: repo, discovery: discovery),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find nearby devices'));
    await tester.pumpAndSettle();

    expect(find.text('Laptop · 192.168.1.7'), findsOneWidget);
    // Selecting a peer is only a convenience: it must not join a group.
    expect(repo.joinCode, isNull);
    await tester.tap(find.text('Laptop · 192.168.1.7'));
    await tester.pump();
    expect(find.text('Selected nearby device'), findsOneWidget);
    expect(repo.joinCode, isNull);
    // The manual pairing field is still present and remains authoritative.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('joining records the pairing code and folder', (tester) async {
    // The discovery row makes this screen taller than the default test surface.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _FakeRepository(status: _disabled);
    await tester.pumpWidget(_host(const SyncScreen(), repository: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'KYSYNC1-OTHER');
    await tester.tap(find.text('Join group'));
    await tester.pumpAndSettle();

    // The first-run confirmation must be accepted before anything is stored.
    expect(repo.joinCode, isNull);
    expect(find.text('Join this sync group?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Join group'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.joinCode, 'KYSYNC1-OTHER');
    expect(repo.joinFolder, '/tmp/keyel-sync');
    expect(find.text('Sync enabled'), findsOneWidget);
  });

  testWidgets('sync now uses the stored folder and reports conflicts', (
    tester,
  ) async {
    final repo = _FakeRepository(status: _enabled);
    await tester.pumpWidget(_host(const SyncScreen(), repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();

    expect(repo.syncFolder, '/tmp/keyel-sync');
    expect(
      find.textContaining('Sync complete: 1 added, 1 updated, 1 conflict copy'),
      findsOneWidget,
    );
  });

  testWidgets('sync now refreshes vault views after a merge', (tester) async {
    final repo = _FakeRepository(status: _enabled);
    final container = _container(repo);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _host(const SyncScreen(), repository: repo, container: container),
    );
    await tester.pumpAndSettle();
    expect(container.read(vaultRevisionProvider), 0);

    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();

    expect(repo.syncFolder, '/tmp/keyel-sync');
    expect(container.read(vaultRevisionProvider), 1);
  });
}
