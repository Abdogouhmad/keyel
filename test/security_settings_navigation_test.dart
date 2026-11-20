import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/security_dashboard/widgets/security_posture_card.dart';
import 'package:keyel/features/settings/settings_screen.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

class _FakeRepository extends VaultRepository {
  @override
  String? get vaultPath => '/tmp/keyel-test/vault.keyel';
}

Widget _host(GoRouter router) => ProviderScope(
  overrides: [vaultRepositoryProvider.overrideWithValue(_FakeRepository())],
  child: MaterialApp.router(theme: KeyelTheme.light(), routerConfig: router),
);

void main() {
  testWidgets('Review settings goes to the settings tab with a return marker', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: KeyelRoutes.security,
      routes: [
        GoRoute(
          path: KeyelRoutes.security,
          builder: (context, state) =>
              const Scaffold(body: SecurityPostureCardConnector()),
        ),
        GoRoute(
          path: KeyelRoutes.settings,
          builder: (context, state) => Scaffold(
            body: Text('arrived:${state.uri.queryParameters['from']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review settings'));
    await tester.pumpAndSettle();

    expect(find.text('arrived:security'), findsOneWidget);
  });

  testWidgets('Settings offers an explicit back arrow to Security', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '${KeyelRoutes.settings}?from=security',
      routes: [
        GoRoute(
          path: KeyelRoutes.security,
          builder: (context, state) =>
              const Scaffold(body: Text('back at security')),
        ),
        GoRoute(
          path: KeyelRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    final back = find.byIcon(Icons.arrow_back_rounded);
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('back at security'), findsOneWidget);
  });
}
