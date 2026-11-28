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
/// discover Keyel peers without a port collision. Scanners bind this port with
/// `reusePort` (falling back to an ephemeral port); presence beacons are sent
/// to it without opening a listening socket.
const int kLocalNetworkKeyelPort = 53318;

/// Default deadline for one discovery pass.
const Duration kLocalNetworkDiscoveryTimeout = Duration(milliseconds: 1500);

/// Hard cap on peers returned by one discovery pass.
const int kLocalNetworkMaxPeers = 16;

/// Hard cap on accepted/sent discovery datagrams.
const int kLocalNetworkMaxPayloadBytes = 512;

/// Maximum number of local interfaces considered in one pass.
const int kLocalNetworkMaxInterfaces = 4;

/// How often one discovery pass repeats its probe.
///
/// Multicast and broadcast are best-effort; repeating a tiny, bounded datagram
/// makes a pass reliable without turning discovery into a long-lived scanner.
const Duration kLocalNetworkProbeRepeat = Duration(milliseconds: 400);

/// How often an unlocked device advertises its non-secret presence.
const Duration kLocalNetworkBeaconInterval = Duration(seconds: 2);

const String _probeKind = 'keyel-probe';

/// Accepted for forward/backward compatibility with explicit peer answers.
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

  /// Whether [address] is a plausible LAN address for this device.
  ///
  /// Discovery answers from public or loopback addresses are rejected, so this
  /// is always `true` for returned peers. It stays explicit so the UI can show
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

  /// Starts advertising this device on the local network while the vault is
  /// unlocked, so another device can find it without a locked peer.
  ///
  /// Implementations must never put secrets in the announcement. The default
  /// keeps fake/test implementations inert.
  Future<void> startPresence() => Future<void>.value();

  /// Stops advertising this device.
  Future<void> stopPresence() => Future<void>.value();
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

  /// Starts a bounded, outbound-only UDP beacon for Keyel discovery.
  ///
  /// A beacon is the other half of discovery: without it, two devices only see
  /// each other when they happen to scan during the same narrow window. It uses
  /// no listening socket and carries no secrets.
  Future<void> startBeacon({
    required List<LocalNetworkAddress> addresses,
    required String peerId,
    required String displayName,
  }) => Future<void>.value();

  /// Stops the beacon opened by [startBeacon].
  Future<void> stopBeacon() => Future<void>.value();
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
/// * A bounded, outbound-only presence beacon from an ephemeral socket while
///   the vault is unlocked. It repeats the same non-secret envelope on the
///   probe targets, so a device does not have to be scanning at the exact same
///   moment to be found, and needs no listening/server entitlement.
/// * Announcements use a compact Keyel JSON envelope over UDP. LocalSend's HTTP
///   register exchange, TLS identity, mDNS and long-lived servers are **not**
///   implemented.
///
/// All sockets are closed at the end of a pass, all receives are bounded, and
/// errors are swallowed rather than logged (no LAN data reaches a log sink).
class IoLocalNetworkAdapter implements LocalNetworkAdapter {
  /// Creates the platform adapter.
  new();

  RawDatagramSocket? _beaconSocket;
  Timer? _beaconTimer;

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
  Future<void> startBeacon({
    required List<LocalNetworkAddress> addresses,
    required String peerId,
    required String displayName,
  }) async {
    if (_beaconTimer != null) return;
    if (addresses.isEmpty) return;

    // An ephemeral outbound-only socket is enough to advertise presence. This
    // avoids needing a listening/server entitlement on macOS and avoids a port
    // collision with scanners or other apps.
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reusePort: true,
    );
    if (_beaconTimer != null) {
      socket.close();
      return;
    }
    socket.broadcastEnabled = true;
    final payload = _encodeProbe(
      peerId: peerId,
      displayName: displayName,
      port: socket.port,
    );
    void sendBeacon() {
      for (final target in _probeTargets(addresses)) {
        for (final port in <int>[kLocalNetworkKeyelPort, kLocalNetworkPort]) {
          try {
            socket.send(payload, target, port);
          } on Object catch (_) {
            // Best effort: one blocked interface must not stop the beacon.
          }
        }
      }
    }

