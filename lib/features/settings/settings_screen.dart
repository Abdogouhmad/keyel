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
import 'package:keyel/core/security/screenshot_protection_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/autofill_settings_provider.dart';
import 'package:keyel/data/biometric_settings.dart';
import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/security_settings_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_dialogs.dart';
import 'package:keyel/features/settings/widgets/settings_help_sheet.dart';
import 'package:keyel/features/settings/widgets/settings_sections.dart';
import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
  bool? _autofillEnabled;
  bool? _passkeyProviderSupported;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = AppPreferences.instance.biometricEnabled;
    unawaited(_checkAutofillStatus());
    unawaited(_checkPasskeySupport());
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

  Future<void> _manageNeverSites() async {
    final notifier = ref.read(autofillSettingsProvider.notifier);
    final sites = List<String>.from(
      ref.read(autofillSettingsProvider).neverForSites,
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = l10nOf(dialogContext);
        return SimpleDialog(
          title: Text(dialogL10n.autofillNeverTitle),
          children: [
            if (sites.isEmpty)
              Padding(
                padding: const EdgeInsets.all(KeyelSpacing.lg),
                child: Text(dialogL10n.autofillNeverEmpty),
              )
            else
              for (final site in sites)
                SimpleDialogOption(
                  onPressed: () {
                    notifier.removeNeverSite(site);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded, size: 20),
                      const SizedBox(width: KeyelSpacing.sm),
                      Expanded(child: Text(site)),
                      Text(dialogL10n.actionRemove),
                    ],
                  ),
                ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogL10n.actionClose),
            ),
          ],
        );
      },
    );
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
    final l10n = l10nOf(context);
    setState(() => _biometricBusy = true);

    try {
      if (enable) {
        final enabled = await _enableBiometric();
        if (mounted && enabled) {
          setState(() => _biometricEnabled = true);
          showKeyelSnack(
            context,
            l10n.prefBiometricEnabledSnack,
            icon: Icons.fingerprint_rounded,
          );
        }
      } else {
        await disableBiometricUnlock();
        if (mounted) {
          setState(() => _biometricEnabled = false);
          showKeyelSnack(
            context,
            l10n.prefBiometricDisabledSnack,
            icon: Icons.fingerprint_rounded,
          );
        }
      }
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(context, l10n.prefBiometricUpdateError(error.toString()));
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<bool> _enableBiometric() async {
    final l10n = l10nOf(context);
    final available = await BiometricAuth.instance.isAvailable;
    if (!mounted) return false;
    if (!available) {
      showKeyelSnack(context, l10n.prefBiometricsUnavailable);
      return false;
    }
    final master = await confirmMasterPassword(context, ref);
    if (!mounted || master == null || master.isEmpty) return false;
    return await enableBiometricUnlock(master);
  }

  Future<void> _factoryReset() async {
    final l10n = l10nOf(context);
    final confirm = await confirmFactoryReset(context);
    if (!confirm || !mounted) return;

    try {
      await disableBiometricUnlock();
      await ref.read(vaultRepositoryProvider).forceDeleteVault();
      ref.read(vaultSessionProvider.notifier).lock();

      if (!mounted) return;
      showKeyelSnack(context, l10n.prefFactoryResetSnack);
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(context, l10n.prefFactoryResetError(error.toString()));
    }
  }

  Future<void> _reportProblem() async {
    final l10n = l10nOf(context);
    final files = ref.read(fileTransferServiceProvider);
    try {
      final path = await files.temporaryFilePath('keyel-diagnostics.txt');
      await files.writeTextFile(path, collectDebugBundle());
      await files.shareFile(
        path,
        subject: l10n.prefDiagnosticsSubject(AppInfo.version),
      );
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(context, l10n.prefReportProblemError(error.toString()));
    }
  }

  Future<void> _setScreenshotProtection(bool enabled) async {
    final l10n = l10nOf(context);
    if (!enabled) {
      final confirmed = await KeyelConfirmDialog.show(
        context,
        title: l10n.prefAllowScreenshotsTitle,
        body: l10n.prefAllowScreenshotsBody,
        confirmLabel: l10n.prefAllowScreenshotsConfirm,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    ref
        .read(screenshotProtectionProvider.notifier)
        .setEnabled(enabled: enabled);
    if (!mounted) return;
    showKeyelSnack(
      context,
      enabled ? l10n.prefScreenshotOnSnack : l10n.prefScreenshotOffSnack,
      icon: Icons.no_photography_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    // Both settings cards below only render the lifecycle, so ignore session
    // `busy`/`error` churn that would otherwise rebuild the whole list.
    final sessionStatus = ref.watch(
      vaultSessionProvider.select((state) => state.status),
    );
    final repo = ref.watch(vaultRepositoryProvider);
    // Watch only the fields this screen renders: OTA progress ticks must not
    // rebuild the whole settings tree while a download is running.
    final hasUpdate = ref.watch(otaProvider.select((state) => state.hasUpdate));
    final updateVersion = ref.watch(
      otaProvider.select((state) => state.availableRelease?.version),
    );
    final appearance = ref.watch(appearanceProvider);
    final screenshotProtection = ref.watch(screenshotProtectionProvider);
    final securitySettings = ref.watch(securitySettingsProvider);
    final autofill = ref.watch(autofillSettingsProvider);
    // The security dashboard links here with ?from=security. Show a real back
    // arrow for that entry so the user can return to where they came from.
    final returnToSecurity =
        GoRouter.maybeOf(context)?.state.uri.queryParameters['from'] ==
        'security';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: l10n.settingsTitle,
              icon: returnToSecurity ? context.backArrow : Icons.tune_rounded,
              iconTooltip: returnToSecurity ? l10n.prefBackToSecurity : null,
              onIconTap: returnToSecurity
                  ? () => context.go(KeyelRoutes.security)
                  : null,
              trailing: KeyelIconHull(
                icon: Icons.help_outline_rounded,
                tooltip: l10n.prefHelpSupportTooltip,
                onPressed: () => showSettingsHelpSheet(context),
              ),
            ),
            Expanded(
              child: KeyelContent(
                maxWidth: context.supportsTwoColumns
                    ? KeyelContentWidth.page
                    : KeyelContentWidth.reading,
                child: KeyelResponsiveColumns(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    context.pageMargin,
                    0,
                    context.pageMargin,
                    KeyelSpacing.lg,
                  ),
                  leading: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        KeyelSpacing.lg,
                        KeyelSpacing.xs,
                        KeyelSpacing.lg,
                        KeyelSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.prefYourVault,
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
                            l10n.prefSecuritySubtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KeyelSpacing.md,
                      ),
                      child: VaultProfileCard(
                        status: sessionStatus,
                        vaultPath: repo.vaultPath,
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    SettingsAppearanceSection(appearance: appearance),
                    const SizedBox(height: KeyelSpacing.lg),
                    SettingsSecuritySection(
                      status: sessionStatus,
                      biometricBusy: _biometricBusy,
                      biometricEnabled: _biometricEnabled,
                      autoLockDelay: securitySettings.autoLockDelay,
                      clipboardSeconds: securitySettings.clipboardClearSeconds,
                      screenshotProtection: screenshotProtection,
                      onLockNow: () {
                        ref.read(vaultSessionProvider.notifier).lock();
                        showKeyelSnack(
                          context,
                          l10n.prefVaultLockedSnack,
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
                        await showClipboardDialog(context, ref);
                        if (mounted) setState(() {});
                      },
                      onScreenshotProtectionChanged: (value) =>
                          unawaited(_setScreenshotProtection(value)),
                    ),
                  ],
                  trailing: [
                    SettingsAutofillSection(
                      autofillEnabled: _autofillEnabled,
                      passkeyProviderSupported: _passkeyProviderSupported,
                      askToSave: autofill.askToSave,
                      matchMode: autofill.matchMode,
                      onOpenSettings: () => unawaited(_openAutofillSettings()),
                      onOpenCredentialProviderSettings: () =>
                          unawaited(_openCredentialProviderSettings()),
                      verifiedOnly: autofill.verifiedOnly,
                      onVerifiedOnlyChanged: (value) => ref
                          .read(autofillSettingsProvider.notifier)
                          .setVerifiedOnly(value: value),
                      neverForSitesCount: autofill.neverForSites.length,
                      onManageNeverSites: _manageNeverSites,
                      onAskToSaveChanged: (value) => ref
                          .read(autofillSettingsProvider.notifier)
                          .setAskToSave(value: value),
                      onToggleMatchMode: () => ref
                          .read(autofillSettingsProvider.notifier)
                          .toggleMatchMode(),
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    const SettingsWatchSection(),
                    const SizedBox(height: KeyelSpacing.lg),
                    SettingsStorageSection(
                      hasUpdate: hasUpdate,
                      updateVersion: updateVersion,
                      onFactoryReset: () => unawaited(_factoryReset()),
                      onReportProblem: () => unawaited(_reportProblem()),
                    ),
                    const SizedBox(height: KeyelSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
