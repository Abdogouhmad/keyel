import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/vault/vault_list_callbacks.dart';
import 'package:keyel/features/vault/vault_list_controller.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Repository whose listEntries calls can be held open, so a slow response can
/// be completed after a newer one to prove stale results are discarded.
class _ControlledRepository extends VaultRepository {
  final calls = <String>[];
  final pending = <Completer<List<EntrySummaryDto>>>[];

  @override
  bool get isUnlocked => true;

  @override
  Future<List<EntrySummaryDto>> listEntries({
    String query = '',
    EntryKindDto? kind,
    bool? favorite,
    bool includeDeleted = false,
  }) {
    calls.add(query);
    final completer = Completer<List<EntrySummaryDto>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<List<FolderDto>> listFolders() async => const [];
}

/// Repository whose reads fail, used to prove load errors are kept in UI state.
class _FailingRepository extends VaultRepository {
  @override
  bool get isUnlocked => true;

  @override
  Future<List<EntrySummaryDto>> listEntries({
    String query = '',
    EntryKindDto? kind,
    bool? favorite,
    bool includeDeleted = false,
  }) => Future<List<EntrySummaryDto>>.error(StateError('disk unavailable'));

  @override
  Future<List<FolderDto>> listFolders() async => const [];
}

EntrySummaryDto _summary(String id, String title) => EntrySummaryDto(
  id: id,
  kind: EntryKindDto.login,
  title: title,
  subtitle: '',
  favorite: false,
  hasTotp: false,
);

void main() {
  late _ControlledRepository repository;
  late VaultListController controller;
  var rebuilds = 0;

  setUp(() {
    repository = _ControlledRepository();
    rebuilds = 0;
    controller = VaultListController(
      repository: repository,
      callbacks: VaultListCallbacks(
        rebuild: () => rebuilds++,
        notify: (_, {icon, actionLabel, onAction}) {},
        notifyError: (_) {},
        confirmDelete: (_) async => true,
        pickFolder: () async => null,
        copy: (_, _) {},
      ),
    );
  });

  tearDown(() => controller.dispose());

  test('search is debounced to one load for a burst of keystrokes', () {
    fakeAsync((async) {
      ['a', 'ab', 'abc'].forEach(controller.onSearchChanged);
      expect(controller.query, 'abc');
      expect(repository.calls, isEmpty, reason: 'no load before the debounce');

      async.elapse(VaultListController.searchDebounce);
      expect(repository.calls, ['abc']);

      async.elapse(const Duration(seconds: 1));
      expect(repository.calls, ['abc'], reason: 'no repeat loads');
    });
  });

  test('a stale listEntries response cannot overwrite a newer one', () async {
    final first = controller.load();
    await pumpMicrotasks();
    final second = controller.load();
    await pumpMicrotasks();
    expect(repository.pending, hasLength(2));

    // Newer load finishes first with one row.
    repository.pending[1].complete([_summary('new', 'new row')]);
    await second;
    await pumpMicrotasks();
    expect(controller.entries.map((e) => e.id), ['new']);

    // The older load finishes later with a different row: must be ignored.
    repository.pending[0].complete([_summary('old', 'old row')]);
    await first;
    await pumpMicrotasks();
    expect(controller.entries.map((e) => e.id), ['new']);
    expect(rebuilds, greaterThan(0));
  });

  test(
    'a failed load is exposed as inline error state, not an empty vault',
    () async {
      final failing = _FailingRepository();
      final failingController = VaultListController(
        repository: failing,
        callbacks: VaultListCallbacks(
          rebuild: () => rebuilds++,
          notify: (_, {icon, actionLabel, onAction}) {},
          notifyError: (_) {},
          confirmDelete: (_) async => true,
          pickFolder: () async => null,
          copy: (_, _) {},
        ),
      );
      addTearDown(failingController.dispose);

      await failingController.load();

      expect(failingController.loadError, isNotNull);
      expect(failingController.entries, isEmpty);
    },
  );

  test('selection pruning uses visible ids, not nested scans', () async {
    final load = controller.load();
    await pumpMicrotasks();
    repository.pending.first.complete([_summary('a', 'A'), _summary('b', 'B')]);
    await load;
    await pumpMicrotasks();

    controller
      ..startSelection('a')
      ..toggleSelection('gone') // stale id, pruned on the next load
      ..selectDetail('gone');

    final reload = controller.load();
    await pumpMicrotasks();
    repository.pending.last.complete([_summary('b', 'B')]);
    await reload;
    await pumpMicrotasks();

    expect(controller.selectedIds, isEmpty);
    expect(controller.selectedEntryId, 'b');
  });
}

Future<void> pumpMicrotasks() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
