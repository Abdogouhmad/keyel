import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/ota/ota_check_host.dart';
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/data/app_preferences.dart';

class _RecordingOta extends OtaNotifier {
  int checks = 0;
  bool? lastUserInitiated;
  int prompts = 0;

  @override
  OtaState build() => const OtaState(currentVersion: '1.8.2');

  @override
  Future<void> maybePromptForNotifications() async {
    prompts++;
  }

  @override
  Future<void> checkForUpdates({bool userInitiated = true}) async {
    checks++;
    lastUserInitiated = userInitiated;
    state = state.copyWith(lastChecked: DateTime.now);
  }
}

void main() {
  setUp(() {
    AppPreferences.instance.otaLastCheckedMs = null;
  });

  testWidgets('checks silently on mount', (tester) async {
    final container = ProviderContainer(
      overrides: [otaProvider.overrideWith(_RecordingOta.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const OtaCheckHost(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();

    final recorder = container.read(otaProvider.notifier) as _RecordingOta;
    expect(recorder.checks, equals(1));
    expect(recorder.lastUserInitiated, isFalse);
    expect(recorder.prompts, equals(1));
  });

  testWidgets('does not check again inside the throttle window', (
    tester,
  ) async {
    AppPreferences.instance.otaLastCheckedMs =
        DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(
      overrides: [otaProvider.overrideWith(_RecordingOta.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const OtaCheckHost(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();

    final recorder = container.read(otaProvider.notifier) as _RecordingOta;
    expect(recorder.checks, isZero);
  });
}
