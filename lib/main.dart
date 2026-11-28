import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/ota/ota_check_host.dart';
import 'package:keyel/core/platform/launch_action.dart';
import 'package:keyel/core/platform/secure_screen.dart';
import 'package:keyel/core/quickaccess/generate_request_host.dart';
import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/core/security/auto_lock_host.dart';
import 'package:keyel/core/security/lock_request_host.dart';
import 'package:keyel/core/security/screenshot_protection_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_paths.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/ota/widgets/update_available_banner.dart';
import 'package:keyel/features/sync/local_network_presence_host.dart';
import 'package:keyel/l10n/generated/app_localizations.dart';
import 'package:keyel/src/rust/api/session.dart' as vault_api;
import 'package:keyel/src/rust/frb_generated.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/l10n/locale_provider.dart';
import 'package:keyel/ui/theme/appearance_provider.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

Future<void> main() async {
  // Edge-to-edge: draw behind system bars (docs/design.md).
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Keep screenshots and the Recents thumbnail out of the lock screen from the
  // first frame onward. ScreenshotProtectionHost relaxes this only after the
  // vault unlocks and only when the user opted in to allowing captures.
  await setSecureScreen(secure: true);

  // Bring up the Rust side (FRB).
  await RustLib.init();

  // Point the bridge at the app-private vault file before any UI runs.
  try {
    final vaultPath = await defaultVaultPath();
    vault_api.init(path: vaultPath);
    await AppPreferences.instance.load(vaultPath);
    setCurrentLocaleId(AppPreferences.instance.localeId);
  } on Object catch (error) {
    // Never block startup on storage problems; the debug screen reports the
    // real error when the user tries to create or unlock a vault.
    debugPrint('Keyel: vault storage is unavailable: $error');
  }

  // Consume a launcher action that arrived before Flutter started, so no vault
  // row can flash before the unlock screen is shown.
  final container = ProviderContainer();
  final launchAction = await getInitialLaunchAction();
  if (launchAction == lockLaunchAction) {
    container.read(vaultSessionProvider.notifier).lock();
  } else if (launchAction == generateLaunchAction) {
    container.read(initialRouteProvider.notifier).initialLocation =
        KeyelRoutes.generator;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoLockHost(
        child: OtaCheckHost(
          child: ScreenshotProtectionHost(
            child: GenerateRequestHost(
              child: LockRequestHost(
                child: LocalNetworkPresenceHost(child: KeyelApp()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The Keyel root widget.
///
/// The user can choose a fixed accent palette, theme mode and AMOLED-black
/// dark surfaces from Settings → Appearance. Security/status colors remain
/// consistent across palettes.
class KeyelApp extends ConsumerWidget {
  /// Creates the root application widget.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: l10nOf(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: appearance.themeMode,
      theme: appearance.lightTheme,
      darkTheme: appearance.darkTheme,
      routerConfig: router,
      // Honour the platform high-contrast setting on every route and sheet,
      // and show update notices above the routed page rather than as a snackbar.
      builder: (context, child) => KeyelTheme.highContrastBuilder(
        child: UpdateAvailableBanner(
          onOpen: () => unawaited(router.push(KeyelRoutes.softwareUpdate)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
