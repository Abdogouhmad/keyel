import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyel/core/app_info.dart';
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_service.dart';

/// Provider exposing the singleton [OtaService].
final otaServiceProvider = Provider<OtaService>((ref) {
  return OtaService();
});

/// Notifier driving the OTA updater workflow.
class OtaNotifier extends Notifier<OtaState> {
  CancelToken? _cancelToken;

  @override
  OtaState build() {
    return const OtaState(currentVersion: AppInfo.version);
  }

  OtaService get _service => ref.read(otaServiceProvider);

  /// Checks for newer releases on the configured channel.
  Future<void> checkForUpdates({bool userInitiated = true}) async {
    if (state.isChecking || state.isDownloading) return;

    state = state.copyWith(step: OtaStep.checking, errorMessage: () => null);

    try {
      final newer = await _service.checkForUpdate(
        currentVersion: state.currentVersion,
        channel: state.channel,
      );
      if (!ref.mounted) return;

      final now = DateTime.now();
      if (newer != null) {
        state = state.copyWith(
          step: OtaStep.available,
          availableRelease: () => newer,
          lastChecked: () => now,
        );
      } else {
        state = state.copyWith(
          step: OtaStep.upToDate,
          availableRelease: () => null,
          lastChecked: () => now,
        );
      }
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => e.toString().replaceFirst('Exception: ', ''),
        lastChecked: DateTime.now,
      );
    }
  }

  /// Begins downloading the available release APK.
  Future<void> startDownload() async {
    final release = state.availableRelease;
    if (release == null || state.isDownloading) return;

    _cancelToken = CancelToken();

    state = state.copyWith(
      step: OtaStep.downloading,
      downloadProgress: 0,
      bytesReceived: 0,
      totalBytes: release.fileSize,
      errorMessage: () => null,
    );

    try {
      final file = await _service.downloadRelease(
        release,
        cancelToken: _cancelToken,
        onProgress: (received, total, progress) {
          if (!ref.mounted) return;
          state = state.copyWith(
            downloadProgress: progress,
            bytesReceived: received,
            totalBytes: total,
          );
        },
      );
      if (!ref.mounted) return;

      state = state.copyWith(
        step: OtaStep.downloaded,
        downloadedFilePath: () => file.path,
        isChecksumVerified: isValidOtaChecksum(release.sha256),
        downloadProgress: 1,
      );
    } on CancellationException {
      if (!ref.mounted) return;
      state = state.copyWith(
        step: OtaStep.available,
        downloadProgress: 0,
        bytesReceived: 0,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => 'Download failed: $e',
      );
    } finally {
      _cancelToken = null;
    }
  }

  /// Cancels an in-progress download.
  void cancelDownload() {
    _cancelToken?.cancel();
  }

  /// Launches Android PackageInstaller for the downloaded update.
  Future<bool> installUpdate() async {
    final path = state.downloadedFilePath;
    if (path == null || !File(path).existsSync()) {
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => 'Update file not found on device',
      );
      return false;
    }
    if (!state.isChecksumVerified) {
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => 'Update checksum could not be verified',
      );
      return false;
    }

    try {
      final canInstall = await _service.canInstallPackages();
      if (!ref.mounted) return false;
      if (!canInstall) {
        await _service.openInstallPermissionSettings();
        return false;
      }

      state = state.copyWith(step: OtaStep.installing);
      final ok = await _service.installApk(path);
      if (!ref.mounted) return ok;
      state = state.copyWith(step: OtaStep.downloaded);
      return ok;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => 'Installation error: $e',
      );
      return false;
    }
  }

  /// Installs an APK selected locally from storage.
  Future<bool> installLocalApk(String filePath) async {
    try {
      final canInstall = await _service.canInstallPackages();
      if (!ref.mounted) return false;
      if (!canInstall) {
        await _service.openInstallPermissionSettings();
        return false;
      }
      return await _service.installApk(filePath);
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => 'Could not install APK: $e',
      );
      return false;
    }
  }

  /// Changes the release channel (Stable vs Beta).
  void setChannel(OtaChannel channel) {
    if (state.channel == channel) return;
    state = state.copyWith(
      channel: channel,
      step: OtaStep.idle,
      availableRelease: () => null,
    );
    unawaited(checkForUpdates());
  }

  /// Toggles automatic checking on startup.
  void setAutoCheck({required bool enabled}) {
    state = state.copyWith(autoCheck: enabled);
  }

  /// Dismisses an active error and returns to idle or available.
  void dismissError() {
    state = state.copyWith(
      step: state.availableRelease != null ? OtaStep.available : OtaStep.idle,
      errorMessage: () => null,
    );
  }
}

/// Main provider for OTA updater state.
final otaProvider = NotifierProvider<OtaNotifier, OtaState>(OtaNotifier.new);
