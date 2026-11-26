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

/// Mirrors the real app: the banner wraps the routed app in
/// MaterialApp.builder, i.e. above the Navigator's Overlay.
Widget _builderHost({required VoidCallback onOpen}) => ProviderScope(
  overrides: [otaProvider.overrideWith(_AvailableOta.new)],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    builder: (context, child) => UpdateAvailableBanner(
      onOpen: onOpen,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const Scaffold(body: Text('page')),
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
    final semantics = tester.ensureSemantics();
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Dismiss update banner'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsNothing);
    expect(find.text('page'), findsOneWidget);
    expect(AppPreferences.instance.otaDismissedVersion, equals('1.9.0-beta.1'));
    semantics.dispose();
  });

  testWidgets('renders above the Navigator without an Overlay ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(_builderHost(onOpen: () {}));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    await tester.pump();

    // The banner used to put a Tooltip here, which asserts with
    // "No Overlay widget found" because MaterialApp.builder wraps the
    // Navigator. A semantics-labelled IconButton must stay usable instead.
    expect(tester.takeException(), isNull);
    expect(find.text('Update available'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Update available'), findsNothing);
    semantics.dispose();
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
