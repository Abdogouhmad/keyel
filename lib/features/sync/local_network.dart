import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The LocalSend multicast group, reused only as a LAN probe target.
///
/// LocalSend sends v2 announcements here; Keyel also sends a small, bounded
/// probe so LocalSend-compatible networks and Keyel peers can be found with
/// the same addresses. Nothing about discovery authenticates a peer.
const String kLocalNetworkMulticastGroup = '224.0.0.167';

/// LocalSend's default port, kept only as a compatibility probe target.
///
/// Keyel peers do not listen here; the Keyel discovery port is
/// [kLocalNetworkKeyelPort].
const int kLocalNetworkPort = 53317;

/// Keyel's own UDP discovery port.
///
/// Kept separate from LocalSend's 53317 so a device running both apps can
/// discover Keyel peers without a port collision. The IO adapter binds this
/// port (with an ephemeral fallback) and advertises the actual bound port.
const int kLocalNetworkKeyelPort = 53318;

/// Default deadline for one discovery pass.
const Duration kLocalNetworkDiscoveryTimeout = Duration(milliseconds: 900);

/// Hard cap on peers returned by one discovery pass.
const int kLocalNetworkMaxPeers = 16;

/// Hard cap on accepted/sent discovery datagrams.
const int kLocalNetworkMaxPayloadBytes = 512;

/// Maximum number of local interfaces considered in one pass.
const int kLocalNetworkMaxInterfaces = 4;

const String _probeKind = 'keyel-probe';
const String _peerKind = 'keyel-peer';
const int _payloadVersion = 1;
const String _defaultDisplayName = 'Keyel';
const int _opaqueIdBytes = 8;

final RegExp _opaqueIdPattern = RegExp(r'^[0-9a-f]{16}$');
final RegExp _safeDisplayNamePattern = RegExp(r'^[A-Za-z0-9 ._-]{1,64}$');

/// A discoverable device on the local network.
///
/// This DTO deliberately contains **only** non-secret, UI-facing fields. It is
/// not a grant of trust: the `KYSYNC1` pairing code remains the sole trust root
/// for creating or joining a sync group, and manual code entry always works.
final class LocalNetworkPeer {
  /// Creates a peer description from discovery data only.
  const new({
    required this.peerId,
    required this.displayName,
    required this.address,
    required this.port,
    required this.isSameSubnet,
  });

  /// An opaque, short-lived random id. Never a sync id or a pairing code.
  final String peerId;

  /// A sanitized display name, safe to show in a picker.
  final String displayName;

  /// The source address of the discovery answer.
  final String address;

  /// The advertised answer port.
  final int port;

  /// Whether [address] matched one of our inferred local prefixes.
  ///
  /// Discovery answers from foreign subnets are rejected, so this is currently
  /// always `true` for returned peers. It is kept explicit so the UI can show
  /// the distinction and a future relaxed policy cannot silently drop it.
  final bool isSameSubnet;

  @override
  String toString() =>
      'LocalNetworkPeer(peerId: $peerId, displayName: $displayName, '
      'address: $address, port: $port, isSameSubnet: $isSameSubnet)';
}

/// LAN discovery for sync-room creation.
///
/// Security boundary:
///
/// * Same-Wi-Fi/LAN reachability is a convenience, **not authentication**.
/// * No implementation may accept, derive, log or broadcast a pairing code,
///   sync id, sync key, vault payload or any fragment of one.
/// * Answers from outside inferred local prefixes are discarded.
/// * Payloads are size-bounded, strictly typed and contain only the fields in
///   this file; unknown fields are rejected rather than forwarded.
abstract interface class LocalNetworkDiscovery {
  /// Returns a bounded list of peers that answered a local probe.
  ///
  /// Never pass a pairing code here: the API has no place to put one.
  Future<List<LocalNetworkPeer>> discover({
    Duration timeout = kLocalNetworkDiscoveryTimeout,
  });
}

