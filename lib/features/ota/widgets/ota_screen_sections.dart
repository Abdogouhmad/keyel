import 'package:flutter/material.dart';

import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Banner summarizing current OTA status.
class OtaStatusBanner extends StatelessWidget {
  /// Creates an OTA status banner.
  const new({required this.state, super.key});

  /// Current OTA state.
  final OtaState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    final (
      IconData icon,
      Color iconColor,
      Color bgColor,
      String title,
      String subtitle,
    ) = switch (state.step) {
      OtaStep.checking => (
        Icons.sync_rounded,
        scheme.primary,
        scheme.primaryContainer.withValues(alpha: 0.5),
        l10n.otaCheckingUpdates,
        l10n.otaConnectingServer,
      ),
      OtaStep.upToDate => (
        Icons.verified_rounded,
        scheme.primary,
        scheme.primaryContainer.withValues(alpha: 0.5),
        l10n.otaUpToDate,
        state.channel == OtaChannel.beta
            ? l10n.otaNoBetaRelease(state.currentVersion)
            : l10n.otaLatestInstalled(state.currentVersion),
      ),
      OtaStep.available => (
        Icons.system_update_rounded,
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
        l10n.otaUpdateAvailableTitle,
        l10n.otaAvailableSubtitle(
          state.availableRelease!.version,
          state.channel.label,
        ),
      ),
      OtaStep.downloading => (
        Icons.downloading_rounded,
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
        l10n.otaDownloadingUpdate,
        l10n.otaDownloadingDetail(
          '${(state.downloadProgress * 100).toInt()}',
          state.availableRelease!.formattedSize,
        ),
      ),
      OtaStep.downloaded => (
        Icons.check_circle_rounded,
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
        l10n.otaReadyToInstall,
        l10n.otaDownloadedVerified(state.availableRelease!.version),
      ),
      OtaStep.installing => (
        Icons.install_mobile_rounded,
        scheme.primary,
        scheme.primaryContainer,
        l10n.otaInstallingUpdate,
        l10n.otaHandingToInstaller,
      ),
      OtaStep.error => (
        Icons.warning_amber_rounded,
        scheme.onErrorContainer,
        scheme.errorContainer,
        l10n.otaCheckFailedTitle,
        state.errorMessage ?? l10n.otaCouldNotConnect,
      ),
      OtaStep.idle => (
        Icons.info_outline_rounded,
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
        l10n.otaInstalledVersion(state.currentVersion),
        state.lastChecked != null
            ? l10n.otaLastChecked(_formatTime(state.lastChecked!))
            : l10n.otaTapCheckNow,
      ),
    };

    return KeyelSectionCard(
      color: bgColor,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(KeyelRadii.card),
            ),
            child: state.isChecking
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Download progress card shown while an update is downloading.
class OtaDownloadProgressCard extends StatelessWidget {
  /// Creates a download progress card.
  const new({required this.state, required this.onCancel, super.key});

  /// Current OTA state.
  final OtaState state;

  /// Cancels the active download.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return KeyelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.otaDownloadingApk,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.otaPercent(
                  (state.downloadProgress * 100).toStringAsFixed(0),
                ),
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(KeyelRadii.pill),
            child: LinearProgressIndicator(
              value: state.downloadProgress > 0 ? state.downloadProgress : null,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatOtaBytes(state.bytesReceived, zeroLabel: '0 B'),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              TextButton(onPressed: onCancel, child: Text(l10n.actionCancel)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Primary action button for the OTA flow.
class OtaPrimaryAction extends StatelessWidget {
  /// Creates the primary OTA action button.
  const new({
    required this.state,
    required this.onCheck,
    required this.onDownload,
    required this.onInstall,
    super.key,
  });

  /// Current OTA state.
  final OtaState state;

  /// Starts an update check.
  final VoidCallback onCheck;

  /// Starts downloading the available update.
  final VoidCallback onDownload;

  /// Installs the downloaded update.
  final Future<void> Function() onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    if (state.isDownloading) {
      return const SizedBox.shrink();
    }

    if (state.isReadyToInstall) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.install_mobile_rounded),
          label: Text(l10n.otaInstallNow),
          onPressed: () async {
            await onInstall();
          },
        ),
      );
    }

    if (state.step == OtaStep.available) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: Text(
            l10n.otaDownloadVersion(
              state.availableRelease!.version,
              state.availableRelease!.formattedSize,
            ),
          ),
          onPressed: onDownload,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          state.isChecking ? l10n.otaChecking : l10n.otaCheckForUpdates,
        ),
        onPressed: state.isChecking ? null : onCheck,
      ),
    );
  }
}

