import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_detail_controller.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/src/rust/api/error.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

class _ResultRepository extends VaultRepository {
  new(this.error);

  final Object? error;

  @override
  Future<EntryDetailDto> getEntry(String id) => error == null
      ? Future.value(_detail)
      : Future<EntryDetailDto>.error(error!);

  @override
  Future<List<FolderDto>> listFolders() async => const [];
}

final EntryDetailDto _detail = EntryDetailDto(
  id: 'entry',
  kind: EntryKindDto.login,
  title: 'Example',
  tags: const [],
  favorite: false,
  createdAt: BigInt.zero,
  updatedAt: BigInt.zero,
  hasNotes: false,
  customFields: const [],
);

EntryDetailController _controller(VaultRepository repository) =>
    EntryDetailController(
      entryId: 'entry',
      repository: repository,
      callbacks: EntryDetailCallbacks(
        rebuild: () {},
        notify: (_, {icon}) {},
        notifyError: (_) {},
        copy: (_, _) {},
        launchUrl: (_) async => true,
        confirmDelete: (_) async => true,
        pushEdit: (_) async {},
        closeEntry: () {},
      ),
    );

Widget _host(VaultRepository repository) => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: const EntryDetailScreen(entryId: 'entry'),
  ),
);

void main() {
  test('notFound is a missing entry, not a load error', () async {
    final controller = _controller(_ResultRepository(VaultApiError.notFound));
    await controller.load();

    expect(controller.missing, isTrue);
    expect(controller.loadError, isNull);
    expect(controller.entry, isNull);
  });

  test('a repository failure is a load error, not a missing entry', () async {
    final controller = _controller(_ResultRepository(StateError('disk gone')));
    await controller.load();

    expect(controller.loadError, contains('disk gone'));
    expect(controller.missing, isFalse);
  });

  testWidgets('a real missing id renders not-found, not retry', (tester) async {
    await tester.pumpWidget(_host(_ResultRepository(VaultApiError.notFound)));
    await tester.pumpAndSettle();

    expect(find.textContaining('No entry with ID'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a failed load renders an inline retry', (tester) async {
    await tester.pumpWidget(_host(_ResultRepository(StateError('disk gone'))));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('No entry with ID'), findsNothing);
  });
}
