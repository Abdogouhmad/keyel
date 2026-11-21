import 'package:flutter/material.dart';

import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/ui/keyel.dart';

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
        'Checking for updates...',
        'Connecting to release server',
      ),
      OtaStep.upToDate => (
        Icons.verified_rounded,
        scheme.primary,
        scheme.primaryContainer.withValues(alpha: 0.5),
        'Keyel is up to date',
        state.channel == OtaChannel.beta
            ? 'No beta release yet • Version ${state.currentVersion} installed'
            : 'Version ${state.currentVersion} • Latest release installed',
      ),
      OtaStep.available => (
        Icons.system_update_rounded,
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
        'Update Available',
        'Keyel v${state.availableRelease!.version} • ${state.channel.label} channel',
      ),
      OtaStep.downloading => (
        Icons.downloading_rounded,
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
        'Downloading update...',
        '${(state.downloadProgress * 100).toInt()}% • ${state.availableRelease!.formattedSize}',
      ),
      OtaStep.downloaded => (
        Icons.check_circle_rounded,
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
        'Ready to Install',
        'Keyel v${state.availableRelease!.version} downloaded & verified',
      ),
      OtaStep.installing => (
        Icons.install_mobile_rounded,
        scheme.primary,
        scheme.primaryContainer,
        'Installing update...',
        'Handing off to system installer',
      ),
      OtaStep.error => (
        Icons.warning_amber_rounded,
        scheme.onErrorContainer,
        scheme.errorContainer,
        'Update check failed',
        state.errorMessage ?? 'Could not connect to release server',
      ),
      OtaStep.idle => (
        Icons.info_outline_rounded,
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
        'Installed Version: ${state.currentVersion}',
        state.lastChecked != null
            ? 'Last checked: ${_formatTime(state.lastChecked!)}'
            : 'Tap "Check now" to look for new releases',
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

    return KeyelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading APK',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
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
                _formatBytes(state.bytesReceived),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
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
    if (state.isDownloading) {
      return const SizedBox.shrink();
    }

    if (state.isReadyToInstall) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.install_mobile_rounded),
          label: const Text('Install Update Now'),
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
            'Download v${state.availableRelease!.version} (${state.availableRelease!.formattedSize})',
          ),
          onPressed: onDownload,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.refresh_rounded),
        label: Text(state.isChecking ? 'Checking...' : 'Check for Updates'),
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

    return KeyelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.xs),
              Text(
                'What’s New in v${release.version}',
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
                : 'No detailed release notes provided for this version.',
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

    return KeyelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Preferences',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Release Channel', style: textTheme.bodyMedium),
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
              title: const Text('Check for updates automatically'),
              subtitle: Text(
                'Checks on launch and when you return, on the selected channel.',
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
                    'Update notifications are on',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: const Text('Enable update notifications'),
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.folder_open_rounded),
        label: const Text('Install update from local APK file'),
        onPressed: () async {
          const service = PlatformFileTransferService();
          final picked = await service.pickFile(
            dialogTitle: 'Select Keyel Update APK',
          );
          if (picked != null) {
            final ok = await onInstallLocal(picked.path);
            if (!ok && context.mounted) {
              showKeyelSnack(
                context,
                'Please grant permission to install unknown apps when prompted.',
                icon: Icons.security_rounded,
              );
            }
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
              'Privacy guarantee: automatic checks read the public channel manifest only, on launch and while the app is open. Your vault database, passwords, keys, and biometrics never leave this device.',
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

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
