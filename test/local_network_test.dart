import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/features/sync/local_network.dart';

const _local = LocalNetworkAddress(address: '192.168.1.20', prefixLength: 24);

final class _FakeAdapter implements LocalNetworkAdapter {
  new({
    this.addresses = const <LocalNetworkAddress>[_local],
    this.answers = const <LocalNetworkDatagram>[],
    this.hang = false,
  });

  /// The fake binds a notional socket here; assertions check this is advertised.
  static const int advertisedPort = kLocalNetworkKeyelPort;

  final List<LocalNetworkAddress> addresses;
  final List<LocalNetworkDatagram> answers;
  final bool hang;
  List<int>? sentPayload;
  String? sentPeerId;
  String? sentDisplayName;

  @override
  Future<List<LocalNetworkAddress>> interfaces() async => addresses;

  @override
  Future<List<LocalNetworkDatagram>> probe({
    required List<LocalNetworkAddress> addresses,
    required String peerId,
    required String displayName,
    required Duration timeout,
  }) async {
    sentPeerId = peerId;
    sentDisplayName = displayName;
    sentPayload = utf8.encode(
      jsonEncode(<String, Object?>{
        'kind': 'keyel-probe',
        'v': 1,
        'peerId': peerId,
        'displayName': displayName,
        'port': advertisedPort,
      }),
    );
    if (hang) return await Completer<List<LocalNetworkDatagram>>().future;
    return List.unmodifiable(answers);
  }
}

List<int> _answerBytes({
  String peerId = 'abcdef0123456789',
  String displayName = 'Desk',
  String kind = 'keyel-probe',
  int port = kLocalNetworkKeyelPort,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return utf8.encode(
    jsonEncode(<String, Object?>{
      'kind': kind,
      'v': 1,
      'peerId': peerId,
      'displayName': displayName,
      'port': port,
      ...extra,
    }),
  );
}

LocalNetworkDatagram _answer(
  List<int> bytes, {
  String address = '192.168.1.7',
}) => LocalNetworkDatagram(address: address, bytes: bytes);

Future<List<LocalNetworkPeer>> _discover(
  _FakeAdapter adapter, {
  Duration timeout = const Duration(milliseconds: 200),
}) => IoLocalNetworkDiscovery(adapter: adapter).discover(timeout: timeout);

void main() {
  test('same-subnet answers become bounded, non-secret DTOs', () async {
    final adapter = _FakeAdapter(
      answers: <LocalNetworkDatagram>[
        _answer(_answerBytes()),
        _answer(
          _answerBytes(
            peerId: '1122334455667788',
            displayName: 'Laptop',
            kind: 'keyel-peer',
          ),
        ),
        // Duplicate ids and our own id must not be returned twice.
        _answer(_answerBytes()),
      ],
    );

    final peers = await _discover(adapter);

    expect(peers, hasLength(2));
    expect(peers.first.peerId, 'abcdef0123456789');
    expect(peers.first.displayName, 'Desk');
    expect(peers.first.address, '192.168.1.7');
    expect(peers.first.port, kLocalNetworkKeyelPort);
    expect(peers.first.isSameSubnet, isTrue);
    expect(peers.map((peer) => peer.peerId), contains('1122334455667788'));
  });

  test('foreign-subnet answers are rejected', () async {
    final adapter = _FakeAdapter(
      answers: <LocalNetworkDatagram>[
        _answer(_answerBytes(), address: '10.9.9.9'),
      ],
    );

    expect(await _discover(adapter), isEmpty);
  });

  test('malformed, oversize and pairing-code answers are rejected', () async {
    final adapter = _FakeAdapter(
      answers: <LocalNetworkDatagram>[
        _answer(utf8.encode('not json')),
        _answer(<int>[0xFF, 0xFE, 0xFD]),
        _answer(<int>[for (var i = 0; i < 513; i++) i]),
        _answer(
          _answerBytes(
            extra: <String, Object?>{
              'pairingCode': 'KYSYNC1-SHOULD-NEVER-TRAVEL',
            },
          ),
        ),
        _answer(_answerBytes(extra: <String, Object?>{'syncKey': 'deadbeef'})),
        _answer(_answerBytes(displayName: 'KYSYNC1-LEAK')),
      ],
    );

    expect(await _discover(adapter), isEmpty);
  });

  test('probe payload contains only non-secret fields', () async {
    final adapter = _FakeAdapter();
    await _discover(adapter);

    final sent = utf8.decode(adapter.sentPayload!);
    final decoded = jsonDecode(sent) as Map<String, Object?>;
    expect(decoded.keys.toSet(), <String>{
      'kind',
      'v',
      'peerId',
      'displayName',
      'port',
    });
    expect(decoded['kind'], 'keyel-probe');
    expect(decoded['displayName'], 'Keyel');
    // The fake's notional socket is bound here; the advertised port must match.
    expect(decoded['port'], _FakeAdapter.advertisedPort);
    expect(decoded['port'], kLocalNetworkKeyelPort);
    expect(decoded['peerId'], adapter.sentPeerId);
    for (final forbidden in <String>[
      'KYSYNC1',
      'pairing',
      'syncId',
      'syncKey',
      'secret',
      'vault',
    ]) {
      expect(sent.toLowerCase().contains(forbidden.toLowerCase()), isFalse);
    }
    expect(sent.length, lessThanOrEqualTo(kLocalNetworkMaxPayloadBytes));
  });

  test('a hanging probe times out with no peers', () async {
    final stopwatch = Stopwatch()..start();
    final peers = await _discover(
      _FakeAdapter(hang: true),
      timeout: const Duration(milliseconds: 40),
    );
    stopwatch.stop();

    expect(peers, isEmpty);
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });

  test('no usable interfaces yields no peers', () async {
    final adapter = _FakeAdapter(addresses: const <LocalNetworkAddress>[]);
    expect(await _discover(adapter), isEmpty);
    expect(adapter.sentPayload, isNull);
  });

  test('provider can be overridden with a fake service', () async {
    final fake = _FakeDiscovery();
    final container = ProviderContainer(
      overrides: [localNetworkDiscoveryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final peers = await container
        .read(localNetworkDiscoveryProvider)
        .discover();

    expect(fake.calls, 1);
    expect(peers, isEmpty);
  });
}

final class _FakeDiscovery implements LocalNetworkDiscovery {
  int calls = 0;

  @override
  Future<List<LocalNetworkPeer>> discover({
    Duration timeout = kLocalNetworkDiscoveryTimeout,
  }) async {
    calls++;
    return const <LocalNetworkPeer>[];
  }
}