/// Release notes for an available OTA release.
class OtaReleaseNotesCard extends StatelessWidget {
  /// Creates a release notes card.
  const new({required this.release, super.key});

  /// Available release to describe.
  final OtaRelease release;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    return KeyelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.xs),
              Text(
                l10n.otaWhatsNew(release.version),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (release.isPrerelease)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                  ),
                  child: Text(
                    'BETA',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: KeyelSpacing.lg),
          SelectableText(
            release.releaseNotes.isNotEmpty
                ? release.releaseNotes
                : l10n.otaNoReleaseNotes,
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Update channel and auto-check preferences.
class OtaPreferencesCard extends StatelessWidget {
  /// Creates an OTA preferences card.
  const new({
    required this.state,
    required this.onChannelChanged,
    required this.onAutoCheckChanged,
    required this.onEnableNotifications,
    super.key,
  });

  /// Current OTA state.
  final OtaState state;

  /// Called when the release channel changes.
  final ValueChanged<OtaChannel> onChannelChanged;

  /// Called when auto-check preference changes.
  final ValueChanged<bool> onAutoCheckChanged;

  /// Requests the Android notification permission.
  final VoidCallback onEnableNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return KeyelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.otaPreferencesTitle,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.otaReleaseChannel, style: textTheme.bodyMedium),
                    Text(
                      state.channel.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<OtaChannel>(
                segments: const [
                  ButtonSegment(
                    value: OtaChannel.stable,
                    label: Text('Stable'),
                  ),
                  ButtonSegment(value: OtaChannel.beta, label: Text('Beta')),
                ],
                selected: {state.channel},
                onSelectionChanged: (set) => onChannelChanged(set.first),
              ),
            ],
          ),
          const Divider(height: KeyelSpacing.lg),
          // A ListTile paints its ink on the nearest Material. The section card
          // is a decorated box, so give the tile its own Material surface.
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.otaAutoCheckTitle),
              subtitle: Text(
                l10n.otaAutoCheckSubtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: state.autoCheck,
              onChanged: onAutoCheckChanged,
            ),
          ),
          if (state.autoCheck) ...[
            const SizedBox(height: KeyelSpacing.xs),
            if (state.notificationsEnabled)
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: KeyelSpacing.xs),
                  Text(
                    l10n.otaNotificationsOn,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: context.alignStart,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: Text(l10n.otaEnableNotifications),
                  onPressed: onEnableNotifications,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Button that installs an update from a locally selected APK file.
class OtaLocalInstallButton extends StatelessWidget {
  /// Creates a local APK install button.
  const new({required this.onInstallLocal, super.key});

  /// Installs from a selected local APK path.
  final Future<bool> Function(String path) onInstallLocal;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.folder_open_rounded),
        label: Text(l10n.otaInstallLocal),
        onPressed: () async {
          const service = PlatformFileTransferService();
          final picked = await service.pickFile(
            dialogTitle: l10n.otaSelectApkTitle,
          );
          if (picked == null || !context.mounted) return;
          // Local files never pass through the manifest checksum gate, so make
          // that explicit before handing one to the system installer.
          final confirmed = await KeyelConfirmDialog.show(
            context,
            title: l10n.otaInstallLocal,
            body: l10n.otaLocalInstallWarning,
            confirmLabel: l10n.otaInstallNow,
            destructive: true,
          );
          if (!confirmed || !context.mounted) return;
          final ok = await onInstallLocal(picked.path);
          if (!ok && context.mounted) {
            showKeyelSnack(
              context,
              l10n.otaGrantInstallPermission,
              icon: Icons.security_rounded,
            );
          }
        },
      ),
    );
  }
}

/// Privacy notice explaining what OTA checks access.
class OtaPrivacyNotice extends StatelessWidget {
  /// Creates an OTA privacy notice.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Text(
              l10n.otaPrivacyNotice,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
