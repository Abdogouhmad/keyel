import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/onboarding/onboarding_screen.dart';
import 'package:keyel/features/vault/widgets/create_vault_view.dart';
import 'package:keyel/features/vault/widgets/recovery_reset_view.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/ui/adaptive/content.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A vault session that never touches Rust, so focused screens can be pumped
/// in isolation at desktop sizes.
class _FakeVaultSession extends VaultSessionNotifier {
  new(this.status);

  final VaultStatus status;

  @override
  VaultSessionState build() => VaultSessionState(status: status);
}

void _sizeTo(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  VaultStatus status = VaultStatus.locked,
}) => ProviderScope(
  overrides: [
    vaultSessionProvider.overrideWith(() => _FakeVaultSession(status)),
  ],
  child: MaterialApp(
    theme: KeyelTheme.light(),
    home: Directionality(textDirection: direction, child: child),
  ),
);

void _expectCappedColumn(WidgetTester tester, double width) {
  final rect = tester.getRect(find.byKey(KeyelFocusedBody.contentKey));
  expect(rect.width, closeTo(width, 1));
  expect(rect.center.dx, closeTo(tester.view.physicalSize.width / 2, 1));
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() {
    // The biometric button reads this directly in initState. Tests must not
    // inherit a value set by another suite.
    AppPreferences.instance.biometricEnabled = false;
  });

  group('onboarding on desktop', () {
    testWidgets('caps at the form token and centers in LTR', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(
        _host(const OnboardingScreen(), status: VaultStatus.noVault),
      );
      await tester.pumpAndSettle();

      _expectCappedColumn(tester, KeyelContentWidth.form);
    });

    testWidgets('centers the same column in RTL', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(
        _host(
          const OnboardingScreen(),
          direction: TextDirection.rtl,
          status: VaultStatus.noVault,
        ),
      );
      await tester.pumpAndSettle();

      _expectCappedColumn(tester, KeyelContentWidth.form);
    });

    testWidgets('grows the cap with 200% text scale', (tester) async {
      _sizeTo(tester, 1600);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _host(const OnboardingScreen(), status: VaultStatus.noVault),
      );
      await tester.pumpAndSettle();

      _expectCappedColumn(tester, KeyelContentWidth.form * 2);
    });

    testWidgets('fills a phone window with responsive margins', (tester) async {
      _sizeTo(tester, 400);
      await tester.pumpWidget(
        _host(const OnboardingScreen(), status: VaultStatus.noVault),
      );
      await tester.pumpAndSettle();

      final rect = tester.getRect(find.byKey(KeyelFocusedBody.contentKey));
      expect(rect.width, 400 - (2 * 16));
      expect(rect.center.dx, 200);
      expect(tester.takeException(), isNull);
    });
  });

  group('other focused vault screens on desktop', () {
    testWidgets('unlock stays centered', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(_host(const UnlockVaultView()));
      await tester.pumpAndSettle();

      _expectCappedColumn(tester, KeyelContentWidth.form);
    });

    testWidgets('create vault stays centered', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(
        _host(const CreateVaultView(), status: VaultStatus.noVault),
      );
      await tester.pumpAndSettle();

      _expectCappedColumn(tester, KeyelContentWidth.form);
    });

    testWidgets('recovery reset stays centered', (tester) async {
      _sizeTo(tester, 1600);
      await tester.pumpWidget(
        _host(Scaffold(body: RecoveryResetView(onBack: () {}))),
      );
      await tester.pumpAndSettle();

      _expectCappedColumn(tester, KeyelContentWidth.form);
    });
  });
}
