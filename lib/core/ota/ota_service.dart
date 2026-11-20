import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_platform.dart';
import 'package:path_provider/path_provider.dart';

/// Progress callback reporting received bytes, total expected bytes, and fraction (0.0 to 1.0).
typedef OtaDownloadProgressCallback = void Function(
  int receivedBytes,
  int totalBytes,
  double progress,
);

/// Strict 64-hex SHA-256, the only checksum format we install against.
final RegExp _checksumPattern = RegExp(r'^[a-fA-F0-9]{64}$');

/// Whether [value] is a usable SHA-256 checksum.
///
/// A missing or malformed checksum must fail closed: an unverified APK is
/// never offered as an update, downloaded, or handed to the installer.
bool isValidOtaChecksum(String? value) =>
    value != null && _checksumPattern.hasMatch(value.trim());

/// Service providing network release checks, chunked APK downloading,
/// SHA-256 verification and handoff to the platform installer.
class OtaService {
  /// Creates the service with default or custom platform / HTTP client.
  new({
    this.repo = 'Abdogouhmad/keyel',
    http.Client? client,
    OtaPlatform? platform,
    this.customManifestUrl,
  }) : _client = client ?? http.Client(),
       _platform = platform ?? const OtaPlatform();

  /// GitHub repository in `owner/repo` format.
  final String repo;

  /// Optional custom manifest URL overriding the built-in release source.
  final String? customManifestUrl;

  final http.Client _client;
  final OtaPlatform _platform;

  /// URI of the committed OTA manifest (`update_manifest.json`).
  ///
  /// `raw.githubusercontent.com` is fronted by a CDN that can serve a stale
  /// copy for minutes after a release is committed; a per-request timestamp
  /// varies the cache key, so a check reads the manifest that was just
  /// published. The server ignores the query string when resolving the path.
  Uri manifestUri({DateTime? now}) {
    final base =
        customManifestUrl ??
        'https://raw.githubusercontent.com/$repo/main/update_manifest.json';
    final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return Uri.parse('$base?ts=$stamp');
  }

  /// Checks for newer releases matching the selected [channel].
  Future<OtaRelease?> checkForUpdate({
    required String currentVersion,
    OtaChannel channel = OtaChannel.stable,
  }) async {
    final releases = await fetchReleases(channel: channel);
    if (releases.isEmpty) return null;

    for (final release in releases) {
      if (channel == OtaChannel.stable && release.isPrerelease) {
        continue;
      }
      if (compareVersions(release.version, currentVersion) > 0) {
        return release;
      }
    }
    return null;
  }

  /// Fetches the candidate releases for [channel].
  ///
  /// The stable channel reads the committed `update_manifest.json` — the file
  /// the release workflow rewrites on every publish, and the only source that
  /// carries the APK's SHA-256. The beta channel reads the GitHub Releases API
  /// so pre-releases keep working. A `customManifestUrl` overrides both and is
  /// parsed as either shape.
  Future<List<OtaRelease>> fetchReleases({
    OtaChannel channel = OtaChannel.stable,
  }) async {
    final uri = customManifestUrl != null
        ? manifestUri()
        : channel == OtaChannel.beta
        ? Uri.parse('https://api.github.com/repos/$repo/releases')
        : manifestUri();

    final response = await _client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
            'User-Agent': 'Keyel-OTA-Updater',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to check for updates: HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      // The committed OTA manifest is a single-release object.
      final manifest = _parseManifest(decoded);
      if (manifest != null) return [manifest];
      final single = _parseSingleRelease(decoded);
      return single != null ? [single] : [];
    }
    if (decoded is! List) return [];

