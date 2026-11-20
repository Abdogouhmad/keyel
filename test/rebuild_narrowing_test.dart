import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_widgets.dart';

/// A repository whose unlock never completes, so the notifier is left with
/// `busy: true` while `status` stays `locked` — exactly the unrelated change
/// the hot screens must ignore.
class _PendingUnlockRepository extends VaultRepository {
  final Completer<void> pending = Completer<void>();

  @override
  bool get vaultExists => true;

  @override
  Stream<String> lockEvents() => const Stream<String>.empty();

  @override
  Future<void> unlockWithMaster(String master) => pending.future;
}

void main() {
  testWidgets(
    'a busy-only session change does not rebuild a status-only subtree',
    (tester) async {
      final repository = _PendingUnlockRepository();
      final container = ProviderContainer(
        overrides: [vaultRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      var builds = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  builds++;
                  // Mirrors the narrowed watch used by SettingsScreen,
                  // VaultScreen and the other hot surfaces since 1.8.0.
                  final status = ref.watch(
                    vaultSessionProvider.select((state) => state.status),
                  );
                  return VaultProfileCard(status: status, vaultPath: '/vault');
                },
              ),
            ),
          ),
        ),
      );
      expect(builds, 1);

      // Flip only `busy`. A broad `ref.watch(vaultSessionProvider)` would rebuild
      // here; the field-level select must not.
      unawaited(
        container
            .read(vaultSessionProvider.notifier)
            .unlockWithMaster('master'),
      );
      await tester.pump();
      expect(
        builds,
        1,
        reason: 'an unrelated session field triggered a rebuild',
      );

      // A real status change must still rebuild.
      repository.pending.complete();
      await tester.pump();
      await tester.pump();
      expect(builds, greaterThan(1));
    },
  );
}
