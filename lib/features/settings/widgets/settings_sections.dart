import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/app_info.dart';
import 'package:keyel/core/ota/ota_models.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_dialogs.dart';
import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Appearance section on the settings screen.
class SettingsAppearanceSection extends StatelessWidget {
  /// Creates the appearance section.
  const new({required this.appearance, super.key});

  /// Current appearance state.
  final AppearanceState appearance;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyelSectionLabel(
          label: l10n.appearanceTitle,
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.color_lens_outlined,
              title: l10n.prefAppearanceColorsTitle,
              subtitle:
                  '${KeyelPaletteX.themeModeLabel(appearance.themeMode)} • ${appearance.palette.label}'
                  '${appearance.amoledBlack ? " • AMOLED" : ""}',
              onTap: () => unawaited(context.push(KeyelRoutes.appearance)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Security and access section on the settings screen.
class SettingsSecuritySection extends StatelessWidget {
  /// Creates the security section.
  const new({
    required this.status,
    required this.biometricBusy,
    required this.biometricEnabled,
    required this.autoLockDelay,
    required this.clipboardSeconds,
    required this.screenshotProtection,
    required this.onLockNow,
    required this.onChangeMaster,
    required this.onAutoLock,
    required this.onToggleBiometric,
    required this.onClipboard,
    required this.onScreenshotProtectionChanged,
    super.key,
  });

  /// Current vault lifecycle (the only session field this section renders).
  final VaultStatus status;

  /// Whether a biometric toggle operation is in progress.
  final bool biometricBusy;

  /// Whether biometric unlock is enabled.
  final bool biometricEnabled;

  /// Current auto-lock delay.
  final Duration autoLockDelay;

  /// Current clipboard clear timeout in seconds.
  final int clipboardSeconds;

  /// Whether screenshots are blocked while the vault is unlocked.
  final bool screenshotProtection;

  /// Locks the vault immediately.
  final VoidCallback onLockNow;

  /// Opens the change-master-password flow.
  final VoidCallback onChangeMaster;

  /// Opens the auto-lock picker.
  final VoidCallback onAutoLock;

  /// Toggles biometric unlock.
  final ValueChanged<bool> onToggleBiometric;

  /// Opens the clipboard clear picker.
  final VoidCallback onClipboard;

  /// Enables or disables screenshots while the vault is unlocked.
  final ValueChanged<bool> onScreenshotProtectionChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);
    final unlocked = status == VaultStatus.unlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyelSectionLabel(
          label: l10n.prefSecurityAccessSection,
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            if (unlocked)
              SettingsRow(
                icon: Icons.lock_outline_rounded,
                title: l10n.prefLockVaultNow,
                subtitle: l10n.prefLockVaultSubtitle,
                onTap: onLockNow,
              ),
            if (unlocked)
              SettingsRow(
                icon: Icons.password_rounded,
                title: l10n.prefChangeMasterPasswordRow,
                subtitle: l10n.prefChangeMasterSubtitle,
                onTap: onChangeMaster,
              ),
            SettingsRow(
              icon: Icons.timer_outlined,
              title: l10n.autoLockTitle,
              subtitle: l10n.prefAutoLockSubtitle,
              trailing: Text(
                autoLockLabel(autoLockDelay),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onAutoLock,
            ),
            SettingsRow(
              icon: Icons.fingerprint_rounded,
              title: l10n.prefBiometricUnlockTitle,
              subtitle: l10n.prefBiometricUnlockSubtitle,
              trailing: biometricBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch.adaptive(
                      value: biometricEnabled,
                      onChanged: onToggleBiometric,
                    ),
            ),
            SettingsRow(
              icon: Icons.content_paste_off_rounded,
              title: l10n.clipboardTitle,
              subtitle: l10n.prefClipboardSubtitle,
              trailing: Text(
                clipboardLabel(clipboardSeconds),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onClipboard,
            ),
            SettingsRow(
              icon: Icons.no_photography_rounded,
              title: l10n.screenshotTitle,
              subtitle: l10n.prefScreenshotSubtitle,
              trailing: Switch.adaptive(
                value: screenshotProtection,
                onChanged: onScreenshotProtectionChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Autofill and passkey provider preferences on the settings screen.
class SettingsAutofillSection extends StatelessWidget {
  /// Creates the autofill/passkey section.
  const new({
    required this.autofillEnabled,
    required this.passkeyProviderSupported,
    required this.askToSave,
    required this.matchMode,
    required this.onOpenSettings,
    required this.onOpenCredentialProviderSettings,
    required this.onAskToSaveChanged,
    required this.onToggleMatchMode,
    required this.neverForSitesCount,
    required this.onManageNeverSites,
    required this.verifiedOnly,
    required this.onVerifiedOnlyChanged,
    super.key,
  });

  /// Whether Keyel is the system autofill provider, or null if unknown.
  final bool? autofillEnabled;

  /// Whether the platform supports hosting a passkey/credential provider.
  final bool? passkeyProviderSupported;

  /// Whether to prompt to save new credentials.
  final bool askToSave;

  /// Current match mode (`exact` or `domain`).
  final String matchMode;

  /// Opens system autofill settings.
  final VoidCallback onOpenSettings;

  /// Opens system credential-provider settings (or best-effort fallback).
  final VoidCallback onOpenCredentialProviderSettings;

  /// Updates ask-to-save preference.
  final ValueChanged<bool> onAskToSaveChanged;

  /// Toggles between exact and domain match modes.
  final VoidCallback onToggleMatchMode;

  /// Number of permanent "never" choices.
  final int neverForSitesCount;

  /// Opens the blocked-sites manager.
  final VoidCallback onManageNeverSites;

  /// Whether only exact package/host matches are offered.
  final bool verifiedOnly;

  /// Updates the offline verified-only mode.
  final ValueChanged<bool> onVerifiedOnlyChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);
    final enabled = autofillEnabled;
    final passkeysSupported = passkeyProviderSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyelSectionLabel(
          label: l10n.prefAutofillPasskeysSection,
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: enabled == true
                  ? Icons.check_circle_outline_rounded
                  : Icons.app_registration_rounded,
              title: l10n.prefAutofillServiceTitle,
              subtitle: enabled == null
                  ? l10n.prefCheckingStatus
                  : enabled
                  ? l10n.prefAutofillEnabledSubtitle
                  : l10n.prefAutofillDisabledSubtitle,
              trailing: enabled == true
                  ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                  : null,
              onTap: onOpenSettings,
            ),
            SettingsRow(
              icon: Icons.key_rounded,
              title: l10n.prefPasskeyProviderTitle,
              subtitle: passkeysSupported == null
                  ? l10n.prefCheckingDeviceSupport
                  : passkeysSupported
                  ? l10n.prefPasskeySupportedSubtitle
                  : l10n.prefPasskeyUnsupportedSubtitle,
              trailing: passkeysSupported == false
                  ? Icon(
                      Icons.info_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    )
                  : null,
              onTap: passkeysSupported == true
                  ? onOpenCredentialProviderSettings
                  : null,
            ),
            SettingsRow(
              icon: Icons.save_rounded,
              title: l10n.prefAskToSaveTitle,
              subtitle: l10n.prefAskToSaveSubtitle,
              trailing: Switch.adaptive(
                value: askToSave,
                onChanged: onAskToSaveChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.language_rounded,
              title: l10n.prefMatchModeTitle,
              subtitle: matchMode == 'exact'
                  ? l10n.prefMatchModeExact
                  : l10n.prefMatchModeDomain,
              onTap: onToggleMatchMode,
            ),
            SettingsRow(
              icon: Icons.verified_user_outlined,
              title: l10n.autofillVerifiedTitle,
              subtitle: l10n.autofillVerifiedSubtitle,
              trailing: Switch.adaptive(
                value: verifiedOnly,
                onChanged: onVerifiedOnlyChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.block_rounded,
              title: l10n.autofillNeverTitle,
              subtitle: neverForSitesCount == 0
                  ? l10n.autofillNeverSubtitle
                  : l10n.autofillNeverCount(neverForSitesCount),
              trailing: Text(l10n.actionManage),
              onTap: onManageNeverSites,
            ),
          ],
        ),
      ],
    );
  }
}

/// Storage, diagnostics and about section on the settings screen.
class SettingsStorageSection extends StatelessWidget {
  /// Creates the storage/diagnostics section.
  const new({
    required this.offlineOnly,
    required this.otaState,
    required this.onOfflineOnlyChanged,
    required this.onFactoryReset,
    required this.onReportProblem,
    super.key,
  });

  /// Whether offline-only mode is enabled.
  final bool offlineOnly;

  /// Current OTA state.
  final OtaState otaState;

  /// Updates offline-only mode.
  final ValueChanged<bool> onOfflineOnlyChanged;

  /// Starts factory reset flow.
  final VoidCallback onFactoryReset;

  /// Shares a diagnostics report.
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyelSectionLabel(
          label: l10n.prefStorageDiagnosticsSection,
          icon: Icons.storage_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.cloud_off_rounded,
              title: l10n.prefOfflineVaultTitle,
              subtitle: l10n.prefOfflineVaultSubtitle,
              trailing: Switch.adaptive(
                value: offlineOnly,
                onChanged: onOfflineOnlyChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.cloud_sync_outlined,
              title: l10n.prefCrossDeviceSyncTitle,
              subtitle: l10n.prefCrossDeviceSyncSubtitle,
              onTap: () => unawaited(context.push(KeyelRoutes.sync)),
            ),
            SettingsRow(
              icon: Icons.folder_rounded,
              title: l10n.foldersTitle,
              subtitle: l10n.prefFoldersSubtitle,
              onTap: () => unawaited(context.push(KeyelRoutes.folders)),
            ),
            SettingsRow(
              icon: Icons.swap_vert_rounded,
              title: l10n.prefBackupImportTitle,
              subtitle: l10n.prefBackupImportSubtitle,
              onTap: () => unawaited(context.push(KeyelRoutes.importExport)),
            ),
            SettingsRow(
              icon: Icons.delete_outline_rounded,
              title: l10n.trashTitle,
              subtitle: l10n.prefTrashSubtitle,
              onTap: () => unawaited(context.push(KeyelRoutes.trash)),
            ),
            SettingsRow(
              icon: Icons.delete_forever_rounded,
              title: l10n.prefFactoryResetVaultTitle,
              subtitle: l10n.prefFactoryResetVaultSubtitle,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.red,
              ),
              onTap: onFactoryReset,
            ),
            SettingsRow(
              icon: Icons.bug_report_outlined,
              title: l10n.reportProblem,
              subtitle: l10n.prefReportProblemSubtitle,
              onTap: onReportProblem,
            ),
            SettingsRow(
              icon: Icons.construction_rounded,
              title: l10n.prefBridgeDiagnosticsTitle,
              subtitle: l10n.prefBridgeDiagnosticsSubtitle,
              onTap: () => unawaited(context.push(KeyelRoutes.debug)),
            ),
            SettingsRow(
              icon: Icons.system_update_rounded,
              title: l10n.prefSoftwareUpdateRowTitle,
              subtitle: otaState.hasUpdate
                  ? l10n.prefUpdateAvailable(otaState.availableRelease!.version)
                  : l10n.prefVersionUpToDate(AppInfo.version),
              trailing: otaState.hasUpdate
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(KeyelRadii.pill),
                      ),
                      child: Text(
                        l10n.prefNewBadge,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () => unawaited(context.push(KeyelRoutes.softwareUpdate)),
            ),
            SettingsRow(
              icon: Icons.gavel_rounded,
              title: l10n.prefOpenSourceLicensesTitle,
              subtitle: l10n.prefOpenSourceLicensesSubtitle,
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Keyel',
                  applicationVersion: AppInfo.version,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Opt-in Wear OS TOTP companion entry point.
class SettingsWatchSection extends StatelessWidget {
  /// Creates the watch section.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyelSectionLabel(label: l10n.wearTitle, icon: Icons.watch_rounded),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.password_outlined,
              title: l10n.wearTitle,
              subtitle: l10n.wearInfo,
              trailing: Text(l10n.actionOpen),
              onTap: () => context.go(KeyelRoutes.watchCodes),
            ),
          ],
        ),
      ],
    );
  }
}
