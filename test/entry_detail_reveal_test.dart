import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_detail_controller.dart';
import 'package:keyel/src/rust/api/models.dart';

class _FakeRepository extends VaultRepository {
  /// When set, every reveal waits on this future (used for lock races).
  Future<String>? gatedReveal;

  final Map<SecretFieldDto, String> secrets = {
    SecretFieldDto.loginPassword: 'password',
    SecretFieldDto.cardNumber: '4111111111111111',
    SecretFieldDto.cardCvv: '123',
    SecretFieldDto.noteContent: 'private note',
    SecretFieldDto.entryNotes: 'attached recovery code',
  };

  @override
  Future<String> revealField(String id, SecretFieldDto field) async =>
      await gatedReveal ?? secrets[field] ?? '';

  @override
  Future<String> revealCustomField(String id, String fieldId) async => 'custom';
}

void main() {
  late _FakeRepository repository;
  var rebuilds = 0;
  final copiedValues = <String>[];

  EntryDetailController controller() => EntryDetailController(
    entryId: 'entry',
    repository: repository,
    callbacks: EntryDetailCallbacks(
      rebuild: () => rebuilds++,
      notify: (_, {icon}) {},
      notifyError: (_) {},
      copy: (value, _) => copiedValues.add(value),
      launchUrl: (_) async => true,
      confirmDelete: (_) async => true,
      pushEdit: (_) async {},
      closeEntry: () {},
    ),
  );

  setUp(() {
    repository = _FakeRepository();
    rebuilds = 0;
    copiedValues.clear();
  });

  test('card and note reveals auto-hide with the password timer', () {
    fakeAsync((async) {
      final detail = controller();

      unawaited(detail.toggleRevealCard());
      async.flushMicrotasks();
      expect(detail.revealedCardNumber, '4111111111111111');
      expect(detail.revealedCvv, '123');

      unawaited(detail.toggleRevealNote());
      async.flushMicrotasks();
      expect(detail.revealedNote, 'private note');

      async.elapse(const Duration(seconds: 15));

      expect(detail.revealedCardNumber, isNull);
      expect(detail.revealedCvv, isNull);
      expect(detail.revealedNote, isNull);
      detail.dispose();
    });
  });

  test('one timer hides every reveal kind', () {
    fakeAsync((async) {
      final detail = controller();

      unawaited(detail.toggleRevealPassword());
      async.flushMicrotasks();
      unawaited(detail.toggleRevealCard());
      async.flushMicrotasks();
      unawaited(detail.toggleRevealCustomField('field'));
      async.flushMicrotasks();

      expect(detail.revealedPassword, 'password');
      expect(detail.revealedCardNumber, isNotNull);
      expect(detail.revealedCustomFields, isNotEmpty);

      async.elapse(const Duration(seconds: 15));

      expect(detail.revealedPassword, isNull);
      expect(detail.revealedCardNumber, isNull);
      expect(detail.revealedCvv, isNull);
      expect(detail.revealedCustomFields, isEmpty);
      detail.dispose();
    });
  });

  test('hideAll clears reveals immediately on lock', () async {
    final detail = controller();
    await detail.toggleRevealPassword();
    await detail.toggleRevealCard();
    await detail.toggleRevealCustomField('field');

    expect(rebuilds, greaterThan(0));
    detail.hideAll();

    expect(detail.revealedPassword, isNull);
    expect(detail.revealedCardNumber, isNull);
    expect(detail.revealedCvv, isNull);
    expect(detail.revealedNote, isNull);
    expect(detail.revealedCustomFields, isEmpty);
    detail.dispose();
  });

  test(
    'attached notes are hidden until revealed and join the shared timer',
    () {
      fakeAsync((async) {
        final detail = controller();

        // Nothing is decrypted or rendered during a build.
        expect(detail.revealedEntryNotes, isNull);

        unawaited(detail.toggleRevealEntryNotes());
        async.flushMicrotasks();
        expect(detail.revealedEntryNotes, 'attached recovery code');

        // Revealing another secret refreshes the same deadline.
        unawaited(detail.toggleRevealPassword());
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 14));
        expect(detail.revealedEntryNotes, 'attached recovery code');

        unawaited(detail.toggleRevealCard());
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 14));
        expect(detail.revealedEntryNotes, isNotNull);

        async.elapse(const Duration(seconds: 15));
        expect(detail.revealedEntryNotes, isNull);
        expect(detail.revealedPassword, isNull);
        expect(detail.revealedCardNumber, isNull);
        detail.dispose();
      });
    },
  );

  test('hideAll also masks attached notes', () async {
    final detail = controller();
    await detail.toggleRevealEntryNotes();
    expect(detail.revealedEntryNotes, isNotNull);

    detail.hideAll();
    expect(detail.revealedEntryNotes, isNull);
    detail.dispose();
  });

  test('a reveal that completes after lock is discarded', () async {
    final gate = Completer<String>();
    repository.gatedReveal = gate.future;
    final detail = controller();

    final pending = detail.toggleRevealPassword();
    detail.hideAll();
    gate.complete('late password');
    await pending;

    expect(detail.revealedPassword, isNull);
    detail.dispose();
  });

  test(
    'a copy that completes after lock never reaches the clipboard',
    () async {
      final gate = Completer<String>();
      repository.gatedReveal = gate.future;
      final detail = controller();

      final pending = detail.copyPassword();
      detail.hideAll();
      gate.complete('late copy');
      await pending;

      expect(copiedValues, isEmpty);
      detail.dispose();
    },
  );
}
