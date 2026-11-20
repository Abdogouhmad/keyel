import 'dart:io';

import 'package:http/http.dart' as http;

/// HTTPS-only client for the HIBP k-anonymity range endpoint.
///
/// Dart sees only 5-character hash prefixes from Rust and returns only raw
/// response bodies to Rust. It never computes a hash, stores a response, or
/// chooses a URL: the endpoint is hard-coded so a compromised preference file
/// cannot redirect a prefix to an attacker-controlled host.
class BreachService {
  /// Creates the service. The HTTP client is injectable for tests.
  new({http.Client? client}) : _client = client ?? http.Client();

  /// Public Pwned Passwords range endpoint. TLS is mandatory.
  static const String endpoint = 'https://api.pwnedpasswords.com/range/';

  /// Network timeout for one range request.
  static const Duration requestTimeout = Duration(seconds: 15);

  static final RegExp _prefixPattern = RegExp(r'^[0-9A-F]{5}$');

  final http.Client _client;

  /// Fetch the range body for [prefix].
  ///
  /// The prefix is validated before it becomes part of a URL, so a bad value
  /// from Rust can never alter the request path.
  Future<String> fetchRange(String prefix) async {
    if (!_prefixPattern.hasMatch(prefix)) {
      throw ArgumentError.value(prefix, 'prefix', 'Invalid HIBP range prefix');
    }

    final uri = Uri.parse('$endpoint$prefix');
    final response = await _client
        .get(
          uri,
          headers: {
            'Accept': 'text/plain',
            'Cache-Control': 'no-cache',
            'User-Agent': 'Keyel-BreachCheck/1.7.0',
          },
        )
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'Breach check request failed with HTTP ${response.statusCode}',
        uri: uri,
      );
    }
    return response.body;
  }
}
