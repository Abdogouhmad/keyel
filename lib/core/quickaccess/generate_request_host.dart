import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/platform/generate_request.dart';
import 'package:keyel/core/platform/launch_action.dart';
import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/core/router/keyel_routes.dart';

/// Turns a warm "Generate password" launch into navigation to the generator.
///
/// Generation itself stays on the screen: the shortcut only opens the tool and
/// never creates or copies a secret on the user's behalf. A locked vault is
/// redirected to `/unlock` by the normal router guard.
class GenerateRequestHost extends ConsumerStatefulWidget {
  /// Wraps the app with generator-shortcut support.
  const new({required this.child, super.key});

  /// The app subtree.
  final Widget child;

  @override
  ConsumerState<GenerateRequestHost> createState() =>
      _GenerateRequestHostState();
}

class _GenerateRequestHostState extends ConsumerState<GenerateRequestHost> {
  late final GenerateRequestBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(generateRequestBridgeProvider)(_openGenerator);
    unawaited(_start());
  }

  Future<void> _start() async {
    _bridge.register();
    // A cold request is consumed by main() before runApp, so this is normally
    // null. Keeping the read preserves the same pattern as LockRequestHost.
    final action = await ref.read(initialLaunchActionProvider)();
    if (!mounted || action != generateLaunchAction) return;
    _openGenerator();
  }

  void _openGenerator() {
    ref.read(appRouterProvider).go(KeyelRoutes.generator);
  }

  @override
  void dispose() {
    _bridge.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
