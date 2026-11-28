import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/sync/local_network.dart';
import 'package:keyel/features/sync/local_network_presence_host.dart';

class _TrackingDiscovery implements LocalNetworkDiscovery {
  int starts = 0;
  int stops = 0;

  @override
  Future<List<LocalNetworkPeer>> discover({
    Duration timeout = kLocalNetworkDiscoveryTimeout,
  }) async => const [];

  @override
  Future<void> startPresence() async => starts++;

  @override
  Future<void> stopPresence() async => stops++;
}

class _MutableSession extends VaultSessionNotifier {
  new(this.initial);

  final VaultStatus initial;

  @override
  VaultSessionState build() => VaultSessionState(status: initial);

  void setStatus(VaultStatus status) =>
      state = VaultSessionState(status: status);
}

Widget _host(
  Widget child, {
  required VaultSessionNotifier session,
  required LocalNetworkDiscovery discovery,
}) => ProviderScope(
  overrides: [
    vaultSessionProvider.overrideWith(() => session),
    localNetworkDiscoveryProvider.overrideWithValue(discovery),
  ],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('unlocked vault advertises; locking stops the beacon', (
    tester,
  ) async {
    final discovery = _TrackingDiscovery();
    final session = _MutableSession(VaultStatus.locked);

    await tester.pumpWidget(
      _host(
        const LocalNetworkPresenceHost(child: SizedBox.expand()),
        session: session,
        discovery: discovery,
      ),
    );
    await tester.pumpAndSettle();
    expect(discovery.starts, 0);

    session.setStatus(VaultStatus.unlocked);
    await tester.pumpAndSettle();
    expect(discovery.starts, 1);

    session.setStatus(VaultStatus.locked);
    await tester.pumpAndSettle();
    expect(discovery.stops, greaterThanOrEqualTo(1));
  });

  testWidgets('sync state does not gate discovery before pairing', (
    tester,
  ) async {
    final discovery = _TrackingDiscovery();
    final session = _MutableSession(VaultStatus.unlocked);

    await tester.pumpWidget(
      _host(
        const LocalNetworkPresenceHost(child: SizedBox.expand()),
        session: session,
        discovery: discovery,
      ),
    );
    await tester.pumpAndSettle();

    expect(discovery.starts, 1);
  });

  testWidgets('backgrounding stops the beacon', (tester) async {
    final discovery = _TrackingDiscovery();
    final session = _MutableSession(VaultStatus.unlocked);

    await tester.pumpWidget(
      _host(
        const LocalNetworkPresenceHost(child: SizedBox.expand()),
        session: session,
        discovery: discovery,
      ),
    );
    await tester.pumpAndSettle();
    expect(discovery.starts, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(discovery.stops, greaterThanOrEqualTo(1));

    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });
}
