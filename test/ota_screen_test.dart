import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/features/ota/ota_screen.dart';
import 'package:keyel/ui/keyel.dart';

class _IdleOta extends OtaNotifier {
  @override
  OtaState build() => const OtaState(currentVersion: '1.9.0');
}

Widget _host({bool disableAnimations = false}) => ProviderScope(
  overrides: [otaProvider.overrideWith(_IdleOta.new)],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: const OtaScreen(),
      ),
    ),
  ),
);

void main() {
  testWidgets('uses the shared top bar with a Back action and refresh', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byType(KeyelTopBar), findsOneWidget);
    expect(find.text('Software Update'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Check for updates'), findsOneWidget);
  });

  testWidgets('fits at 200% text scale and respects reduced motion', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Check for updates'), findsOneWidget);
  });
}