/// A local, non-loopback address plus a conservative inferred prefix.
///
/// `dart:io` does not expose interface netmasks, so the prefix is inferred from
/// the address class. It is used only to reject obviously foreign answers.
final class LocalNetworkAddress {
  /// Creates an address/prefix pair.
  const new({required this.address, required this.prefixLength});

  /// Dotted IPv4 or textual IPv6 address.
  final String address;

  /// Inferred prefix length (IPv4: 16/24, IPv6: 64).
  final int prefixLength;
}

/// A raw, untrusted discovery answer. Only used by IO adapter implementations.
final class LocalNetworkDatagram {
  /// Creates a datagram envelope.
  const new({required this.address, required this.bytes});

  /// Source address as reported by the socket.
  final String address;

  /// Raw bytes, already bounded by the adapter.
  final List<int> bytes;
}

/// Test seam for interface enumeration and probing.
///
/// UI tests should override [localNetworkDiscoveryProvider] instead of this;
/// this interface exists so the IO implementation can be unit-tested without
/// opening a socket.
abstract interface class LocalNetworkAdapter {
  /// Lists usable local addresses.
  Future<List<LocalNetworkAddress>> interfaces();

  /// Announces [peerId]/[displayName] on LAN probe targets and collects answers.
  ///
  /// The adapter builds the payload so it can advertise the actual bound port.
  Future<List<LocalNetworkDatagram>> probe({
    required List<LocalNetworkAddress> addresses,
    required String peerId,
    required String displayName,
    required Duration timeout,
  });
}

/// `dart:io` discovery implementation.
///
/// This is a deliberately small subset of LocalSend's discovery:
///
/// * IPv4 interface enumeration and prefix inference (IPv6 is enumerated and
///   used for subnet checks, but no IPv6 multicast send is attempted because
///   `dart:io` does not expose a scope-safe interface binding).
/// * UDP probes on [kLocalNetworkKeyelPort] to the LocalSend multicast group,
///   limited broadcast, the inferred directed broadcast and each local address;
///   the same bounded envelope is also sent to LocalSend's 53317 as a courtesy.
/// * A short, connect-only TCP probe to [kLocalNetworkKeyelPort] on local
///   addresses. No bytes are written; this is a reachability hint, never a
///   trust signal.
/// * Answers use a compact Keyel JSON envelope over UDP. LocalSend's HTTP
///   register exchange, TLS identity, mDNS and long-lived servers are **not**
///   implemented.
///
/// All sockets are closed at the end of a pass, all receives are bounded, and
/// errors are swallowed rather than logged (no LAN data reaches a log sink).
class IoLocalNetworkAdapter implements LocalNetworkAdapter {
  /// Creates the platform adapter.
  const new();

  @override
  Future<List<LocalNetworkAddress>> interfaces() async {
    final found = <LocalNetworkAddress>[];
    final seen = <String>{};
    for (final type in <InternetAddressType>[
      InternetAddressType.IPv4,
      InternetAddressType.IPv6,
    ]) {
      final nics = await NetworkInterface.list(type: type);
      for (final nic in nics) {
        for (final address in nic.addresses) {
          if (address.isLoopback || address.isLinkLocal) continue;
          if (!seen.add(address.address)) continue;
          found.add(
            LocalNetworkAddress(
              address: address.address,
              prefixLength: inferLocalPrefixLength(address.address),
            ),
          );
          if (found.length >= kLocalNetworkMaxInterfaces) {
            return List.unmodifiable(found);
          }
        }
      }
    }
    return List.unmodifiable(found);
  }

