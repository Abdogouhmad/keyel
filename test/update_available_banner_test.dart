import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/features/ota/widgets/update_available_banner.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

final _release = OtaRelease(
  version: '1.9.0-beta.1',
  tagName: 'v1.9.0-beta.1',
  title: 'Keyel 1.9.0-beta.1',
  releaseNotes: 'Beta preview',
  publishedAt: DateTime(2026, 11, 20),
  downloadUrl: 'https://example.com/app.apk',
  fileName: 'app.apk',
  fileSize: 1000,
  isPrerelease: true,
);

class _AvailableOta extends OtaNotifier {
  @override
  OtaState build() => OtaState(
    currentVersion: '1.8.2',
    step: OtaStep.available,
    availableRelease: _release,
    channel: OtaChannel.beta,
    dismissedVersion: AppPreferences.instance.otaDismissedVersion,
  );
}

Widget _host({required VoidCallback onOpen, bool disableAnimations = false}) =>
    ProviderScope(
      overrides: [otaProvider.overrideWith(_AvailableOta.new)],
      child: MaterialApp(
        theme: KeyelTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: UpdateAvailableBanner(
              onOpen: onOpen,
              child: const Text('page'),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    AppPreferences.instance.otaDismissedVersion = null;
  });

  testWidgets('banner announces the update and opens the OTA screen', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(_host(onOpen: () => opens++));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.textContaining('Keyel v1.9.0-beta.1'), findsOneWidget);
    expect(find.textContaining('Beta channel'), findsOneWidget);

    await tester.tap(find.text('Update available'));
    expect(opens, 1);
  });

  testWidgets('dismissing hides only this version', (tester) async {
    await tester.pumpWidget(_host(onOpen: () {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dismiss update banner'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsNothing);
    expect(find.text('page'), findsOneWidget);
    expect(AppPreferences.instance.otaDismissedVersion, equals('1.9.0-beta.1'));
  });

  testWidgets('fits at 200% text scale and respects reduced motion', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_host(onOpen: () {}, disableAnimations: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Update available'), findsOneWidget);
    for (final size in tester.widgetList<AnimatedSize>(
      find.byType(AnimatedSize),
    )) {
      expect(size.duration, Duration.zero);
    }
  });
}
