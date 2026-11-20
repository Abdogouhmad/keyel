import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/data/app_preferences.dart';

/// Runs quiet OTA checks while the app is in the foreground.
///
/// Checks happen on mount, on every resume, and periodically while the app is
/// visible. There is no background service or alarm: an update is detected the
/// next time the user opens Keyel, which preserves the project's foreground-only
/// network promise. The host never runs while the app is paused.
class OtaCheckHost extends ConsumerStatefulWidget {
  /// Creates the host around the root app.
  const new({
    required this.child,
    this.checkInterval = const Duration(minutes: 30),
    super.key,
  });

  /// Widget below the host, normally `KeyelApp`.
  final Widget child;

  /// Minimum time between two automatic checks.
  final Duration checkInterval;

  @override
  ConsumerState<OtaCheckHost> createState() => _OtaCheckHostState();
}

class _OtaCheckHostState extends ConsumerState<OtaCheckHost>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Riverpod state must not change during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resumed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resumed();
        });
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _timer?.cancel();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _resumed() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.checkInterval, (_) => _maybeCheck());
    unawaited(_maybeCheck());
  }

  Future<void> _maybeCheck() async {
    final notifier = ref.read(otaProvider.notifier);
    final state = ref.read(otaProvider);
    if (!state.autoCheck || state.isChecking || state.isDownloading) return;

    final lastCheck = AppPreferences.instance.otaLastCheckedMs;
    if (lastCheck != null &&
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(lastCheck),
            ) <
            widget.checkInterval) {
      return;
    }

    // The permission prompt must not delay the network check; the banner is
    // shown even when the user declines the notification permission.
    unawaited(notifier.maybePromptForNotifications());
    await notifier.checkForUpdates(userInitiated: false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
