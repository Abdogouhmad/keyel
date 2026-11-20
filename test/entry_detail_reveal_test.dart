import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_detail_controller.dart';
import 'package:keyel/src/rust/api/models.dart';

class _FakeRepository extends VaultRepository {
  final Map<SecretFieldDto, String> secrets = {
    SecretFieldDto.loginPassword: 'password',
    SecretFieldDto.cardNumber: '4111111111111111',
    SecretFieldDto.cardCvv: '123',
    SecretFieldDto.noteContent: 'private note',
  };

  @override
  Future<String> revealField(String id, SecretFieldDto field) async =>
      secrets[field] ?? '';

  @override
  Future<String> revealCustomField(String id, String fieldId) async => 'custom';
}

void main() {
  late _FakeRepository repository;
  var rebuilds = 0;

  EntryDetailController controller() => EntryDetailController(
    entryId: 'entry',
    repository: repository,
    callbacks: EntryDetailCallbacks(
      rebuild: () => rebuilds++,
      notify: (_, {icon}) {},
      notifyError: (_) {},
      copy: (_, _) {},
      launchUrl: (_) async => true,
      confirmDelete: (_) async => true,
      pushEdit: (_) async {},
      closeEntry: () {},
    ),
  );

  setUp(() {
    repository = _FakeRepository();
    rebuilds = 0;
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
}
