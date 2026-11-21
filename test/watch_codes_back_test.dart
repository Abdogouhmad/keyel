import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/wear/watch_codes_screen.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

class _FakeRepository extends VaultRepository {
  @override
  String? get vaultPath => '/tmp/keyel-test/vault.keyel';

  @override
  Future<List<EntrySummaryDto>> listEntries({
    String query = '',
    EntryKindDto? kind,
    bool? favorite,
    bool includeDeleted = false,
  }) async => const [];
}

Widget _host(GoRouter router) => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(_FakeRepository())],
  child: MaterialApp.router(theme: KeyelTheme.light(), routerConfig: router),
);

void main() {
  testWidgets('Wear OS screen offers a back arrow to Settings', (tester) async {
    final router = GoRouter(
      initialLocation: KeyelRoutes.settings,
      routes: [
        GoRoute(
          path: KeyelRoutes.settings,
          builder: (context, state) =>
              const Scaffold(body: Text('back at settings')),
        ),
        GoRoute(
          path: KeyelRoutes.watchCodes,
          builder: (context, state) => const WatchCodesScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    // Enter the sub-page the way the settings row does, so a back stack exists.
    // `push` completes only when popped, so do not await it here.
    unawaited(router.push(KeyelRoutes.watchCodes));
    // The watch screen shows an indeterminate progress indicator while it
    // loads, so pump a bounded number of frames instead of pumpAndSettle.
    await tester.pump();
    await tester.pump();

    final back = find.byIcon(Icons.arrow_back_rounded);
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('back at settings'), findsOneWidget);
  });
}
