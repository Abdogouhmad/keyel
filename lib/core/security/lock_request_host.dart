import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/platform/launch_action.dart';
import 'package:keyel/core/platform/lock_request.dart';
import 'package:keyel/data/vault_session_provider.dart';

/// Turns Android one-tap lock requests into the normal in-app lock path.
///
/// The host handles both timings: a request that arrived before Flutter started
/// (read once on mount) and taps while the app is running (method-call handler).
class LockRequestHost extends ConsumerStatefulWidget {
  /// Wraps the app with one-tap lock support.
  const new({required this.child, super.key});

  /// The app subtree.
  final Widget child;

  @override
  ConsumerState<LockRequestHost> createState() => _LockRequestHostState();
}

class _LockRequestHostState extends ConsumerState<LockRequestHost> {
  late final LockRequestBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(lockRequestBridgeProvider)(_lockNow);
    unawaited(_start());
  }

  Future<void> _start() async {
    _bridge.register();
    // The native side may have recorded a request before this handler existed.
    final action = await ref.read(initialLaunchActionProvider)();
    if (!mounted || action != lockLaunchAction) return;
    _lockNow();
  }

  void _lockNow() {
    ref.read(vaultSessionProvider.notifier).lock();
  }

  @override
  void dispose() {
    _bridge.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
