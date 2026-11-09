import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/error.dart';

class _FakeRepository extends VaultRepository {
  new({this.exists = true, this.unlocked = false});

  final bool exists;
  final bool unlocked;

  @override
  bool get vaultExists => exists;

  @override
  bool get isUnlocked => unlocked;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<String> createVault(String master) =>
      Future<String>.error(VaultApiError.vaultExists);
}

ProviderContainer _container(_FakeRepository repository) {
  final container = ProviderContainer(
    overrides: [vaultRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('an existing vault resolves to locked on first read', () {
    final container = _container(_FakeRepository());

    // Regression: build() used to return `noVault` and overwrite the async
    // refresh, so every cold start offered "create vault" and then failed
    // with VaultExists.
    expect(
      container.read(vaultSessionProvider).status,
      VaultStatus.locked,
    );
  });

  test('an unlocked Rust session resolves to unlocked', () {
    final container = _container(_FakeRepository(unlocked: true));

    expect(
      container.read(vaultSessionProvider).status,
      VaultStatus.unlocked,
    );
  });

  test('a missing vault resolves to noVault', () {
    final container = _container(_FakeRepository(exists: false));

    expect(
      container.read(vaultSessionProvider).status,
      VaultStatus.noVault,
    );
  });

  test('a VaultExists error switches the UI to the unlock state', () async {
    final container = _container(_FakeRepository());
    final notifier = container.read(vaultSessionProvider.notifier);

    await expectLater(
      notifier.create('master password'),
      throwsA(isA<VaultApiError>()),
    );
    expect(
      container.read(vaultSessionProvider).status,
      VaultStatus.locked,
    );
  });
}
