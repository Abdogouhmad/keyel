import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/security/unlock_throttle.dart';
import 'package:keyel/data/app_preferences.dart';
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

class _LockingRepository extends _FakeRepository {
  new() : super(unlocked: true);

  bool locked = false;

  @override
  bool get isUnlocked => !locked;

  @override
  void lock() => locked = true;
}

/// A repository whose master-password unlock always fails until told otherwise.
class _UnlockRepository extends _FakeRepository {
  new();

  /// When true, [unlockWithMaster] fails with `wrongPassword`.
  bool wrongPassword = true;

  /// How many times the real unlock was attempted (throttled calls do not
  /// reach the repository).
  int unlockCalls = 0;

  @override
  Future<void> unlockWithMaster(String master) {
    unlockCalls += 1;
    if (wrongPassword) {
      return Future<void>.error(VaultApiError.wrongPassword);
    }
    return Future<void>.value();
  }
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
    expect(container.read(vaultSessionProvider).status, VaultStatus.locked);
  });

  test('an unlocked Rust session resolves to unlocked', () {
    final container = _container(_FakeRepository(unlocked: true));

    expect(container.read(vaultSessionProvider).status, VaultStatus.unlocked);
  });

  test('a missing vault resolves to noVault', () {
    final container = _container(_FakeRepository(exists: false));

    expect(container.read(vaultSessionProvider).status, VaultStatus.noVault);
  });

  test('a VaultExists error switches the UI to the unlock state', () async {
    final container = _container(_FakeRepository());
    final notifier = container.read(vaultSessionProvider.notifier);

    await expectLater(
      notifier.create('master password'),
      throwsA(isA<VaultApiError>()),
    );
    expect(container.read(vaultSessionProvider).status, VaultStatus.locked);
  });

  test('an immediate auto-lock locks as soon as the app backgrounds', () {
    final repository = _LockingRepository();
    final container = _container(repository);
    final notifier = container.read(vaultSessionProvider.notifier);
    addTearDown(() {
      AppPreferences.instance.autoLockDelay = const Duration(minutes: 1);
    });

    notifier
      ..setAutoLockDelay(Duration.zero)
      ..onAppBackgrounded();

    expect(repository.locked, isTrue);
    expect(container.read(vaultSessionProvider).status, VaultStatus.locked);
  });

  group('unlock throttle', () {
    setUp(() {
      AppPreferences.instance
        ..unlockFailures = 0
        ..unlockLockedUntilMs = null
        ..biometricEnabled = false;
    });

    test('wrong passwords are counted and persisted', () async {
      final repository = _UnlockRepository();
      final container = _container(repository);
      final notifier = container.read(vaultSessionProvider.notifier);

      for (var i = 0; i < 4; i++) {
        await expectLater(
          notifier.unlockWithMaster('nope'),
          throwsA(isA<VaultApiError>()),
        );
      }

      expect(repository.unlockCalls, 4);
      expect(notifier.isUnlockThrottled, isTrue);
      expect(notifier.unlockDelayRemaining, greaterThan(Duration.zero));
      expect(AppPreferences.instance.unlockFailures, 4);
      expect(AppPreferences.instance.unlockLockedUntilMs, isNotNull);
    });

    test('a restored deadline refuses attempts before they reach Rust',
        () async {
      AppPreferences.instance
        ..unlockFailures = 4
        ..unlockLockedUntilMs = DateTime.now()
            .add(const Duration(minutes: 1))
            .millisecondsSinceEpoch;
      final repository = _UnlockRepository();
      final container = _container(repository);
      final notifier = container.read(vaultSessionProvider.notifier);

      expect(notifier.isUnlockThrottled, isTrue);
      expect(notifier.unlockDelayRemaining, greaterThan(Duration.zero));
      await expectLater(
        notifier.unlockWithMaster('nope'),
        throwsA(isA<UnlockThrottledException>()),
      );
      expect(repository.unlockCalls, 0);
    });

    test('a successful unlock clears the failure count', () async {
      final repository = _UnlockRepository();
      final container = _container(repository);
      final notifier = container.read(vaultSessionProvider.notifier);

      for (var i = 0; i < 2; i++) {
        await expectLater(
          notifier.unlockWithMaster('nope'),
          throwsA(isA<VaultApiError>()),
        );
      }
      expect(AppPreferences.instance.unlockFailures, 2);

      repository.wrongPassword = false;
      await notifier.unlockWithMaster('right');

      expect(notifier.isUnlockThrottled, isFalse);
      expect(AppPreferences.instance.unlockFailures, 0);
      expect(AppPreferences.instance.unlockLockedUntilMs, isNull);
      expect(container.read(vaultSessionProvider).status, VaultStatus.unlocked);
    });
  });
}