    final releases = <OtaRelease>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final parsed = _parseSingleRelease(item);
        if (parsed != null) {
          releases.add(parsed);
        }
      }
    }
    return releases;
  }

  /// Parses the committed OTA manifest (`update_manifest.json`).
  ///
  /// Returns `null` when [json] is not a manifest (for example a GitHub release
  /// object), so the caller can fall back to [_parseSingleRelease].
  OtaRelease? _parseManifest(Map<String, dynamic> json) {
    final version = (json['latestVersionName'] as String? ?? '').trim();
    final apkUrl = (json['apkUrl'] as String? ?? '').trim();
    if (version.isEmpty || apkUrl.isEmpty) return null;

    final publishedAtStr = json['publishedAt'] as String?;
    final sha256 = json['sha256'] as String?;
    // A publish with a missing/malformed hash is a broken release, not an
    // unverified one we should offer to install.
    if (!isValidOtaChecksum(sha256)) return null;
    return OtaRelease(
      version: version,
      tagName: 'v$version',
      title: 'Keyel $version',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      publishedAt: publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
          : DateTime.now(),
      downloadUrl: apkUrl,
      fileName: apkUrl.split('/').last,
      fileSize: json['size'] as int? ?? 0,
      sha256: sha256!.trim(),
    );
  }

  OtaRelease? _parseSingleRelease(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    var version = tagName;
    if (version.startsWith('v') || version.startsWith('V')) {
      version = version.substring(1);
    }
    if (version.isEmpty) return null;

    final name = json['name'] as String? ?? 'Release $tagName';
    final body = json['body'] as String? ?? '';
    final prerelease = json['prerelease'] as bool? ?? false;
    final publishedAtStr = json['published_at'] as String?;
    final publishedAt = publishedAtStr != null
        ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
        : DateTime.now();

    final assets = json['assets'] as List<dynamic>? ?? [];

    // Find the APK asset: prefer arm64 or universal, else any .apk
    Map<String, dynamic>? chosenAsset;
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final assetName = (asset['name'] as String? ?? '').toLowerCase();
        if (assetName.endsWith('.apk')) {
          if (chosenAsset == null) {
            chosenAsset = asset;
          } else if (assetName.contains('arm64') ||
              assetName.contains('universal')) {
            chosenAsset = asset;
          }
        }
      }
    }

    if (chosenAsset == null) return null;

    final downloadUrl = chosenAsset['browser_download_url'] as String? ?? '';
    if (downloadUrl.isEmpty) return null;

    final fileName = chosenAsset['name'] as String? ?? 'keyel-update.apk';
    final fileSize = chosenAsset['size'] as int? ?? 0;

    // Search for a SHA-256 hash in the release body
    String? sha256Checksum;
    final hashRegex = RegExp(r'\b([a-fA-F0-9]{64})\b');
    final match = hashRegex.firstMatch(body);
    if (match != null) {
      sha256Checksum = match.group(1);
    }
    // The GitHub Releases body is authored text, so the hash may be absent or
    // malformed. Fail closed instead of installing an unverified APK.
    if (!isValidOtaChecksum(sha256Checksum)) return null;

    return OtaRelease(
      version: version,
      tagName: tagName,
      title: name,
      releaseNotes: body,
      publishedAt: publishedAt,
      downloadUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileSize,
      sha256: sha256Checksum!.trim(),
      isPrerelease: prerelease,
    );
  }

  /// Downloads the release APK with chunking, calculates SHA-256 on the fly,
  /// and writes to temporary storage.
  Future<File> downloadRelease(
    OtaRelease release, {
    OtaDownloadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    // Second line of defence: callers may construct a release directly rather
    // than going through the parsers. Never fetch or install without a hash.
    if (!isValidOtaChecksum(release.sha256)) {
      throw StateError(
        'Refusing to download an update without a valid SHA-256 checksum',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final cleanFileName = release.fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final saveFile = File('${tempDir.path}/$cleanFileName');

    if (saveFile.existsSync()) {
      try {
        saveFile.deleteSync();
      } on Object catch (_) {}
    }

    final request = http.Request('GET', Uri.parse(release.downloadUrl));
    request.headers['User-Agent'] = 'Keyel-OTA-Updater';
    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      throw HttpException(
        'Download failed with HTTP ${streamedResponse.statusCode}',
        uri: Uri.parse(release.downloadUrl),
      );
    }

    final totalBytes = streamedResponse.contentLength ?? release.fileSize;
    var receivedBytes = 0;

    final sink = saveFile.openWrite();

    try {
      await for (final chunk in streamedResponse.stream) {
        if (cancelToken?.isCancelled == true) {
          await sink.close();
          if (saveFile.existsSync()) saveFile.deleteSync();
          throw const CancellationException('Download cancelled by user');
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        if (onProgress != null) {
          final fraction = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
          onProgress(receivedBytes, totalBytes, fraction.clamp(0.0, 1.0));
        }
      }

      await sink.flush();
      await sink.close();
    } on Object catch (_) {
      await sink.close();
      if (saveFile.existsSync()) {
        try {
          saveFile.deleteSync();
        } on Object catch (_) {}
      }
      rethrow;
    }

    // Verification is mandatory, never conditional (see T13).
    final digest = await sha256.bind(saveFile.openRead()).first;
    final computed = digest.toString().toLowerCase();
    final expected = release.sha256!.trim().toLowerCase();
    if (computed != expected) {
      if (saveFile.existsSync()) {
        try {
          saveFile.deleteSync();
        } on Object catch (_) {}
      }
      throw StateError(
        'Checksum mismatch: expected $expected but got $computed',
      );
    }

    return saveFile;
  }

  /// Verifies an APK file's SHA-256 against an expected hash.
  Future<bool> verifyFileChecksum(File file, String expectedSha256) async {
    if (!file.existsSync()) return false;
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase() ==
        expectedSha256.trim().toLowerCase();
  }

  /// Hands off an APK file to Android for installation.
  Future<bool> installApk(String filePath) {
    return _platform.installApk(filePath);
  }

  /// Checks if permission to install unknown apps is granted.
  Future<bool> canInstallPackages() {
    return _platform.canInstallPackages();
  }

  /// Opens install-unknown-apps permission settings.
  Future<void> openInstallPermissionSettings() {
    return _platform.openInstallPermissionSettings();
  }
}

/// Token to allow user to abort an in-flight download.
class CancelToken {
  bool _cancelled = false;

  /// Returns true if cancelled.
  bool get isCancelled => _cancelled;

  /// Signals cancellation.
  void cancel() {
    _cancelled = true;
  }
}

/// Exception thrown when download is user-cancelled.
class CancellationException implements Exception {
  /// Creates the exception with a message.
  const new(this.message);

  /// Human-readable explanation.
  final String message;

  @override
  String toString() => message;
}
