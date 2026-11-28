import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/sync/local_network.dart';

/// Keeps Keyel discoverable on the local network while the vault is unlocked.
///
/// Presence is deliberately tied to the unlock guard, not to sync being
/// enabled: two devices must be able to find each other *before* a group exists.
/// It sends only the bounded, secret-free Keyel beacon from
/// [LocalNetworkDiscovery]; it never opens a sync transport, never authenticates
/// a peer and never sends a pairing code, sync id/key or vault data. Manual code
/// entry remains the trust root and works whether or not discovery succeeds.
///
/// The beacon stops while the app is in the background so discovery stays
/// foreground-only, as sync itself does.
class LocalNetworkPresenceHost extends ConsumerStatefulWidget {
  /// Creates the presence host around the rest of the app.
  const new({required this.child, super.key});

  /// The application below this host.
  final Widget child;

  @override
  ConsumerState<LocalNetworkPresenceHost> createState() =>
      _LocalNetworkPresenceHostState();
}

class _LocalNetworkPresenceHostState
    extends ConsumerState<LocalNetworkPresenceHost>
    with WidgetsBindingObserver {
  late final LocalNetworkDiscovery _discovery;
  VaultStatus _status = VaultStatus.locked;
  bool _foreground = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _discovery = ref.read(localNetworkDiscoveryProvider);
    _status = ref.read(vaultSessionProvider).status;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    unawaited(_apply());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    unawaited(_apply());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vaultSessionProvider, (previous, next) {
      if (previous?.status != next.status) {
        _status = next.status;
        unawaited(_apply());
      }
    });
    return widget.child;
  }

  Future<void> _apply() async {
    final generation = ++_generation;
    final shouldBePresent = _status == VaultStatus.unlocked && _foreground;
    try {
      if (shouldBePresent) {
        await _discovery.startPresence();
      } else {
        await _discovery.stopPresence();
      }
    } on Object catch (_) {
      // Fail closed: a beacon error must never leave presence behind.
      try {
        await _discovery.stopPresence();
      } on Object catch (_) {
        // Nothing more can be done; the next state change will retry.
      }
      return;
    }
    if (generation != _generation && mounted) {
      await _discovery.stopPresence();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_discovery.stopPresence());
    super.dispose();
  }
}
