import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyel/core/app_info.dart';
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_service.dart';
import 'package:keyel/core/platform/update_notifications.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Provider exposing the singleton [OtaService].
final otaServiceProvider = Provider<OtaService>((ref) {
  return OtaService();
});

/// Notifier driving the OTA updater workflow.
class OtaNotifier extends Notifier<OtaState> {
  CancelToken? _cancelToken;

  AppPreferences get _prefs => AppPreferences.instance;

  OtaService get _service => ref.read(otaServiceProvider);

  UpdateNotificationPlatform get _notifications =>
      ref.read(updateNotificationProvider);

  @override
  OtaState build() {
    final prefs = _prefs;
    final lastCheck = prefs.otaLastCheckedMs;
    return OtaState(
      currentVersion: AppInfo.version,
      channel: prefs.otaChannel == 'beta' ? OtaChannel.beta : OtaChannel.stable,
      autoCheck: prefs.otaAutoCheck,
      lastChecked: lastCheck == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastCheck),
      dismissedVersion: prefs.otaDismissedVersion,
    );
  }

  /// Checks for newer releases on the configured channel.
  ///
  /// Silent checks ([userInitiated] `false`) do not surface transient network
  /// errors and post an OS notification only for a newly discovered version.
  Future<void> checkForUpdates({bool userInitiated = true}) async {
    if (state.isChecking || state.isDownloading) return;

    final previousStep = state.step;
    state = state.copyWith(step: OtaStep.checking, errorMessage: () => null);

    try {
      final newer = await _service.checkForUpdate(
        currentVersion: state.currentVersion,
        channel: state.channel,
      );
      if (!ref.mounted) return;

      final now = DateTime.now();
      _prefs.otaLastCheckedMs = now.millisecondsSinceEpoch;
      await _prefs.save();
      if (!ref.mounted) return;

      if (newer != null) {
        state = state.copyWith(
          step: OtaStep.available,
          availableRelease: () => newer,
          lastChecked: () => now,
          dismissedVersion: () => _prefs.otaDismissedVersion,
        );
        if (!userInitiated) {
          await _maybeNotify(newer);
        }
      } else {
        state = state.copyWith(
          step: OtaStep.upToDate,
          availableRelease: () => null,
          lastChecked: () => now,
        );
      }
    } on Object catch (e) {
      if (!ref.mounted) return;
      if (userInitiated) {
        state = state.copyWith(
          step: OtaStep.error,
          errorMessage: () => e.toString().replaceFirst('Exception: ', ''),
          lastChecked: DateTime.now,
        );
      } else {
        // A background check must not replace useful UI or flash an error.
        state = state.copyWith(step: previousStep, lastChecked: DateTime.now);
      }
    }
  }

  Future<void> _maybeNotify(OtaRelease release) async {
    if (!state.autoCheck || _prefs.otaLastNotifiedVersion == release.version) {
      return;
    }
    final shown = await _notifications.showUpdateAvailable(
      version: release.version,
      channel: state.channel.label,
    );
    if (!shown || !ref.mounted) return;

    _prefs.otaLastNotifiedVersion = release.version;
    await _prefs.save();
    if (!ref.mounted) return;
    state = state.copyWith(notificationsEnabled: true);
  }

  /// Refreshes the cached Android notification-permission state.
  Future<void> refreshNotificationPermission() async {
    final enabled = await _notifications.areNotificationsEnabled();
    if (!ref.mounted) return;
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// Requests notification permission once, remembering the prompt.
  Future<bool> requestNotifications() async {
    // Set the flag before awaiting so a second resume cannot prompt twice.
    final prefs = _prefs..otaNotificationPromptShown = true;
    await prefs.save();
    final granted = await _notifications.requestPermission();
    if (!ref.mounted) return granted;
    state = state.copyWith(notificationsEnabled: granted);
    return granted;
  }

  /// Prompts for notifications on the first automatic check, then stays quiet.
  ///
  /// When the prompt was already shown this only refreshes the cached state,
  /// so a permission granted in Android settings is reflected in the UI.
  Future<void> maybePromptForNotifications() async {
    if (!state.autoCheck) return;
    if (_prefs.otaNotificationPromptShown) {
      await refreshNotificationPermission();
      return;
    }
    await requestNotifications();
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
        errorMessage: () => currentL10n.otaDownloadFailed('$e'),
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
        errorMessage: () => currentL10n.otaUpdateFileNotFound,
      );
      return false;
    }
    final expectedSha256 = state.availableRelease?.sha256;
    if (!state.isChecksumVerified ||
        expectedSha256 == null ||
        !isValidOtaChecksum(expectedSha256)) {
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => currentL10n.otaChecksumNotVerified,
      );
      return false;
    }

    try {
      // Permission prompts can take arbitrary time, so settle them first. The
      // re-hash below is then the last await before handing the file over.
      final canInstall = await _service.canInstallPackages();
      if (!ref.mounted) return false;
      if (!canInstall) {
        await _service.openInstallPermissionSettings();
        return false;
      }
      state = state.copyWith(step: OtaStep.installing);

      // The file can be replaced between download and install. Re-hash it at
      // the last possible moment and drop it if it no longer matches.
      final stillValid = await _service.verifyFileChecksum(
        File(path),
        expectedSha256,
      );
      if (!ref.mounted) return false;
      if (!stillValid) {
        try {
          File(path).deleteSync();
        } on Object catch (_) {}
        state = state.copyWith(
          step: OtaStep.error,
          errorMessage: () => currentL10n.otaReverifyFailed,
          isChecksumVerified: false,
          downloadedFilePath: () => null,
        );
        return false;
      }

      final ok = await _service.installApk(path);
      if (!ref.mounted) return ok;
      state = state.copyWith(step: OtaStep.downloaded);
      return ok;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        step: OtaStep.error,
        errorMessage: () => currentL10n.otaInstallationError('$e'),
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
        errorMessage: () => currentL10n.otaCouldNotInstallApk('$e'),
      );
      return false;
    }
  }

  /// Changes the release channel (Stable vs Beta) and rechecks immediately.
  Future<void> setChannel(OtaChannel channel) async {
    if (state.channel == channel) return;
    final prefs = _prefs
      ..otaChannel = channel == OtaChannel.beta ? 'beta' : 'stable'
      ..otaDismissedVersion = null;
    await prefs.save();
    if (!ref.mounted) return;

    state = state.copyWith(
      channel: channel,
      step: OtaStep.idle,
      availableRelease: () => null,
      dismissedVersion: () => null,
    );
    await checkForUpdates();
  }

  /// Persists the automatic-check preference and requests permission if on.
  Future<void> setAutoCheck({required bool enabled}) async {
    final prefs = _prefs..otaAutoCheck = enabled;
    await prefs.save();
    if (!ref.mounted) return;
    state = state.copyWith(autoCheck: enabled);
    if (enabled) await requestNotifications();
  }

  /// Hides the top banner for the currently available version only.
  Future<void> dismissUpdateBanner() async {
    final version = state.availableRelease?.version;
    if (version == null) return;
    final prefs = _prefs..otaDismissedVersion = version;
    await prefs.save();
    if (!ref.mounted) return;
    state = state.copyWith(dismissedVersion: () => version);
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
