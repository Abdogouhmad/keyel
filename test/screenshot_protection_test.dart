import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/security/screenshot_protection_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_sections.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A session whose status can be flipped mid-test without the Rust bridge.
class _MutableSession extends VaultSessionNotifier {
  @override
  VaultSessionState build() =>
      const VaultSessionState(status: VaultStatus.unlocked);

  void lockNow() => state = const VaultSessionState(status: VaultStatus.locked);
}

Future<void> _flushPlatformCalls(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

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

  testWidgets('the host reapplies the platform flag on every state change', (
    tester,
  ) async {
    const channel = MethodChannel('keyel/platform');
    final secureCalls = <bool>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setSecure') {
              final args = call.arguments as Map<Object?, Object?>;
              secureCalls.add(args['secure']! as bool);
            }
            return null;
          });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final container = ProviderContainer(
      overrides: [vaultSessionProvider.overrideWith(_MutableSession.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ScreenshotProtectionHost(child: SizedBox.shrink()),
        ),
      ),
    );
    await _flushPlatformCalls(tester);
    expect(secureCalls, [true], reason: 'startup flag from main()');

    // The regression: this used to be a no-op because Riverpod 3 had already
    // closed the listeners registered in initState.
    container
        .read(screenshotProtectionProvider.notifier)
        .setEnabled(enabled: false);
    await _flushPlatformCalls(tester);
    expect(secureCalls, [true, false]);

    (container.read(vaultSessionProvider.notifier) as _MutableSession)
        .lockNow();
    await _flushPlatformCalls(tester);
    expect(secureCalls, [true, false, true]);

    container
        .read(screenshotProtectionProvider.notifier)
        .setEnabled(enabled: false);
    await _flushPlatformCalls(tester);
    expect(secureCalls, [true, false, true], reason: 'locked stays secure');
  });
}
