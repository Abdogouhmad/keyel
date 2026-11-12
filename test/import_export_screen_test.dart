import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/import_export/import_export_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

const _preview = ImportPreviewDto(
  format: ImportFormatDto.bitwarden,
  total: 3,
  logins: 2,
  cards: 1,
  notes: 0,
  failures: [],
);

const _report = ImportReportDto(
  added: 3,
  skipped: 0,
  failed: 0,
  logins: 2,
  cards: 1,
  notes: 0,
  foldersAdded: 0,
  failures: [],
);

/// A repository whose import/export calls are recorded instead of hitting Rust.
class _FakeRepository extends VaultRepository {
  new();

  ImportModeDto? lastMode;
  String? lastPath;
  String? lastPassword;

  @override
  bool get vaultExists => true;

  @override
  bool get isUnlocked => true;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<ImportPreviewDto> previewImport(String path) async => _preview;

  @override
  Future<ImportReportDto> importCsv(String path, ImportModeDto mode) async {
    lastPath = path;
    lastMode = mode;
    return _report;
  }

  @override
  Future<void> exportBackup({
    required String path,
    required String password,
  }) async {
    lastPath = path;
    lastPassword = password;
  }

  @override
  Future<void> exportCsv(String path) async {
    lastPath = path;
  }

  @override
  Future<ImportReportDto> importBackup({
    required String path,
    required String password,
    required ImportModeDto mode,
  }) async {
    lastPath = path;
    lastPassword = password;
    lastMode = mode;
    return _report;
  }
}

/// An in-memory file transfer service: no picker, no share sheet, no disk.
class _FakeFiles implements FileTransferService {
  new({this.picked});

  PickedFile? picked;
  final List<String> shared = [];
  final List<String> deleted = [];
  bool cleared = false;

  @override
  Future<PickedFile?> pickFile({String? dialogTitle}) async => picked;

  @override
  Future<String> temporaryFilePath(String fileName) async =>
      '/tmp/keyel-export/$fileName';

  @override
  Future<void> clearTemporaryExports() async => cleared = true;

  @override
  Future<void> shareFile(String path, {String? subject}) async =>
      shared.add(path);

  @override
  Future<void> deleteFile(String path) async => deleted.add(path);
}

Widget _host(_FakeRepository repository, _FakeFiles files) => ProviderScope(
  overrides: [
    vaultRepositoryProvider.overrideWithValue(repository),
    fileTransferServiceProvider.overrideWithValue(files),
  ],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: const ImportExportScreen(),
  ),
);

void main() {
  testWidgets('hub lists every backup and CSV action', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_FakeRepository(), _FakeFiles()));
    await tester.pumpAndSettle();

    expect(find.text('Export encrypted backup'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
    expect(find.text('Import from CSV'), findsOneWidget);
    expect(find.text('Export as plain CSV'), findsOneWidget);
  });

  testWidgets('unencrypted CSV export asks for confirmation first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final files = _FakeFiles();
    await tester.pumpWidget(_host(_FakeRepository(), files));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export as plain CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Export unencrypted CSV?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(files.cleared, isFalse);
  });

  testWidgets('CSV export writes, shares and cleans up the temp file', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    final files = _FakeFiles();
    await tester.pumpWidget(_host(repository, files));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export as plain CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export unencrypted'));
    await tester.pumpAndSettle();

    expect(files.cleared, isTrue);
    expect(repository.lastPath, startsWith('/tmp/keyel-export/keyel-export-'));
    expect(find.text('CSV exported'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(files.shared, hasLength(1));

    // Disposing the screen removes the plaintext file.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(files.deleted, contains(repository.lastPath));
  });

  testWidgets('encrypted backup requires a matching password', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    final files = _FakeFiles();
    await tester.pumpWidget(_host(repository, files));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export encrypted backup'));
    await tester.pumpAndSettle();

    expect(find.text('Encrypt backup'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'short');
    await tester.pumpAndSettle();
    // Too short: the CTA stays disabled and nothing is written.
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
    expect(repository.lastPath, isNull);

    await tester.enterText(fields.at(0), 'correct horse battery');
    await tester.enterText(fields.at(1), 'correct horse battery');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();

    expect(repository.lastPassword, 'correct horse battery');
    expect(find.text('Backup created'), findsOneWidget);
  });

  testWidgets('CSV import previews, then applies with the chosen mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    final files = _FakeFiles(
      picked: const PickedFile(path: '/tmp/site.csv', name: 'site.csv'),
    );
    await tester.pumpWidget(_host(repository, files));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import from CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Import Bitwarden CSV'), findsOneWidget);
    expect(find.text('site.csv'), findsOneWidget);
    expect(find.text('Logins'), findsOneWidget);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import 3 entries'));
    await tester.pumpAndSettle();

    expect(repository.lastPath, '/tmp/site.csv');
    expect(repository.lastMode, ImportModeDto.replace);
    expect(find.text('Import complete'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
  });
}