  @override
  Future<List<LocalNetworkDatagram>> probe({
    required List<LocalNetworkAddress> addresses,
    required String peerId,
    required String displayName,
    required Duration timeout,
  }) async {
    if (addresses.isEmpty) return const <LocalNetworkDatagram>[];

    RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kLocalNetworkKeyelPort,
      );
    } on SocketException catch (_) {
      // Another process may own the port; an ephemeral port still works because
      // the advertised port comes from the socket itself.
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    }
    socket.broadcastEnabled = true;
    try {
      socket.joinMulticast(InternetAddress(kLocalNetworkMulticastGroup));
    } on Object catch (_) {
      // Multicast is unavailable on some interfaces; broadcast/unicast remain.
    }

    final payload = _encodeProbe(
      peerId: peerId,
      displayName: displayName,
      port: socket.port,
    );

    final answers = <LocalNetworkDatagram>[];
    final completer = Completer<List<LocalNetworkDatagram>>();
    var finished = false;
    StreamSubscription<RawSocketEvent>? subscription;
    Timer? timer;

    void finish() {
      if (finished) return;
      finished = true;
      timer?.cancel();
      unawaited(subscription?.cancel());
      if (!completer.isCompleted) {
        completer.complete(List.unmodifiable(answers));
      }
      socket.close();
    }

    timer = Timer(timeout, finish);
    subscription = socket.listen(
      (event) {
        if (event != RawSocketEvent.read || finished) return;
        final datagram = socket.receive();
        if (datagram == null ||
            datagram.data.length > kLocalNetworkMaxPayloadBytes) {
          return;
        }
        answers.add(
          LocalNetworkDatagram(
            address: datagram.address.address,
            bytes: datagram.data,
          ),
        );
        if (answers.length >= kLocalNetworkMaxPeers) finish();
      },
      onError: (Object error, StackTrace stackTrace) => finish(),
      onDone: finish,
    );

    for (final target in _probeTargets(addresses)) {
      for (final port in <int>[kLocalNetworkKeyelPort, kLocalNetworkPort]) {
        try {
          socket.send(payload, target, port);
        } on Object catch (_) {
          // A blocked interface must not stop discovery on the others.
        }
      }
    }

    await _tcpPresenceProbe(addresses, timeout);
    return await completer.future;
  }
}

/// Infers a conservative prefix because `dart:io` does not expose netmasks.
int inferLocalPrefixLength(String address) {
  final parsed = InternetAddress.tryParse(address);
  if (parsed == null) return 24;
  if (parsed.type == InternetAddressType.IPv6) return 64;
  final parts = address.split('.');
  if (parts.length != 4) return 24;
  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  if (first == null || second == null) return 24;
  if (first == 169 && second == 254) return 16;
  return 24;
}

/// The app-wide discovery service. Override with a fake in widget tests via
/// `localNetworkDiscoveryProvider.overrideWithValue(...)`.
final Provider<LocalNetworkDiscovery> localNetworkDiscoveryProvider =
    Provider<LocalNetworkDiscovery>((ref) => IoLocalNetworkDiscovery());

/// Default implementation of [LocalNetworkDiscovery].
class IoLocalNetworkDiscovery implements LocalNetworkDiscovery {
  /// Creates a discovery service with injectable IO for tests.
  new({
    LocalNetworkAdapter? adapter,
    String displayName = _defaultDisplayName,
    Random? random,
  }) : _adapter = adapter ?? const IoLocalNetworkAdapter(),
       _displayName = _sanitizeDisplayName(displayName) ?? _defaultDisplayName,
       _random = random ?? Random.secure();

  final LocalNetworkAdapter _adapter;
  final String _displayName;
  final Random _random;

  @override
  Future<List<LocalNetworkPeer>> discover({
    Duration timeout = kLocalNetworkDiscoveryTimeout,
  }) async {
    final deadline = timeout > Duration.zero
        ? timeout
        : kLocalNetworkDiscoveryTimeout;
    final addresses = await _interfacesWithTimeout(
      _adapter.interfaces(),
      deadline,
    );
    if (addresses.isEmpty) return const <LocalNetworkPeer>[];

    final selfId = _newOpaqueId();
    final answers = await _answersWithTimeout(
      _adapter.probe(
        addresses: addresses,
        peerId: selfId,
        displayName: _displayName,
        timeout: deadline,
      ),
      deadline,
    );

    final seenIds = <String>{};
    final peers = <LocalNetworkPeer>[];
    for (final answer in answers) {
      if (peers.length >= kLocalNetworkMaxPeers) break;
      final peer = _decodeAnswer(answer, addresses);
      if (peer == null || peer.peerId == selfId || !seenIds.add(peer.peerId)) {
        continue;
      }
      peers.add(peer);
    }
    return List.unmodifiable(peers);
  }

