/// Separate Flutter entrypoint used by the Credential Manager passkey handler.
///
/// This is launched when another app/browser requests passkey creation or
/// assertion via Android Credential Manager. It boots the Rust bridge, loads
/// preferences, and renders only the passkey ceremony UI (unlock/confirm/pick).
///
/// Security: private key material and signing never leave Rust/session
/// boundaries. This UI only passes request metadata and receives platform
/// response JSON (or errors).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/security/auto_lock_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_paths.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/passkeys/passkey_create_screen.dart';
import 'package:keyel/features/passkeys/passkey_get_screen.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/src/rust/api/session.dart' as vault_api;
import 'package:keyel/src/rust/frb_generated.dart';
import 'package:keyel/ui/theme/keyel_palettes.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

const _channel = MethodChannel('keyel/passkey');

/// Entry point invoked by `PasskeyHandlerActivity.getDartEntrypointFunctionName`.
@pragma('vm:entry-point')
Future<void> mainPasskey() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // PasskeyHandlerActivity sets FLAG_SECURE natively before this entrypoint
  // starts; the keyel/platform channel is not registered on that activity.

  await RustLib.init();

  try {
    final vaultPath = await defaultVaultPath();
    vault_api.init(path: vaultPath);
    await AppPreferences.instance.load(vaultPath);
  } on Object catch (_) {
    // Same resilience as other entrypoints.
  }

  Map<Object?, Object?>? args;
  try {
    args = await _channel.invokeMapMethod<Object?, Object?>('getRequest');
  } on Object catch (_) {
    // Will fail closed in UI.
  }

  runApp(
    ProviderScope(
      child: AutoLockHost(
        child: _PasskeyApp(args: args ?? const <Object?, Object?>{}),
      ),
    ),
  );
}

String? _nonEmpty(Object? v) {
  if (v is! String) return null;
  final s = v.trim();
  return s.isEmpty ? null : s;
}

Future<void> _returnCreateResponse(String responseJson) async {
  try {
    await _channel.invokeMethod<void>('returnCreateResponse', {
      'responseJson': responseJson,
    });
  } on Object catch (_) {}
}

Future<void> _returnGetResponse(String responseJson) async {
  try {
    await _channel.invokeMethod<void>('returnGetResponse', {
      'responseJson': responseJson,
    });
  } on Object catch (_) {}
}

Future<void> _cancel([String? message]) async {
  try {
    await _channel.invokeMethod<void>('cancel', {'message': ?message});
  } on Object catch (_) {}
}

class _PasskeyApp extends ConsumerWidget {
  const new({required this.args});

  final Map<Object?, Object?> args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked =
        ref.watch(vaultSessionProvider.select((state) => state.status)) ==
        VaultStatus.unlocked;
    final prefs = AppPreferences.instance;
    final palette = KeyelPaletteX.fromId(prefs.paletteId);
    final themeMode = KeyelPaletteX.themeModeFromId(prefs.themeMode);

    final mode = _nonEmpty(args['mode']) ?? 'unknown';
    final requestJson = _nonEmpty(args['requestJson']);
    final origin = _nonEmpty(args['origin']) ?? '';
    final rpId = _nonEmpty(args['rpId']);

    return MaterialApp(
      title: 'Keyel Passkeys',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: KeyelTheme.light(palette: palette),
      darkTheme: KeyelTheme.dark(
        palette: palette,
        amoledBlack: prefs.amoledBlack,
      ),
      builder: (context, child) => KeyelTheme.highContrastBuilder(
        child: child ?? const SizedBox.shrink(),
      ),
      home: !isUnlocked
          ? const UnlockVaultView()
          : _buildScreen(
              mode: mode,
              requestJson: requestJson,
              origin: origin,
              rpId: rpId,
            ),
    );
  }

  Widget _buildScreen({
    required String mode,
    required String? requestJson,
    required String origin,
    required String? rpId,
  }) {
    if (requestJson == null) {
      return _ErrorScreen(
        title: 'Passkey unavailable',
        message: 'Could not read the passkey request. Try again.',
        onClose: () => unawaited(_cancel()),
      );
    }
    switch (mode) {
      case 'create':
        return PasskeyCreateScreen(
          requestJson: requestJson,
          origin: origin,
          onCreated: (responseJson) =>
              unawaited(_returnCreateResponse(responseJson)),
          onCancel: () => unawaited(_cancel()),
        );
      case 'get':
      case 'unlock':
        return PasskeyGetScreen(
          requestJson: requestJson,
          origin: origin,
          rpId: rpId,
          onAsserted: (responseJson) =>
              unawaited(_returnGetResponse(responseJson)),
          onCancel: () => unawaited(_cancel()),
        );
      default:
        return _ErrorScreen(
          title: 'Passkey unavailable',
          message: 'This passkey request is not supported.',
          onClose: () => unawaited(_cancel()),
        );
    }
  }
}

class _ErrorScreen extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.key_off_rounded, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onClose, child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }
}
