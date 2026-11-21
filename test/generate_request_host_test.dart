import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/generate_request.dart';
import 'package:keyel/core/platform/launch_action.dart';
import 'package:keyel/core/quickaccess/generate_request_host.dart';
import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/core/router/keyel_routes.dart';

/// Fake native bridge so the test can fire a warm launch request.
class _FakeBridge extends GenerateRequestBridge {
  new() : super();

  VoidCallback? callback;

  @override
  void register() {}

  @override
  void unregister() {}

  void fire() => callback?.call();
}

GoRouter _router() => GoRouter(
  initialLocation: KeyelRoutes.vault,
  routes: [
    GoRoute(
      path: KeyelRoutes.vault,
      builder: (context, state) => const Scaffold(body: Text('vault')),
    ),
    GoRoute(
      path: KeyelRoutes.generator,
      builder: (context, state) => const Scaffold(body: Text('generator')),
    ),
  ],
);

Widget _host(
  GoRouter router,
  _FakeBridge bridge, {
  String? initialAction,
}) => ProviderScope(
  overrides: [
    appRouterProvider.overrideWithValue(router),
    initialLaunchActionProvider.overrideWithValue(() async => initialAction),
    generateRequestBridgeProvider.overrideWithValue(
      (callback) => bridge..callback = callback,
    ),
  ],
  child: GenerateRequestHost(child: MaterialApp.router(routerConfig: router)),
);

void main() {
  testWidgets('a warm generate request opens the generator', (tester) async {
    final router = _router();
    final bridge = _FakeBridge();
    await tester.pumpWidget(_host(router, bridge));

    expect(find.text('vault'), findsOneWidget);
    expect(find.text('generator'), findsNothing);

    bridge.fire();
    await tester.pumpAndSettle();

    expect(find.text('generator'), findsOneWidget);
  });

  testWidgets('a pending generate action opens the generator on mount', (
    tester,
  ) async {
    final router = _router();
    final bridge = _FakeBridge();
    await tester.pumpWidget(
      _host(router, bridge, initialAction: generateLaunchAction),
    );
    await tester.pumpAndSettle();

    expect(find.text('generator'), findsOneWidget);
  });
}
