/// Canonical identity of an autofill target, used by "Never for this site".
///
/// The identity deliberately mirrors the Rust matcher's trust rules in
/// `crates/keyel_core/src/autofill.rs`: a web domain is only a fill target when
/// no app package was reported, or when the reporter is a known browser. For
/// every other app we deny the package, never a WebView domain the app could
/// spoof. Values are non-secret and are stored in `settings.json`.
library;

/// Packages whose reported web domain is trusted as a fill target.
const trustedAutofillBrowsers = <String>{
  'com.android.chrome',
  'com.chrome.beta',
  'com.chrome.dev',
  'com.chrome.canary',
  'com.google.android.apps.chrome',
  'com.android.browser',
  'org.mozilla.firefox',
  'org.mozilla.firefox_beta',
  'org.mozilla.fennec_fdroid',
  'com.microsoft.emmx',
  'com.brave.browser',
  'com.opera.browser',
  'com.opera.mini.native',
  'com.duckduckgo.mobile.android',
  'com.vivaldi.browser',
};

/// Normalizes [value] to a lowercase host without scheme, port, path, `www.`
/// or a trailing dot. Returns `null` for blank or whitespace-containing input.
String? normalizeAutofillHost(String? value) {
  if (value == null) return null;
  var host = value.trim().toLowerCase();
  if (host.isEmpty || host.contains(RegExp(r'\s'))) return null;
  final scheme = host.indexOf('://');
  if (scheme >= 0) host = host.substring(scheme + 3);
  final slash = host.indexOf('/');
  if (slash >= 0) host = host.substring(0, slash);
  final colon = host.indexOf(':');
  if (colon >= 0) host = host.substring(0, colon);
  if (host.startsWith('www.')) host = host.substring(4);
  while (host.endsWith('.')) {
    host = host.substring(0, host.length - 1);
  }
  if (host.isEmpty || !host.contains('.')) return null;
  return host;
}

/// Returns the canonical deny key for a target, or `null` when the target has
/// no trustworthy identity (for example a browser with no reported domain).
String? canonicalAutofillTarget({
  required String? package,
  required String? webDomain,
}) {
  final pkg = package?.trim().toLowerCase();
  final host = normalizeAutofillHost(webDomain);
  final hasPackage = pkg != null && pkg.isNotEmpty;

  // Never deny a browser package itself: that would disable Keyel for every
  // site. Deny the specific host instead.
  if (!hasPackage || trustedAutofillBrowsers.contains(pkg)) {
    return host == null ? null : 'host:$host';
  }
  return 'package:$pkg';
}

/// Whether [target] is a valid canonical key produced by
/// [canonicalAutofillTarget]. Used when loading persisted values.
bool isValidAutofillTarget(String target) {
  if (target.startsWith('host:')) {
    final host = normalizeAutofillHost(target.substring(5));
    return host != null && target == 'host:$host';
  }
  if (target.startsWith('package:')) {
    final pkg = target.substring(8);
    return pkg.isNotEmpty &&
        !pkg.contains(RegExp(r'\s')) &&
        pkg == pkg.toLowerCase();
  }
  return false;
}
