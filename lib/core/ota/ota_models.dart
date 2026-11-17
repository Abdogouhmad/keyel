import 'package:flutter/foundation.dart';

/// Update release channel.
enum OtaChannel {
  /// Stable, production-ready releases only.
  stable('Stable', 'Official verified releases'),

  /// Beta releases for testing upcoming features.
  beta('Beta', 'Pre-release previews with latest features');

  new(this.label, this.description);

  /// Human-readable label.
  final String label;

  /// Channel description.
  final String description;
}

/// Lifecycle step of the OTA updater.
enum OtaStep {
  /// Idle, no update in progress.
  idle,

  /// Checking GitHub/server for latest release.
  checking,

  /// Currently on the latest version.
  upToDate,

  /// A newer release is available for download.
  available,

  /// Downloading the release APK.
  downloading,

  /// APK downloaded and integrity verified.
  downloaded,

  /// Invoking package installer.
  installing,

  /// An error occurred during check, download or install.
  error,
}

/// Metadata representing an available OTA release.
@immutable
class OtaRelease {
  /// Creates an OTA release descriptor.
  const new({
    required this.version,
    required this.tagName,
    required this.title,
    required this.releaseNotes,
    required this.publishedAt,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    this.sha256,
    this.isPrerelease = false,
  });

  /// Semantic version string (e.g. `1.1.0`).
  final String version;

  /// Git tag name (e.g. `v1.1.0`).
  final String tagName;

  /// Release title or name.
  final String title;

  /// Markdown release notes or changelog.
  final String releaseNotes;

  /// Publication timestamp.
  final DateTime publishedAt;

  /// Direct download URL for the APK asset.
  final String downloadUrl;

  /// File name of the APK (e.g. `keyel-v1.1.0-universal.apk`).
  final String fileName;

  /// File size in bytes.
  final int fileSize;

  /// Optional expected SHA-256 checksum.
  final String? sha256;

  /// Whether this release is marked as pre-release / beta.
  final bool isPrerelease;

  /// Formatted human-readable file size (e.g. "18.4 MB").
  String get formattedSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Complete immutable state of the OTA subsystem.
@immutable
class OtaState {
  /// Creates the OTA state.
  const new({
    required this.currentVersion,
    this.step = OtaStep.idle,
    this.availableRelease,
    this.downloadProgress = 0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.downloadedFilePath,
    this.isChecksumVerified = false,
    this.lastChecked,
    this.errorMessage,
    this.channel = OtaChannel.stable,
    this.autoCheck = true,
  });

  /// Current step in update lifecycle.
  final OtaStep step;

  /// Installed app version (e.g. `1.1.0`).
  final String currentVersion;

  /// Newer release if one is available.
  final OtaRelease? availableRelease;

  /// Download progress between 0.0 and 1.0.
  final double downloadProgress;

  /// Bytes downloaded so far.
  final int bytesReceived;

  /// Total expected bytes of the download.
  final int totalBytes;

  /// Local path where the downloaded APK is cached.
  final String? downloadedFilePath;

  /// Whether the downloaded file has been verified against SHA-256.
  final bool isChecksumVerified;

  /// When the last update check was performed.
  final DateTime? lastChecked;

  /// Error message if [step] is [OtaStep.error].
  final String? errorMessage;

  /// Selected release channel.
  final OtaChannel channel;

  /// Whether automatic update check on start is enabled.
  final bool autoCheck;

  /// Whether an update check is currently running.
  bool get isChecking => step == OtaStep.checking;

  /// Whether an APK download is in progress.
  bool get isDownloading => step == OtaStep.downloading;

  /// Whether an update is available to download.
  bool get hasUpdate =>
      (step == OtaStep.available ||
          step == OtaStep.downloading ||
          step == OtaStep.downloaded) &&
      availableRelease != null;

  /// Whether an update is downloaded and ready to install.
  bool get isReadyToInstall =>
      step == OtaStep.downloaded &&
      downloadedFilePath != null &&
      downloadedFilePath!.isNotEmpty;

  /// Returns a copy with updated properties.
  OtaState copyWith({
    OtaStep? step,
    String? currentVersion,
    OtaRelease? Function()? availableRelease,
    double? downloadProgress,
    int? bytesReceived,
    int? totalBytes,
    String? Function()? downloadedFilePath,
    bool? isChecksumVerified,
    DateTime? Function()? lastChecked,
    String? Function()? errorMessage,
    OtaChannel? channel,
    bool? autoCheck,
  }) {
    return OtaState(
      step: step ?? this.step,
      currentVersion: currentVersion ?? this.currentVersion,
      availableRelease: availableRelease != null
          ? availableRelease()
          : this.availableRelease,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedFilePath: downloadedFilePath != null
          ? downloadedFilePath()
          : this.downloadedFilePath,
      isChecksumVerified: isChecksumVerified ?? this.isChecksumVerified,
      lastChecked: lastChecked != null ? lastChecked() : this.lastChecked,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      channel: channel ?? this.channel,
      autoCheck: autoCheck ?? this.autoCheck,
    );
  }
}

/// Compares two semver strings (e.g. `1.1.0` vs `1.0.0`).
/// Returns positive if [v1] > [v2], negative if [v1] < [v2], 0 if equal.
int compareVersions(String v1, String v2) {
  List<int> parse(String v) {
    var clean = v.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }
    final plusIndex = clean.indexOf('+');
    if (plusIndex != -1) {
      clean = clean.substring(0, plusIndex);
    }
    final dashIndex = clean.indexOf('-');
    if (dashIndex != -1) {
      clean = clean.substring(0, dashIndex);
    }
    return clean.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  final p1 = parse(v1);
  final p2 = parse(v2);

  final maxLen = p1.length > p2.length ? p1.length : p2.length;
  for (var i = 0; i < maxLen; i++) {
    final num1 = i < p1.length ? p1[i] : 0;
    final num2 = i < p2.length ? p2[i] : 0;
    if (num1 != num2) {
      return num1.compareTo(num2);
    }
  }
  return 0;
}
