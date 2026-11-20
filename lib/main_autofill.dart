/// Separate Flutter entrypoint used by the autofill `AuthActivity`.
///
/// This is launched in a dedicated Flutter activity when another app asks
/// Keyel to fill credentials, or when a login form is submitted so Keyel can
/// offer to save it. It boots the Rust bridge, loads preferences, and renders
/// only the relevant autofill screen (no shell, no bottom bar).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/security/auto_lock_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_paths.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/autofill/autofill_picker_screen.dart';
import 'package:keyel/features/autofill/autofill_save_screen.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/src/rust/api/session.dart' as vault_api;
import 'package:keyel/src/rust/frb_generated.dart';
import 'package:keyel/ui/theme/keyel_palettes.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

const _autofillChannel = MethodChannel('keyel/autofill');

/// Entry point invoked by `AuthActivity.getDartEntrypointFunctionName`.
@pragma('vm:entry-point')
Future<void> mainAutofill() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // AuthActivity sets FLAG_SECURE natively before this entrypoint starts; the
  // keyel/platform channel is not registered on that activity.

  await RustLib.init();

  try {
    final vaultPath = await defaultVaultPath();
    vault_api.init(path: vaultPath);
    await AppPreferences.instance.load(vaultPath);
  } on Object catch (_) {
    // Same resilience as the main entrypoint.
  }

  // Ask the host activity what we're filling for (or saving).
  Map<Object?, Object?>? args;
  try {
    args = await _autofillChannel.invokeMapMethod<String, String>(
      'getAutofillArgs',
    );
  } on Object catch (_) {
    // Will fall back to no target.
  }

  final mode = args?['mode'] as String? ?? 'fill';
  final package = _nonEmpty(args?['package'] as String?);
  final webDomain = _nonEmpty(args?['webDomain'] as String?);

  if (mode == 'save') {
    // Respect the user's "Ask to save" preference: finish silently instead of
    // showing the confirmation sheet.
    if (!AppPreferences.instance.autofillAskToSave) {
      await _invoke('cancel');
      return;
    }
    final username = args?['username'] as String? ?? '';
    final password = args?['password'] as String? ?? '';
    runApp(
      ProviderScope(
        child: AutoLockHost(
          child: _AutofillApp(
            package: package,
            webDomain: webDomain,
            mode: mode,
            username: username,
            password: password,
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    ProviderScope(
      child: AutoLockHost(
        child: _AutofillApp(package: package, webDomain: webDomain, mode: mode),
      ),
    ),
  );
}

Future<void> _invoke(String method, [Map<String, Object?>? args]) async {
  try {
    await _autofillChannel.invokeMethod<void>(method, args);
  } on Object catch (_) {
    // The activity already finished; nothing to do.
  }
}

String? _nonEmpty(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return s;
}

class _AutofillApp extends ConsumerWidget {
  const new({
    this.package,
    this.webDomain,
    this.mode = 'fill',
    this.username = '',
    this.password = '',
  });

  final String? package;
  final String? webDomain;
  final String mode;
  final String username;
  final String password;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked =
        ref.watch(vaultSessionProvider.select((state) => state.status)) ==
        VaultStatus.unlocked;
    final prefs = AppPreferences.instance;
    final palette = KeyelPaletteX.fromId(prefs.paletteId);
    final themeMode = KeyelPaletteX.themeModeFromId(prefs.themeMode);

    return MaterialApp(
      title: 'Keyel Autofill',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: KeyelTheme.light(palette: palette),
      darkTheme: KeyelTheme.dark(
        palette: palette,
        amoledBlack: prefs.amoledBlack,
      ),
      // Honour the platform high-contrast setting on the autofill screens too.
      builder: (context, child) => KeyelTheme.highContrastBuilder(
        child: child ?? const SizedBox.shrink(),
      ),
      home: isUnlocked
          ? _unlockedScreen()
          // The UnlockVaultView updates vaultSessionProvider on success,
          // which triggers a rebuild that swaps to the real screen.
          : const UnlockVaultView(),
    );
  }

  Widget _unlockedScreen() {
    if (mode == 'save') {
      return AutofillSaveScreen(
        package: package,
        webDomain: webDomain,
        username: username,
        password: password,
        onSaved: () => unawaited(_invoke('saveCompleted')),
        onDecline: () => unawaited(_invoke('cancel')),
      );
    }
    return AutofillPickerScreen(
      package: package,
      webDomain: webDomain,
      onPicked: (selection) => unawaited(
        _invoke('returnCredentials', {
          'username': selection.username,
          'password': selection.password,
        }),
      ),
      onCreateNew: () => unawaited(_invoke('cancel')),
    );
  }
}
