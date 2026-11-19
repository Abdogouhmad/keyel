import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/app_info.dart';
import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/core/platform/autofill_platform.dart';
import 'package:keyel/core/platform/biometric_auth.dart';
import 'package:keyel/core/platform/debug_bundle.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/biometric_settings.dart';
import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_dialogs.dart';
import 'package:keyel/features/settings/widgets/settings_sections.dart';
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
  bool? _passkeyProviderSupported;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = AppPreferences.instance.biometricEnabled;
    unawaited(_checkAutofillStatus());
    unawaited(_checkPasskeySupport());
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

  Future<void> _checkPasskeySupport() async {
    final supported = await isPasskeyProviderSupported();
    if (mounted) setState(() => _passkeyProviderSupported = supported);
  }

  Future<void> _openCredentialProviderSettings() async {
    await openCredentialProviderSettings();
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
                    SettingsAppearanceSection(appearance: appearance),
                    const SizedBox(height: KeyelSpacing.lg),
                    SettingsSecuritySection(
                      session: session,
                      biometricBusy: _biometricBusy,
                      biometricEnabled: _biometricEnabled,
                      autoLockDelay: ref
                          .read(vaultSessionProvider.notifier)
                          .autoLockDelay,
                      clipboardSeconds:
                          AppPreferences.instance.clipboardClearSeconds,
                      onLockNow: () {
                        ref.read(vaultSessionProvider.notifier).lock();
                        showKeyelSnack(
                          context,
                          'Vault locked',
                          icon: Icons.lock_rounded,
                        );
                      },
                      onChangeMaster: () =>
                          unawaited(showChangeMasterDialog(context, ref)),
                      onAutoLock: () async {
                        await showAutoLockDialog(context, ref);
                        if (mounted) setState(() {});
                      },
                      onToggleBiometric: (value) =>
                          unawaited(_toggleBiometric(enable: value)),
                      onClipboard: () async {
                        await showClipboardDialog(context);
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    SettingsAutofillSection(
                      autofillEnabled: _autofillEnabled,
                      passkeyProviderSupported: _passkeyProviderSupported,
                      askToSave: AppPreferences.instance.autofillAskToSave,
                      matchMode: AppPreferences.instance.autofillMatchMode,
                      onOpenSettings: () => unawaited(_openAutofillSettings()),
                      onOpenCredentialProviderSettings: () =>
                          unawaited(_openCredentialProviderSettings()),
                      onAskToSaveChanged: (value) {
                        setState(() {
                          AppPreferences.instance.autofillAskToSave = value;
                        });
                        unawaited(AppPreferences.instance.save());
                      },
                      onToggleMatchMode: () {
                        final current =
                            AppPreferences.instance.autofillMatchMode;
                        setState(() {
                          AppPreferences.instance.autofillMatchMode =
                              current == 'exact' ? 'domain' : 'exact';
                        });
                        unawaited(AppPreferences.instance.save());
                      },
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    SettingsStorageSection(
                      offlineOnly: _offlineOnly,
                      otaState: otaState,
                      onOfflineOnlyChanged: (value) =>
                          setState(() => _offlineOnly = value),
                      onFactoryReset: () => unawaited(_factoryReset()),
                      onReportProblem: () => unawaited(_reportProblem()),
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
