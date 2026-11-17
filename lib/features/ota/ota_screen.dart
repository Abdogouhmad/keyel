import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/ui/keyel.dart';

/// Screen presenting the over-the-air update status, check triggers,
/// download progress, release notes, and installer actions.
class OtaScreen extends ConsumerStatefulWidget {
  /// Default constructor.
  const new({super.key});

  @override
  ConsumerState<OtaScreen> createState() => _OtaScreenState();
}

class _OtaScreenState extends ConsumerState<OtaScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otaProvider);
    final notifier = ref.read(otaProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KeyelSubShell(
      tabIndex: KeyelTab.settings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Software Update'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Check for updates',
              onPressed: state.isChecking || state.isDownloading
                  ? null
                  : notifier.checkForUpdates,
            ),
          ],
        ),
        body: KeyelContent(
          maxWidth: 600,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: KeyelSpacing.md,
              vertical: KeyelSpacing.lg,
            ),
            children: [
              _buildStatusBanner(context, state),
              const SizedBox(height: KeyelSpacing.lg),
              if (state.isDownloading) ...[
                _buildDownloadProgress(context, state, notifier),
                const SizedBox(height: KeyelSpacing.lg),
              ],
              _buildActionButtons(context, state, notifier),
              const SizedBox(height: KeyelSpacing.lg),
              if (state.availableRelease != null) ...[
                _buildReleaseNotes(context, state.availableRelease!),
                const SizedBox(height: KeyelSpacing.lg),
              ],
              _buildSettingsCard(context, state, notifier),
              const SizedBox(height: KeyelSpacing.md),
              _buildLocalApkOption(context, notifier),
              const SizedBox(height: KeyelSpacing.xl),
              _buildPrivacyNotice(context, scheme, textTheme),
              const SizedBox(height: KeyelSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, OtaState state) {
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
        'Version ${state.currentVersion} • Latest release installed',
      ),
      OtaStep.available => (
        Icons.system_update_rounded,
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
        'Update Available',
        'Keyel v${state.availableRelease!.version} is ready to download',
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

  Widget _buildDownloadProgress(
    BuildContext context,
    OtaState state,
    OtaNotifier notifier,
  ) {
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
              TextButton(
                onPressed: notifier.cancelDownload,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    OtaState state,
    OtaNotifier notifier,
  ) {
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
            final ok = await notifier.installUpdate();
            if (!ok && context.mounted) {
              showKeyelSnack(
                context,
                'Please grant permission to install unknown apps when prompted.',
                icon: Icons.security_rounded,
              );
            }
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
          onPressed: notifier.startDownload,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.refresh_rounded),
        label: Text(state.isChecking ? 'Checking...' : 'Check for Updates'),
        onPressed: state.isChecking ? null : notifier.checkForUpdates,
      ),
    );
  }

  Widget _buildReleaseNotes(BuildContext context, OtaRelease release) {
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

  Widget _buildSettingsCard(
    BuildContext context,
    OtaState state,
    OtaNotifier notifier,
  ) {
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
                onSelectionChanged: (set) {
                  notifier.setChannel(set.first);
                },
              ),
            ],
          ),
          const Divider(height: KeyelSpacing.lg),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Check for updates on launch'),
            subtitle: Text(
              'Notifies you when a new release is available',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            value: state.autoCheck,
            onChanged: (val) => notifier.setAutoCheck(enabled: val),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalApkOption(BuildContext context, OtaNotifier notifier) {
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
            final ok = await notifier.installLocalApk(picked.path);
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

  Widget _buildPrivacyNotice(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
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
              'Privacy guarantee: OTA update checks query public release tags only. Your vault database, passwords, keys, and biometrics never leave this device.',
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
}
