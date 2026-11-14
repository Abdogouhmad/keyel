import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/autofill_platform.dart';
import 'package:keyel/core/platform/biometric_auth.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/biometric_settings.dart';
import 'package:keyel/data/vault_session_provider.dart';
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
    // Initialize local state from preferences
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
    // Re-check after returning from the settings screen.
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
      if (mounted) {
        setState(() => _biometricBusy = false);
      }
    }
  }

  /// Confirm the master password, then let the OS prompt and Keystore storage
  /// take over. The password is verified against the vault before anything is
  /// stored.
  Future<bool> _enableBiometric() async {
    if (!await BiometricAuth.instance.isAvailable) {
      if (mounted) {
        showKeyelSnack(context, 'Biometrics are not available on this device.');
      }
      return false;
    }

    final master = await _confirmMaster();
    if (master == null || master.isEmpty) return false;

    final enabled = await enableBiometricUnlock(master);
    return enabled;
  }

  /// Ask for the master password and verify it against the vault.
  Future<String?> _confirmMaster() async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          var verifying = false;
          String? errorText;

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Confirm master password'),
              content: TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                enabled: !verifying,
                decoration: InputDecoration(
                  labelText: 'Master password',
                  errorText: errorText,
                ),
                onSubmitted: (value) {
                  if (!verifying && value.isNotEmpty) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: verifying
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          if (controller.text.isEmpty) {
                            setState(() => errorText = 'Password required');
                            return;
                          }

                          setState(() {
                            verifying = true;
                            errorText = null;
                          });

                          try {
                            final valid = await ref
                                .read(vaultRepositoryProvider)
                                .verifyMaster(controller.text);

                            if (!valid) {
                              setState(() {
                                verifying = false;
                                errorText = 'Incorrect password';
                              });
                              return;
                            }

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(controller.text);
                            }
                          } on Object {
                            setState(() {
                              verifying = false;
                              errorText = 'Verification failed';
                            });
                          }
                        },
                  child: verifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  String _autoLockLabel(Duration delay) {
    if (delay == Duration.zero) return 'Immediately';
    if (delay.inSeconds < 60) return 'After ${delay.inSeconds} seconds';
    final minutes = delay.inMinutes;
    return 'After $minutes ${minutes == 1 ? "minute" : "minutes"}';
  }

  Future<void> _showAutoLockDialog() async {
    final notifier = ref.read(vaultSessionProvider.notifier);
    final current = notifier.autoLockDelay;

    const options = [
      Duration.zero,
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
    ];

    final selected = await showDialog<Duration>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Auto-lock after'),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(option),
              child: Row(
                children: [
                  Icon(
                    option == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: KeyelSpacing.sm),
                  Text(_autoLockLabel(option)),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected == null) return;

    notifier.setAutoLockDelay(selected);

    if (mounted) setState(() {});
  }

  String _clipboardLabel(int seconds) {
    if (seconds <= 0) return 'Never';
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    return '$minutes ${minutes == 1 ? "minute" : "minutes"}';
  }

  Future<void> _showClipboardDialog() async {
    final prefs = AppPreferences.instance;
    final current = prefs.clipboardClearSeconds;
    const options = [15, 30, 60, 0];

    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Clear clipboard after'),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(option),
              child: Row(
                children: [
                  Icon(
                    option == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: KeyelSpacing.sm),
                  Text(_clipboardLabel(option)),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected == null) return;

    prefs.clipboardClearSeconds = selected;
    await prefs.save();

    if (mounted) setState(() {});
  }

  Future<void> _showChangeMasterDialog() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Change Master Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Master Password',
                ),
              ),
              const SizedBox(height: KeyelSpacing.sm),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Master Password',
                ),
              ),
              const SizedBox(height: KeyelSpacing.sm),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Master Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (newController.text != confirmController.text) {
                  showKeyelSnack(dialogCtx, 'New passwords do not match.');
                  return;
                }
                if (newController.text.isEmpty) {
                  showKeyelSnack(dialogCtx, 'New password cannot be empty.');
                  return;
                }

                try {
                  await ref
                      .read(vaultSessionProvider.notifier)
                      .changeMaster(
                        oldMaster: oldController.text,
                        newMaster: newController.text,
                      );

                  if (!mounted || !dialogCtx.mounted) return;
                  Navigator.of(dialogCtx).pop();
                  showKeyelSnack(
                    context,
                    'Master password changed successfully',
                  );
                } on Object catch (error) {
                  if (dialogCtx.mounted) {
                    showKeyelSnack(dialogCtx, describeVaultError(error));
                  }
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      );
    } finally {
      oldController.dispose();
      newController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _factoryReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Factory Reset?'),
          ],
        ),
        content: const Text(
          'This will permanently delete your vault file and all stored '
          'credentials. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final session = ref.watch(vaultSessionProvider);
    final repo = ref.watch(vaultRepositoryProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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

                // Header
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

                // Vault profile
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _VaultProfileCard(
                      session: session,
                      vaultPath: repo.vaultPath,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: KeyelSpacing.lg),
                ),

                // Settings sections
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.md,
                  ),
                  sliver: SliverList.list(
                    children: [
                      const KeyelSectionLabel(
                        label: 'Security & Access',
                        icon: Icons.shield_rounded,
                      ),
                      const SizedBox(height: KeyelSpacing.sm),

                      _SettingsCard(
                        children: [
                          if (session.status == VaultStatus.unlocked)
                            _SettingsRow(
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
                            _SettingsRow(
                              icon: Icons.password_rounded,
                              title: 'Change master password',
                              subtitle:
                                  'Re-encrypt the vault keyslot with a new '
                                  'master',
                              onTap: () => unawaited(_showChangeMasterDialog()),
                            ),

                          _SettingsRow(
                            icon: Icons.timer_outlined,
                            title: 'Auto-lock',
                            subtitle:
                                'Lock the vault after time in the background',
                            trailing: Text(
                              _autoLockLabel(
                                ref
                                    .read(vaultSessionProvider.notifier)
                                    .autoLockDelay,
                              ),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => unawaited(_showAutoLockDialog()),
                          ),

                          // Biometric authentication
                          _SettingsRow(
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

                          _SettingsRow(
                            icon: Icons.content_paste_off_rounded,
                            title: 'Clear clipboard',
                            subtitle: 'Wipe copied secrets from the clipboard',
                            trailing: Text(
                              _clipboardLabel(
                                AppPreferences.instance.clipboardClearSeconds,
                              ),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => unawaited(_showClipboardDialog()),
                          ),
                        ],
                      ),

                      const SizedBox(height: KeyelSpacing.lg),

                      const KeyelSectionLabel(
                        label: 'Autofill',
                        icon: Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(height: KeyelSpacing.sm),

                      _SettingsCard(
                        children: [
                          _SettingsRow(
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
                          _SettingsRow(
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
                          _SettingsRow(
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

                      _SettingsCard(
                        children: [
                          _SettingsRow(
                            icon: Icons.cloud_off_rounded,
                            title: 'Offline vault mode',
                            subtitle:
                                'Zero telemetry, zero cloud synchronisation',
                            trailing: Switch.adaptive(
                              value: _offlineOnly,
                              onChanged: (value) {
                                setState(() => _offlineOnly = value);
                              },
                            ),
                          ),

                          _SettingsRow(
                            icon: Icons.folder_rounded,
                            title: 'Folders',
                            subtitle: 'Create, rename and delete vault folders',
                            onTap: () =>
                                unawaited(context.push(KeyelRoutes.folders)),
                          ),

                          _SettingsRow(
                            icon: Icons.swap_vert_rounded,
                            title: 'Backup & import',
                            subtitle:
                                'Encrypted backups and CSV import or export',
                            onTap: () => unawaited(
                              context.push(KeyelRoutes.importExport),
                            ),
                          ),

                          _SettingsRow(
                            icon: Icons.delete_outline_rounded,
                            title: 'Trash',
                            subtitle: 'Restore deleted entries or remove them forever',
                            onTap: () =>
                                unawaited(context.push(KeyelRoutes.trash)),
                          ),

                          _SettingsRow(
                            icon: Icons.delete_forever_rounded,
                            title: 'Factory reset vault',
                            subtitle:
                                'Permanently delete vault file and reset app '
                                'state',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.red,
                            ),
                            onTap: () => unawaited(_factoryReset()),
                          ),

                          _SettingsRow(
                            icon: Icons.bug_report_outlined,
                            title: 'Bridge diagnostics & test suite',
                            subtitle:
                                'Raw FRB bridge operations and diagnostics',
                            onTap: () =>
                                unawaited(context.push(KeyelRoutes.debug)),
                          ),

                          _SettingsRow(
                            icon: Icons.gavel_rounded,
                            title: 'Open source licenses',
                            subtitle: 'Libraries bundled with this build',
                            onTap: () {
                              showLicensePage(
                                context: context,
                                applicationName: 'Keyel',
                                applicationVersion: '0.7.0',
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
      ),
    );
  }
}

/// Displays the current vault status and storage location.
class _VaultProfileCard extends StatelessWidget {
  const new({required this.session, this.vaultPath});

  final VaultSessionState session;
  final String? vaultPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (label, icon, color, foreground) = switch (session.status) {
      VaultStatus.unlocked => (
        'Unlocked',
        Icons.lock_open_rounded,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      VaultStatus.locked => (
        'Locked',
        Icons.lock_rounded,
        scheme.surfaceContainerHigh,
        scheme.primary,
      ),
      VaultStatus.noVault => (
        'No Vault',
        Icons.help_outline_rounded,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };

    return KeyelSectionCard(
      showBorder: true,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryFixed,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(
              Icons.key_rounded,
              size: 26,
              color: scheme.onPrimaryFixed,
            ),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Encrypted Vault',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vaultPath ?? 'Storage not initialized',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: KeyelTheme.monoFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm),
          KeyelBadge(
            label: label,
            icon: icon,
            background: color,
            foreground: foreground,
          ),
        ],
      ),
    );
  }
}

/// Groups related settings rows into a single card.
class _SettingsCard extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(
                  left: 72,
                  right: KeyelSpacing.md,
                ),
                child: KeyelRule(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Individual settings row with an optional trailing widget or action.
class _SettingsRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KeyelSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: KeyelSpacing.sm),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: KeyelSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(onTap: onTap, child: row);
  }
}