    _beaconSocket = socket;
    sendBeacon();
    _beaconTimer = Timer.periodic(
      kLocalNetworkBeaconInterval,
      (_) => sendBeacon(),
    );
  }

  @override
  Future<void> stopBeacon() async {
    final timer = _beaconTimer;
    final socket = _beaconSocket;
    _beaconTimer = null;
    _beaconSocket = null;
    timer?.cancel();
    socket?.close();
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
        reusePort: true,
      );
    } on Object catch (_) {
      // Another process may own the port; an ephemeral port still works because
      // the advertised port comes from the socket itself and responders answer
      // the datagram's actual source port.
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reusePort: true,
      );
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
    Timer? repeat;

    void finish() {
      if (finished) return;
      finished = true;
      timer?.cancel();
      repeat?.cancel();
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

    void sendProbe() {
      for (final target in _probeTargets(addresses)) {
        for (final port in <int>[kLocalNetworkKeyelPort, kLocalNetworkPort]) {
          try {
            socket.send(payload, target, port);
          } on Object catch (_) {
            // A blocked interface must not stop discovery on the others.
          }
        }
      }
    }

    sendProbe();
    repeat = Timer.periodic(kLocalNetworkProbeRepeat, (_) => sendProbe());
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
  }) : _adapter = adapter ?? IoLocalNetworkAdapter(),
       _displayName = _sanitizeDisplayName(displayName) ?? _defaultDisplayName,
       _random = random ?? Random.secure();

  final LocalNetworkAdapter _adapter;
  final String _displayName;
  final Random _random;

  /// Stable while this process is alive, so a scanner never mistakes the
  /// app's own beacon for a nearby peer.
  String? _presenceId;
  bool _presenceActive = false;
  int _presenceGeneration = 0;
  Future<void> _presenceQueue = Future<void>.value();

  @override
  Future<void> startPresence() {
    final generation = ++_presenceGeneration;
    return _enqueuePresence(() async {
      // Interfaces are cheap, but a hung platform query must not block presence.
      final addresses = await _interfacesWithTimeout(
        _adapter.interfaces(),
        const Duration(milliseconds: 500),
      );
      if (generation != _presenceGeneration) return;
      if (addresses.isEmpty) return;

      final peerId = _presenceId ?? _newOpaqueId();
      await _adapter.startBeacon(
        addresses: addresses,
        peerId: peerId,
        displayName: _displayName,
      );
      if (generation != _presenceGeneration) {
        await _adapter.stopBeacon();
        return;
      }
      _presenceId = peerId;
      _presenceActive = true;
    });
  }

  @override
  Future<void> stopPresence() {
    _presenceGeneration++;
    return _enqueuePresence(() async {
      _presenceActive = false;
      await _adapter.stopBeacon();
    });
  }

  /// Serializes presence transitions so a slow stop cannot close a socket that
  /// a newer start has just opened.
  Future<void> _enqueuePresence(Future<void> Function() action) {
    final next = _presenceQueue.then((_) => action());
    _presenceQueue = () async {
      try {
        await next;
      } on Object catch (_) {
        // Keep the queue usable; callers still receive the original error.
      }
    }();
    return next;
  }

  /// Whether this service is currently announcing non-secret presence.
  bool get isPresenceActive => _presenceActive;

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

    final selfId = _presenceId ?? _newOpaqueId();
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
}) => _encodeEnvelope(
  kind: _probeKind,
  peerId: peerId,
  displayName: displayName,
  port: port,
);

List<int> _encodeEnvelope({
  required String kind,
  required String peerId,
  required String displayName,
  required int port,
}) {
  final name = _sanitizeDisplayName(displayName);
  if (name == null ||
      !_opaqueIdPattern.hasMatch(peerId) ||
      port < 1 ||
      port > 65535) {
    throw ArgumentError('Invalid local-network discovery fields');
  }
  final payload = utf8.encode(
    jsonEncode(<String, Object?>{
      'kind': kind,
      'v': _payloadVersion,
      'peerId': peerId,
      'displayName': name,
      'port': port,
    }),
  );
  if (payload.length > kLocalNetworkMaxPayloadBytes) {
    throw StateError('Local-network discovery payload is too large');
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
  // Scanners emit probes; an explicit peer answer from a future/other Keyel
  // build is still accepted, but neither kind carries identity or secrets.
  if (kind != _probeKind && kind != _peerKind) return null;

  final peerId = decoded['peerId'];
  final name = decoded['displayName'];
  final port = decoded['port'];
  if (peerId is! String || !_opaqueIdPattern.hasMatch(peerId)) return null;
  if (name is! String || _sanitizeDisplayName(name) == null) return null;
  if (port is! int || port < 1 || port > 65535) return null;

  final isSameSubnet = _isLocalNetworkAddress(answer.address, addresses);
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

/// Accepts only addresses that can plausibly belong to a local network.
///
/// `dart:io` does not expose interface netmasks, so inferring `/24` from the
/// address class rejects valid `10.0.0.0/8` and `172.16.0.0/12` Wi-Fi networks.
/// Private/link-local ranges are accepted instead; public addresses are still
/// discarded. Same-prefix checks remain as a fallback for unusual LAN ranges.
bool _isLocalNetworkAddress(
  String source,
  List<LocalNetworkAddress> addresses,
) {
  final parsedSource = InternetAddress.tryParse(source);
  if (parsedSource == null || parsedSource.isLoopback) return false;
  if (parsedSource.type == InternetAddressType.IPv4) {
    if (_isPrivateIPv4(source)) return true;
  } else if (_isLinkLocalIPv6(parsedSource) ||
      _isUniqueLocalIPv6(parsedSource)) {
    return true;
  }

  for (final local in addresses) {
    final parsedLocal = InternetAddress.tryParse(local.address);
    if (parsedLocal == null ||
        parsedLocal.type != parsedSource.type ||
        parsedLocal.isLoopback) {
      continue;
    }
    if (parsedSource.type == InternetAddressType.IPv4) {
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

bool _isPrivateIPv4(String address) {
  final parts = address.split('.').map(int.tryParse).toList(growable: false);
  if (parts.length != 4 ||
      parts.any((part) => part == null || part < 0 || part > 255)) {
    return false;
  }
  final first = parts[0]!;
  final second = parts[1]!;
  if (first == 10 || (first == 169 && second == 254)) return true;
  if (first == 172 && second >= 16 && second <= 31) return true;
  return first == 192 && second == 168;
}

bool _isLinkLocalIPv6(InternetAddress address) {
  final bytes = address.rawAddress;
  return bytes.length == 16 && bytes[0] == 0xFE && (bytes[1] & 0xC0) == 0x80;
}

bool _isUniqueLocalIPv6(InternetAddress address) {
  final bytes = address.rawAddress;
  return bytes.length == 16 && (bytes[0] & 0xFE) == 0xFC;
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