  String _newOpaqueId() {
    final bytes = List<int>.generate(
      _opaqueIdBytes,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

List<int> _encodeProbe({
  required String peerId,
  required String displayName,
  required int port,
}) {
  final name = _sanitizeDisplayName(displayName);
  if (name == null ||
      !_opaqueIdPattern.hasMatch(peerId) ||
      port < 1 ||
      port > 65535) {
    throw ArgumentError('Invalid local-network probe fields');
  }
  final payload = utf8.encode(
    jsonEncode(<String, Object?>{
      'kind': _probeKind,
      'v': _payloadVersion,
      'peerId': peerId,
      'displayName': name,
      'port': port,
    }),
  );
  if (payload.length > kLocalNetworkMaxPayloadBytes) {
    throw StateError('Local-network probe payload is too large');
  }
  return payload;
}

LocalNetworkPeer? _decodeAnswer(
  LocalNetworkDatagram answer,
  List<LocalNetworkAddress> addresses,
) {
  if (answer.bytes.length > kLocalNetworkMaxPayloadBytes) return null;
  final String text;
  try {
    text = utf8.decode(answer.bytes, allowMalformed: false);
  } on FormatException catch (_) {
    return null;
  }
  // Defense in depth: strict key checking below already blocks extra fields,
  // but never let a pairing-code-shaped string survive parsing.
  if (text.toUpperCase().contains('KYSYNC1')) return null;

  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (_) {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  const allowedKeys = <String>{'kind', 'v', 'peerId', 'displayName', 'port'};
  if (decoded.keys.any((key) => !allowedKeys.contains(key))) return null;
  if (decoded['v'] != _payloadVersion) return null;
  final kind = decoded['kind'];
  // Both scanners send probes, so both probes and explicit peer answers count.
  if (kind != _probeKind && kind != _peerKind) return null;

  final peerId = decoded['peerId'];
  final name = decoded['displayName'];
  final port = decoded['port'];
  if (peerId is! String || !_opaqueIdPattern.hasMatch(peerId)) return null;
  if (name is! String || _sanitizeDisplayName(name) == null) return null;
  if (port is! int || port < 1 || port > 65535) return null;

  final isSameSubnet = _isSameSubnet(answer.address, addresses);
  if (!isSameSubnet) return null;
  return LocalNetworkPeer(
    peerId: peerId,
    displayName: name,
    address: answer.address,
    port: port,
    isSameSubnet: isSameSubnet,
  );
}

String? _sanitizeDisplayName(String value) {
  final trimmed = value.trim();
  if (!_safeDisplayNamePattern.hasMatch(trimmed)) return null;
  return trimmed;
}

Future<List<LocalNetworkAddress>> _interfacesWithTimeout(
  Future<List<LocalNetworkAddress>> source,
  Duration timeout,
) async {
  final completer = Completer<List<LocalNetworkAddress>>();
  final timer = Timer(
    timeout,
    () => completer.complete(const <LocalNetworkAddress>[]),
  );
  try {
    return await Future.any<List<LocalNetworkAddress>>([
      source,
      completer.future,
    ]);
  } finally {
    timer.cancel();
  }
}

Future<List<LocalNetworkDatagram>> _answersWithTimeout(
  Future<List<LocalNetworkDatagram>> source,
  Duration timeout,
) async {
  final completer = Completer<List<LocalNetworkDatagram>>();
  final timer = Timer(
    timeout,
    () => completer.complete(const <LocalNetworkDatagram>[]),
  );
  try {
    return await Future.any<List<LocalNetworkDatagram>>([
      source,
      completer.future,
    ]);
  } finally {
    timer.cancel();
  }
}

Iterable<InternetAddress> _probeTargets(List<LocalNetworkAddress> addresses) {
  final targets = <String>{kLocalNetworkMulticastGroup, '255.255.255.255'};
  for (final address in addresses) {
    if (InternetAddress.tryParse(address.address)?.type !=
        InternetAddressType.IPv4) {
      continue;
    }
    targets.add(address.address);
    final broadcast = _directedBroadcast(address.address, address.prefixLength);
    if (broadcast != null) targets.add(broadcast);
  }
  return targets.map(InternetAddress.new).toList(growable: false);
}

String? _directedBroadcast(String address, int prefixLength) {
  final value = _ipv4ToInt(address);
  if (value == null || prefixLength <= 0 || prefixLength >= 32) return null;
  final shift = 32 - prefixLength;
  final mask = (0xFFFFFFFF << shift) & 0xFFFFFFFF;
  final broadcast = (value | (~mask & 0xFFFFFFFF)) & 0xFFFFFFFF;
  return _intToIpv4(broadcast);
}

bool _isSameSubnet(String source, List<LocalNetworkAddress> addresses) {
  final parsedSource = InternetAddress.tryParse(source);
  if (parsedSource == null || parsedSource.isLoopback) return false;
  for (final local in addresses) {
    final parsedLocal = InternetAddress.tryParse(local.address);
    if (parsedLocal == null ||
        parsedLocal.type != parsedSource.type ||
        parsedLocal.isLoopback) {
      continue;
    }
    if (parsedLocal.type == InternetAddressType.IPv4) {
      final sourceValue = _ipv4ToInt(source);
      final localValue = _ipv4ToInt(local.address);
      if (sourceValue == null || localValue == null) continue;
      final bits = local.prefixLength.clamp(0, 32);
      final mask = bits == 0 ? 0 : (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF;
      if ((sourceValue & mask) == (localValue & mask)) return true;
      continue;
    }

    final sourceBytes = parsedSource.rawAddress;
    final localBytes = parsedLocal.rawAddress;
    if (sourceBytes.length < 16 || localBytes.length < 16) continue;
    final bits = local.prefixLength.clamp(0, 128);
    final wholeBytes = bits ~/ 8;
    var matches = true;
    for (var i = 0; i < wholeBytes; i++) {
      if (sourceBytes[i] != localBytes[i]) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    final remainingBits = bits % 8;
    if (remainingBits > 0) {
      final mask = (0xFF << (8 - remainingBits)) & 0xFF;
      if ((sourceBytes[wholeBytes] & mask) != (localBytes[wholeBytes] & mask)) {
        continue;
      }
    }
    return true;
  }
  return false;
}

int? _ipv4ToInt(String address) {
  final parts = address.split('.');
  if (parts.length != 4) return null;
  var value = 0;
  for (final part in parts) {
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) return null;
    value = (value << 8) | octet;
  }
  return value;
}

String _intToIpv4(int value) =>
    '${(value >> 24) & 0xFF}.${(value >> 16) & 0xFF}.'
    '${(value >> 8) & 0xFF}.${value & 0xFF}';

Future<void> _tcpPresenceProbe(
  List<LocalNetworkAddress> addresses,
  Duration timeout,
) async {
  final milliseconds = (timeout.inMilliseconds ~/ 4).clamp(1, 150);
  final connectTimeout = Duration(milliseconds: milliseconds);
  final targets = addresses
      .where(
        (address) =>
            InternetAddress.tryParse(address.address)?.type ==
            InternetAddressType.IPv4,
      )
      .take(kLocalNetworkMaxInterfaces);
  await Future.wait<void>([
    for (final address in targets)
      _tryTcpConnect(address.address, connectTimeout),
  ]);
}

Future<void> _tryTcpConnect(String host, Duration timeout) async {
  try {
    final socket = await Socket.connect(
      host,
      kLocalNetworkKeyelPort,
      timeout: timeout,
    );
    socket.destroy();
  } on Object catch (_) {
    // Connect-only probe: no payload, no identity, no diagnostics.
  }
}
