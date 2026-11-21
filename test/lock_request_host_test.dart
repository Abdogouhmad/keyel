import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/platform/launch_action.dart';
import 'package:keyel/core/platform/lock_request.dart';
import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/security/lock_request_host.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';

class _LockingRepository extends VaultRepository {
  new() : super();

  bool locked = false;

  @override
  bool get vaultExists => true;

  @override
  bool get isUnlocked => !locked;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  void lock() => locked = true;
}

class _FakeBridge extends LockRequestBridge {
  new() : super(_noop);

  static void _noop() {}

  VoidCallback? callback;

  @override
  void register() {}

  @override
  void unregister() {}

  void fire() => callback?.call();
}

void main() {
  testWidgets('a native lock request locks the vault', (tester) async {
    final repository = _LockingRepository();
    final bridge = _FakeBridge();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultRepositoryProvider.overrideWithValue(repository),
          clipboardWipeProvider.overrideWithValue(() async {}),
          initialLaunchActionProvider.overrideWithValue(() async => null),
          lockRequestBridgeProvider.overrideWithValue(
            (callback) => bridge..callback = callback,
          ),
        ],
        child: const LockRequestHost(child: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.locked, isFalse);
    bridge.fire();
    await tester.pumpAndSettle();
    expect(repository.locked, isTrue);
  });

  testWidgets('a pending lock action is consumed on mount', (tester) async {
    final repository = _LockingRepository();
    final bridge = _FakeBridge();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultRepositoryProvider.overrideWithValue(repository),
          clipboardWipeProvider.overrideWithValue(() async {}),
          initialLaunchActionProvider.overrideWithValue(
            () async => lockLaunchAction,
          ),
          lockRequestBridgeProvider.overrideWithValue(
            (callback) => bridge..callback = callback,
          ),
        ],
        child: const LockRequestHost(child: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.locked, isTrue);
  });
}
