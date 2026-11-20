import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/security/screenshot_protection_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_sections.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

Widget _section({
  required bool screenshotProtection,
  required ValueChanged<bool> onScreenshotProtectionChanged,
}) => MaterialApp(
  theme: KeyelTheme.light(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: SettingsSecuritySection(
        status: VaultStatus.unlocked,
        biometricBusy: false,
        biometricEnabled: false,
        autoLockDelay: const Duration(minutes: 1),
        clipboardSeconds: 30,
        screenshotProtection: screenshotProtection,
        onLockNow: () {},
        onChangeMaster: () {},
        onAutoLock: () {},
        onToggleBiometric: (_) {},
        onClipboard: () {},
        onScreenshotProtectionChanged: onScreenshotProtectionChanged,
      ),
    ),
  ),
);

void main() {
  final prefs = AppPreferences.instance;

  setUp(() => prefs.screenshotProtection = true);
  tearDown(() => prefs.screenshotProtection = true);

  test('lock and unlock screens always block screenshots', () {
    expect(
      shouldBlockScreenshots(status: VaultStatus.locked, enabled: false),
      isTrue,
    );
    expect(
      shouldBlockScreenshots(status: VaultStatus.noVault, enabled: false),
      isTrue,
    );
    expect(
      shouldBlockScreenshots(status: VaultStatus.unlocked, enabled: true),
      isTrue,
    );
  });

  test('only an unlocked vault can opt out of screenshot blocking', () {
    expect(
      shouldBlockScreenshots(status: VaultStatus.unlocked, enabled: false),
      isFalse,
    );
  });

  test('the provider mirrors and persists the preference', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(screenshotProtectionProvider), isTrue);
    container
        .read(screenshotProtectionProvider.notifier)
        .setEnabled(enabled: false);
    expect(container.read(screenshotProtectionProvider), isFalse);
    expect(prefs.screenshotProtection, isFalse);
  });

  testWidgets('the security section offers a screenshot toggle', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      _section(
        screenshotProtection: true,
        onScreenshotProtectionChanged: changes.add,
      ),
    );

    expect(find.text('Screenshot protection'), findsOneWidget);
    final toggle = tester.widget<Switch>(find.byType(Switch).last);
    expect(toggle.value, isTrue);

    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    expect(changes, [false]);
  });
}
