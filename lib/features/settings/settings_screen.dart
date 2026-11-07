import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Settings screen — security, appearance and vault preferences.
///
/// UI preview for roadmap 0.5.0: the controls are presentational. Toggles keep
/// local state so the interaction feels real, while persistence lands with the
/// vault layer.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const new({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricUnlock = true;
  bool _clearClipboard = true;
  bool _offlineOnly = true;

  void _notImplemented(String feature) {
    showKeyelSnack(
      context,
      '$feature arrives with the encrypted vault layer.',
      icon: Icons.construction_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
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
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
              sliver: SliverToBoxAdapter(child: _VaultProfileCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: KeyelSpacing.lg)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
              sliver: SliverList.list(
                children: [
                  const KeyelSectionLabel(
                    label: 'Security',
                    icon: Icons.shield_rounded,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  _SettingsCard(
                    children: [
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
                        icon: Icons.timer_outlined,
                        title: 'Auto-lock timeout',
                        subtitle: 'After 1 minute in the background',
                        onTap: () => _notImplemented('Auto-lock scheduling'),
                      ),
                      _SettingsRow(
                        icon: Icons.password_rounded,
                        title: 'Change master password',
                        subtitle: 'Rotate the key that protects your vault',
                        onTap: () =>
                            _notImplemented('Master password rotation'),
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
                    label: 'Appearance',
                    icon: Icons.palette_outlined,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'Theme',
                        subtitle: 'System default',
                        onTap: () => showKeyelSnack(
                          context,
                          'Theme switching arrives with settings storage.',
                          icon: Icons.dark_mode_outlined,
                        ),
                      ),
                      const _PaletteRow(),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.lg),
                  const KeyelSectionLabel(
                    label: 'Data',
                    icon: Icons.folder_rounded,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.upload_rounded,
                        title: 'Export vault',
                        subtitle: 'Create an encrypted backup file',
                        onTap: () => _notImplemented('Encrypted export'),
                      ),
                      _SettingsRow(
                        icon: Icons.download_rounded,
                        title: 'Import',
                        subtitle: 'Bring entries over from another manager',
                        onTap: () => _notImplemented('Vault import'),
                      ),
                      _SettingsRow(
                        icon: Icons.cloud_off_rounded,
                        title: 'Offline only',
                        subtitle: 'Never sync this vault to a cloud',
                        trailing: Switch.adaptive(
                          value: _offlineOnly,
                          onChanged: (value) =>
                              setState(() => _offlineOnly = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.lg),
                  const KeyelSectionLabel(
                    label: 'About',
                    icon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  _SettingsCard(
                    children: [
                      const _SettingsRow(
                        icon: Icons.verified_user_outlined,
                        title: 'Keyel',
                        subtitle: '0.1.0 · UI preview for 0.5.0',
                        trailing: KeyelBadge(
                          label: 'Local first',
                          icon: Icons.lock_rounded,
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.gavel_rounded,
                        title: 'Open source licenses',
                        subtitle: 'Libraries bundled with this build',
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'Keyel',
                          applicationVersion: '0.1.0',
                        ),
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
    );
  }
}

// ---------------------------------------------------------------------------

class _VaultProfileCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  'Personal vault',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '10 entries · device only',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          KeyelBadge(
            label: 'Locked',
            icon: Icons.lock_rounded,
            background: scheme.primaryFixed,
            foreground: scheme.onPrimaryFixed,
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
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(KeyelRadii.sm + 4),
            ),
            child: Icon(icon, size: 21, color: scheme.primary),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: KeyelSpacing.sm),
            trailing!,
          ] else
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final swatches = [
      scheme.primary,
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryFixed,
      scheme.surfaceContainerHighest,
    ];

    return Padding(
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
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(KeyelRadii.sm + 4),
            ),
            child: Icon(
              Icons.color_lens_outlined,
              size: 21,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brand palette',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Fixed Keyel colours · dynamic colour off',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm),
          Row(
            children: [
              for (final color in swatches)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surfaceContainerLow,
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
