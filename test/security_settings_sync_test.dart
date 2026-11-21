import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/security_settings_provider.dart';
import 'package:keyel/features/security_dashboard/widgets/security_posture_card.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

void main() {
  testWidgets('vault posture updates when auto-lock or clipboard changes', (
    tester,
  ) async {
    // Start from deterministic values; AppPreferences is a process singleton.
    AppPreferences.instance.autoLockDelay = const Duration(minutes: 1);
    AppPreferences.instance.clipboardClearSeconds = 30;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: KeyelTheme.light(),
          home: const Scaffold(body: SecurityPostureCardConnector()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('After 1 minute'), findsOneWidget);
    expect(find.text('30 seconds'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SecurityPostureCardConnector)),
    );

    container
        .read(securitySettingsProvider.notifier)
        .setAutoLockDelay(const Duration(minutes: 15));
    await tester.pump();
    expect(find.text('After 15 minutes'), findsOneWidget);
    expect(find.text('After 1 minute'), findsNothing);

    container
        .read(securitySettingsProvider.notifier)
        .setClipboardClearSeconds(0);
    await tester.pump();
    expect(find.text('On lock only'), findsOneWidget);
    expect(find.text('30 seconds'), findsNothing);
  });
}
