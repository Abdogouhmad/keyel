import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/platform/secure_screen.dart';
import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/core/security/auto_lock_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_paths.dart';
import 'package:keyel/src/rust/api/session.dart' as vault_api;
import 'package:keyel/src/rust/frb_generated.dart';
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
  // first frame onward.
  await setSecureScreen(secure: true);

  // Bring up the Rust side (FRB).
  await RustLib.init();

  // Point the bridge at the app-private vault file before any UI runs.
  try {
    final vaultPath = await defaultVaultPath();
    vault_api.init(path: vaultPath);
    await AppPreferences.instance.load(vaultPath);
  } on Object catch (error) {
    // Never block startup on storage problems; the debug screen reports the
    // real error when the user tries to create or unlock a vault.
    debugPrint('Keyel: vault storage is unavailable: $error');
  }

  runApp(const ProviderScope(child: AutoLockHost(child: KeyelApp())));
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

    return MaterialApp.router(
      title: 'Keyel',
      debugShowCheckedModeBanner: false,
      themeMode: appearance.themeMode,
      theme: appearance.lightTheme,
      darkTheme: appearance.darkTheme,
      routerConfig: ref.watch(appRouterProvider),
      // Honour the platform high-contrast setting on every route and sheet.
      builder: (context, child) => KeyelTheme.highContrastBuilder(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
