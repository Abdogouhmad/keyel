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

/// Appearance section on the settings screen.
class SettingsAppearanceSection extends StatelessWidget {
  /// Creates the appearance section.
  const new({required this.appearance, super.key});

  /// Current appearance state.
  final AppearanceState appearance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KeyelSectionLabel(
          label: 'Appearance',
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.color_lens_outlined,
              title: 'Appearance & colors',
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
    required this.session,
    required this.biometricBusy,
    required this.biometricEnabled,
    required this.autoLockDelay,
    required this.clipboardSeconds,
    required this.onLockNow,
    required this.onChangeMaster,
    required this.onAutoLock,
    required this.onToggleBiometric,
    required this.onClipboard,
    super.key,
  });

  /// Current vault session.
  final VaultSessionState session;

  /// Whether a biometric toggle operation is in progress.
  final bool biometricBusy;

  /// Whether biometric unlock is enabled.
  final bool biometricEnabled;

  /// Current auto-lock delay.
  final Duration autoLockDelay;

  /// Current clipboard clear timeout in seconds.
  final int clipboardSeconds;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unlocked = session.status == VaultStatus.unlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KeyelSectionLabel(
          label: 'Security & Access',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            if (unlocked)
              SettingsRow(
                icon: Icons.lock_outline_rounded,
                title: 'Lock vault now',
                subtitle: 'Wipe decryption key from memory immediately',
                onTap: onLockNow,
              ),
            if (unlocked)
              SettingsRow(
                icon: Icons.password_rounded,
                title: 'Change master password',
                subtitle: 'Re-encrypt the vault keyslot with a new master',
                onTap: onChangeMaster,
              ),
            SettingsRow(
              icon: Icons.timer_outlined,
              title: 'Auto-lock',
              subtitle: 'Lock the vault after time in the background',
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
              title: 'Biometric unlock',
              subtitle: 'Fingerprint or face to open the vault',
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
              title: 'Clear clipboard',
              subtitle: 'Wipe copied secrets from the clipboard',
              trailing: Text(
                clipboardLabel(clipboardSeconds),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onClipboard,
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = autofillEnabled;
    final passkeysSupported = passkeyProviderSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KeyelSectionLabel(
          label: 'Autofill & Passkeys',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: enabled == true
                  ? Icons.check_circle_outline_rounded
                  : Icons.app_registration_rounded,
              title: 'Autofill service',
              subtitle: enabled == null
                  ? 'Checking…'
                  : enabled
                  ? 'Keyel is your autofill provider'
                  : 'Tap to enable Keyel as your autofill provider',
              trailing: enabled == true
                  ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                  : null,
              onTap: onOpenSettings,
            ),
            SettingsRow(
              icon: Icons.key_rounded,
              title: 'Passkey provider',
              subtitle: passkeysSupported == null
                  ? 'Checking device support…'
                  : passkeysSupported
                  ? 'Manage Keyel as a passkey provider in system settings'
                  : 'Not supported on this device or Android version',
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
              title: 'Ask to save',
              subtitle: 'Offer to save new credentials after a login',
              trailing: Switch.adaptive(
                value: askToSave,
                onChanged: onAskToSaveChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.language_rounded,
              title: 'Match mode',
              subtitle: matchMode == 'exact'
                  ? 'Exact host only'
                  : 'Domain (includes subdomains)',
              onTap: onToggleMatchMode,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KeyelSectionLabel(
          label: 'Storage & Diagnostics',
          icon: Icons.storage_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.cloud_off_rounded,
              title: 'Offline vault mode',
              subtitle: 'Zero telemetry, zero cloud synchronisation',
              trailing: Switch.adaptive(
                value: offlineOnly,
                onChanged: onOfflineOnlyChanged,
              ),
            ),
            SettingsRow(
              icon: Icons.folder_rounded,
              title: 'Folders',
              subtitle: 'Create, rename and delete vault folders',
              onTap: () => unawaited(context.push(KeyelRoutes.folders)),
            ),
            SettingsRow(
              icon: Icons.swap_vert_rounded,
              title: 'Backup & import',
              subtitle: 'Encrypted backups and CSV import or export',
              onTap: () => unawaited(context.push(KeyelRoutes.importExport)),
            ),
            SettingsRow(
              icon: Icons.delete_outline_rounded,
              title: 'Trash',
              subtitle: 'Restore deleted entries or remove them forever',
              onTap: () => unawaited(context.push(KeyelRoutes.trash)),
            ),
            SettingsRow(
              icon: Icons.delete_forever_rounded,
              title: 'Factory reset vault',
              subtitle: 'Permanently delete vault file and reset app state',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.red,
              ),
              onTap: onFactoryReset,
            ),
            SettingsRow(
              icon: Icons.bug_report_outlined,
              title: 'Report a problem',
              subtitle: 'Share a redacted diagnostics file (no secrets)',
              onTap: onReportProblem,
            ),
            SettingsRow(
              icon: Icons.construction_rounded,
              title: 'Bridge diagnostics & test suite',
              subtitle: 'Raw FRB bridge operations and diagnostics',
              onTap: () => unawaited(context.push(KeyelRoutes.debug)),
            ),
            SettingsRow(
              icon: Icons.system_update_rounded,
              title: 'Software update',
              subtitle: otaState.hasUpdate
                  ? 'Update available (v${otaState.availableRelease!.version})'
                  : 'Version ${AppInfo.version} • Up to date',
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
                        'NEW',
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
              title: 'Open source licenses',
              subtitle: 'Libraries bundled with this build',
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
