import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
// import 'package:keyel/data/vault_repository.dart';
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
  bool _biometricUnlock = false;
  bool _clearClipboard = true;
  bool _offlineOnly = true;

  void _notImplemented(String feature) {
    showKeyelSnack(
      context,
      '$feature is planned for a future update.',
      icon: Icons.construction_rounded,
    );
  }

  Future<void> _showChangeMasterDialog() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

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

                if (!mounted) return;
                if (!dialogCtx.mounted) return;

                Navigator.of(dialogCtx).pop();
                showKeyelSnack(context, 'Master password changed successfully');
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

    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
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

    // This is a State method, so `mounted` guards `State.context` correctly.
    if (confirm != true) return;
    if (!mounted) return;

    // 1. Force delete the file via Dart
    ref.read(vaultRepositoryProvider).forceDeleteVault();

    // 2. Lock the session to ensure clean state
    ref.read(vaultSessionProvider.notifier).lock();

    showKeyelSnack(context, 'Vault permanently deleted. Resetting...');
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
                    child: _VaultProfileCard(
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
                            icon: Icons.fingerprint_rounded,
                            title: 'Biometric unlock',
                            subtitle: 'Fingerprint or face to open the vault',
                            trailing: Switch.adaptive(
                              value: _biometricUnlock,
                              onChanged: (value) =>
                                  setState(() => _biometricUnlock = value),
                            ),
                          ),
                          _SettingsRow(
                            icon: Icons.content_paste_off_rounded,
                            title: 'Clear clipboard',
                            subtitle: 'Wipe copied secrets after 30 seconds',
                            trailing: Switch.adaptive(
                              value: _clearClipboard,
                              onChanged: (value) =>
                                  setState(() => _clearClipboard = value),
                            ),
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
                              onChanged: (value) =>
                                  setState(() => _offlineOnly = value),
                            ),
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
                                applicationVersion: '0.4.0',
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
                  vaultPath != null ? vaultPath! : 'Storage not initialized',
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

    return PressableScale(onTap: onTap, semanticLabel: title, child: row);
  }
}
