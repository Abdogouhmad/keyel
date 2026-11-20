import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/platform/secure_screen.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';

/// Riverpod mirror of the persisted screenshot-protection preference.
///
/// The settings switch and the security dashboard both read this provider, so
/// toggling it updates every surface without duplicating the preference value.
final screenshotProtectionProvider =
    NotifierProvider<ScreenshotProtectionNotifier, bool>(
      ScreenshotProtectionNotifier.new,
    );

/// Persists and exposes the user's screenshot-protection choice.
class ScreenshotProtectionNotifier extends Notifier<bool> {
  @override
  bool build() => AppPreferences.instance.screenshotProtection;

  /// Enables or disables screenshots while the vault is unlocked.
  void setEnabled({required bool enabled}) {
    final prefs = AppPreferences.instance..screenshotProtection = enabled;
    state = enabled;
    unawaited(prefs.save());
  }
}

/// Whether the OS should block screenshots for the current app state.
///
/// The lock, unlock and first-run screens always stay protected: they can show
/// a recovery key or the unlock prompt. Once the vault is unlocked the user's
/// preference decides, which lets them capture in-app designs.
bool shouldBlockScreenshots({
  required VaultStatus status,
  required bool enabled,
}) => status != VaultStatus.unlocked || enabled;

/// Applies the screenshot preference to the platform window as state changes.
///
/// `main()` sets `FLAG_SECURE` before the first frame so the unlock screen is
/// never exposed. This host then relaxes it after the vault unlocks when the
/// user has chosen to allow screenshots, and restores it on every lock. The
/// separate autofill and passkey entrypoints keep the flag set unconditionally.
class ScreenshotProtectionHost extends ConsumerStatefulWidget {
  /// Creates the host around [child].
  const new({required this.child, super.key});

  /// The application subtree.
  final Widget child;

  @override
  ConsumerState<ScreenshotProtectionHost> createState() =>
      _ScreenshotProtectionHostState();
}

class _ScreenshotProtectionHostState
    extends ConsumerState<ScreenshotProtectionHost> {
  @override
  void initState() {
    super.initState();
    ref.listen(
      vaultSessionProvider.select((state) => state.status),
      (_, _) => _apply(),
    );
    ref.listen(screenshotProtectionProvider, (_, _) => _apply());
    // Apply after mount: preferences are loaded before runApp, and the first
    // platform call must not delay the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  void _apply() {
    final secure = shouldBlockScreenshots(
      status: ref.read(vaultSessionProvider).status,
      enabled: ref.read(screenshotProtectionProvider),
    );
    unawaited(setSecureScreen(secure: secure));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
