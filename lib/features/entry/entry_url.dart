import 'package:url_launcher/url_launcher.dart';

/// Normalizes a website value stored on a vault entry into a launchable URI.
///
/// Bare hosts such as `example.com` or `example.com:8080` are upgraded to
/// `https://…` before parsing. Values that already carry a scheme keep it
/// when it is `http` or `https`; every other scheme (`mailto:`, `otpauth://`,
/// `javascript:`, …) yields `null` so callers can show feedback instead of
/// launching. Blank or unparseable values also yield `null`.
Uri? normalizeEntryUrl(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;

  final parsed = Uri.tryParse(raw);
  if (parsed != null && parsed.hasScheme) {
    final scheme = parsed.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return parsed.host.isNotEmpty ? parsed : null;
    }
    // `example.com:8080` parses with the host masquerading as the scheme;
    // dotted "schemes" are really hosts and are upgraded to https below.
    if (!scheme.contains('.')) return null;
  }

  final upgraded = Uri.tryParse('https://$raw');
  return upgraded != null && upgraded.host.isNotEmpty ? upgraded : null;
}

/// Launches [uri] in the user's default external application.
///
/// Resolves `false` when the platform throws or refuses, so callers can show
/// feedback instead of surfacing an unhandled platform error.
Future<bool> launchEntryUrl(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
