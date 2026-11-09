import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';

/// Watches the app lifecycle and drives the vault auto-lock countdown.
///
/// The widget wraps the whole app, but reads the session lazily so it stays
/// cheap while no vault is unlocked. Dart timers are suspended while Android
/// freezes the process, so resuming also compares timestamps to catch a
/// background period that elapsed with the app frozen.
class AutoLockHost extends ConsumerStatefulWidget {
  /// Creates the lifecycle host around [child].
  const new({required this.child, super.key});

  /// The application subtree.
  final Widget child;

  @override
  ConsumerState<AutoLockHost> createState() => _AutoLockHostState();
}

class _AutoLockHostState extends ConsumerState<AutoLockHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(vaultSessionProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        notifier.onAppBackgrounded();
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
