import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/app_info.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/core/platform/autofill_platform.dart';
import 'package:keyel/core/platform/biometric_auth.dart';
import 'package:keyel/core/platform/debug_bundle.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/biometric_settings.dart';
import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_dialogs.dart';
import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/ui/keyel.dart';

/// Settings screen — security, appearance and vault preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const new({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricBusy = false;
  bool _biometricEnabled = false;
  bool _offlineOnly = true;
  bool? _autofillEnabled;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = AppPreferences.instance.biometricEnabled;
    unawaited(_checkAutofillStatus());
  }

  void _notImplemented(String feature) {
    showKeyelSnack(
      context,
      '$feature is planned for a future update.',
      icon: Icons.construction_rounded,
    );
  }

  Future<void> _checkAutofillStatus() async {
    final enabled = await isAutofillServiceEnabled();
    if (mounted) setState(() => _autofillEnabled = enabled);
  }

  Future<void> _openAutofillSettings() async {
    await openAutofillSettings();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _checkAutofillStatus();
  }

  Future<void> _toggleBiometric({required bool enable}) async {
    if (_biometricBusy) return;
    setState(() => _biometricBusy = true);

    try {
      if (enable) {
        final enabled = await _enableBiometric();
        if (mounted && enabled) {
          setState(() => _biometricEnabled = true);
          showKeyelSnack(
            context,
            'Biometric unlock enabled',
            icon: Icons.fingerprint_rounded,
          );
        }
      } else {
        await disableBiometricUnlock();
        if (mounted) {
          setState(() => _biometricEnabled = false);
          showKeyelSnack(
            context,
            'Biometric unlock disabled.',
            icon: Icons.fingerprint_rounded,
          );
        }
      }
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(context, 'Could not update biometric settings: $error');
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<bool> _enableBiometric() async {
    final available = await BiometricAuth.instance.isAvailable;
    if (!mounted) return false;
    if (!available) {
      showKeyelSnack(context, 'Biometrics are not available on this device.');
      return false;
    }
    final master = await confirmMasterPassword(context, ref);
    if (!mounted || master == null || master.isEmpty) return false;
    return await enableBiometricUnlock(master);
  }

  Future<void> _factoryReset() async {
    final confirm = await confirmFactoryReset(context);
    if (!confirm || !mounted) return;

    try {
      await disableBiometricUnlock();
      await Future.sync(
        () => ref.read(vaultRepositoryProvider).forceDeleteVault(),
      );
      ref.read(vaultSessionProvider.notifier).lock();

      if (!mounted) return;
      showKeyelSnack(context, 'Vault permanently deleted. Resetting...');
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(context, 'Factory reset failed: $error');
    }
  }

  Future<void> _reportProblem() async {
    final files = ref.read(fileTransferServiceProvider);
    try {
      final path = await files.temporaryFilePath('keyel-diagnostics.txt');
      await files.writeTextFile(path, collectDebugBundle());
      await files.shareFile(
        path,
        subject: 'Keyel diagnostics (${AppInfo.version})',
      );
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(context, 'Could not prepare the report: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(vaultSessionProvider);
    final repo = ref.watch(vaultRepositoryProvider);
    final otaState = ref.watch(otaProvider);
    final appearance = ref.watch(appearanceProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: KeyelContent(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: KeyelTopBar(
                  title: 'Settings',
                  icon: Icons.tune_rounded,
                  trailing: KeyelIconHull(
                    icon: Icons.help_outline_rounded,
                    tooltip: 'Help & support',
                    onPressed: () => _notImplemented('Guided help'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.xs,
                  KeyelSpacing.lg,
                  KeyelSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your vault',
                        style: textTheme.headlineLarge?.copyWith(
                          color: scheme.onSurface,
                          fontSize: 28,
                          height: 36 / 28,
                          letterSpacing: -0.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Security tuned for this device, kept local.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: VaultProfileCard(
                    session: session,
                    vaultPath: repo.vaultPath,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: KeyelSpacing.lg),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.md,
                ),
                sliver: SliverList.list(
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
                          onTap: () =>
                              unawaited(context.push(KeyelRoutes.appearance)),
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    const KeyelSectionLabel(
                      label: 'Security & Access',
                      icon: Icons.shield_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        if (session.status == VaultStatus.unlocked)
                          SettingsRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Lock vault now',
                            subtitle:
                                'Wipe decryption key from memory immediately',
                            onTap: () {
                              ref.read(vaultSessionProvider.notifier).lock();
                              showKeyelSnack(
                                context,
                                'Vault locked',
                                icon: Icons.lock_rounded,
                              );
                            },
                          ),
                        if (session.status == VaultStatus.unlocked)
                          SettingsRow(
                            icon: Icons.password_rounded,
                            title: 'Change master password',
                            subtitle: 'Re-encrypt the vault keyslot with a new master',
                            onTap: () =>
                                unawaited(showChangeMasterDialog(context, ref)),
                          ),
                        SettingsRow(
                          icon: Icons.timer_outlined,
                          title: 'Auto-lock',
                          subtitle:
                              'Lock the vault after time in the background',
                          trailing: Text(
                            autoLockLabel(
                              ref
                                  .read(vaultSessionProvider.notifier)
                                  .autoLockDelay,
                            ),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () async {
                            await showAutoLockDialog(context, ref);
                            if (mounted) setState(() {});
                          },
                        ),
                        SettingsRow(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric unlock',
                          subtitle: 'Fingerprint or face to open the vault',
                          trailing: _biometricBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Switch.adaptive(
                                  value: _biometricEnabled,
                                  onChanged: (value) => unawaited(
                                    _toggleBiometric(enable: value),
                                  ),
                                ),
                        ),
                        SettingsRow(
                          icon: Icons.content_paste_off_rounded,
                          title: 'Clear clipboard',
                          subtitle: 'Wipe copied secrets from the clipboard',
                          trailing: Text(
                            clipboardLabel(
                              AppPreferences.instance.clipboardClearSeconds,
                            ),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () async {
                            await showClipboardDialog(context);
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    const KeyelSectionLabel(
                      label: 'Autofill',
                      icon: Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: _autofillEnabled == true
                              ? Icons.check_circle_outline_rounded
                              : Icons.app_registration_rounded,
                          title: 'Autofill service',
                          subtitle: _autofillEnabled == null
                              ? 'Checking…'
                              : _autofillEnabled!
                              ? 'Keyel is your autofill provider'
                              : 'Tap to enable Keyel as your autofill provider',
                          trailing: _autofillEnabled == true
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: scheme.primary,
                                )
                              : null,
                          onTap: () => unawaited(_openAutofillSettings()),
                        ),
                        SettingsRow(
                          icon: Icons.save_rounded,
                          title: 'Ask to save',
                          subtitle:
                              'Offer to save new credentials after a login',
                          trailing: Switch.adaptive(
                            value: AppPreferences.instance.autofillAskToSave,
                            onChanged: (value) {
                              setState(() {
                                AppPreferences.instance.autofillAskToSave =
                                    value;
                              });
                              unawaited(AppPreferences.instance.save());
                            },
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.language_rounded,
                          title: 'Match mode',
                          subtitle:
                              AppPreferences.instance.autofillMatchMode ==
                                  'exact'
                              ? 'Exact host only'
                              : 'Domain (includes subdomains)',
                          onTap: () {
                            final current =
                                AppPreferences.instance.autofillMatchMode;
                            setState(() {
                              AppPreferences.instance.autofillMatchMode =
                                  current == 'exact' ? 'domain' : 'exact';
                            });
                            unawaited(AppPreferences.instance.save());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
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
                          subtitle:
                              'Zero telemetry, zero cloud synchronisation',
                          trailing: Switch.adaptive(
                            value: _offlineOnly,
                            onChanged: (value) =>
                                setState(() => _offlineOnly = value),
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.folder_rounded,
                          title: 'Folders',
                          subtitle: 'Create, rename and delete vault folders',
                          onTap: () =>
                              unawaited(context.push(KeyelRoutes.folders)),
                        ),
                        SettingsRow(
                          icon: Icons.swap_vert_rounded,
                          title: 'Backup & import',
                          subtitle:
                              'Encrypted backups and CSV import or export',
                          onTap: () =>
                              unawaited(context.push(KeyelRoutes.importExport)),
                        ),
                        SettingsRow(
                          icon: Icons.delete_outline_rounded,
                          title: 'Trash',
                          subtitle:
                              'Restore deleted entries or remove them forever',
                          onTap: () =>
                              unawaited(context.push(KeyelRoutes.trash)),
                        ),
                        SettingsRow(
                          icon: Icons.delete_forever_rounded,
                          title: 'Factory reset vault',
                          subtitle: 'Permanently delete vault file and reset app state',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.red,
                          ),
                          onTap: () => unawaited(_factoryReset()),
                        ),
                        SettingsRow(
                          icon: Icons.bug_report_outlined,
                          title: 'Report a problem',
                          subtitle:
                              'Share a redacted diagnostics file (no secrets)',
                          onTap: () => unawaited(_reportProblem()),
                        ),
                        SettingsRow(
                          icon: Icons.construction_rounded,
                          title: 'Bridge diagnostics & test suite',
                          subtitle: 'Raw FRB bridge operations and diagnostics',
                          onTap: () =>
                              unawaited(context.push(KeyelRoutes.debug)),
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
                                    borderRadius: BorderRadius.circular(
                                      KeyelRadii.pill,
                                    ),
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
                          onTap: () => unawaited(
                            context.push(KeyelRoutes.softwareUpdate),
                          ),
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
                    const SizedBox(height: KeyelSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
