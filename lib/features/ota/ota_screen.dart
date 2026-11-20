import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/features/ota/widgets/ota_screen_sections.dart';
import 'package:keyel/ui/keyel.dart';

/// Screen presenting the over-the-air update status, check triggers,
/// download progress, release notes, and installer actions.
class OtaScreen extends ConsumerWidget {
  /// Default constructor.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otaProvider);
    final notifier = ref.read(otaProvider.notifier);

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
              OtaStatusBanner(state: state),
              const SizedBox(height: KeyelSpacing.lg),
              if (state.isDownloading) ...[
                OtaDownloadProgressCard(
                  state: state,
                  onCancel: notifier.cancelDownload,
                ),
                const SizedBox(height: KeyelSpacing.lg),
              ],
              OtaPrimaryAction(
                state: state,
                onCheck: notifier.checkForUpdates,
                onDownload: notifier.startDownload,
                onInstall: () async {
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
              const SizedBox(height: KeyelSpacing.lg),
              if (state.availableRelease != null) ...[
                OtaReleaseNotesCard(release: state.availableRelease!),
                const SizedBox(height: KeyelSpacing.lg),
              ],
              OtaPreferencesCard(
                state: state,
                onChannelChanged: notifier.setChannel,
                onAutoCheckChanged: (value) =>
                    notifier.setAutoCheck(enabled: value),
              ),
              const SizedBox(height: KeyelSpacing.md),
              OtaLocalInstallButton(onInstallLocal: notifier.installLocalApk),
              const SizedBox(height: KeyelSpacing.xl),
              const OtaPrivacyNotice(),
              const SizedBox(height: KeyelSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
