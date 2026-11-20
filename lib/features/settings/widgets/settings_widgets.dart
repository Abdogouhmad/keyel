import 'package:flutter/material.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';

/// Displays the current vault status and storage location.
class VaultProfileCard extends StatelessWidget {
  /// Creates a vault profile card.
  const new({required this.status, this.vaultPath, super.key});

  /// Current vault lifecycle (the only session field this card renders).
  final VaultStatus status;

  /// Resolved vault file path, if known.
  final String? vaultPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusName = status.toString();
    final unlocked = statusName.contains('unlocked');
    final locked = statusName.contains('locked');

    final (label, icon, color, foreground) = unlocked
        ? (
            'Unlocked',
            Icons.lock_open_rounded,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          )
        : locked
        ? (
            'Locked',
            Icons.lock_rounded,
            scheme.surfaceContainerHigh,
            scheme.primary,
          )
        : (
            'No Vault',
            Icons.help_outline_rounded,
            scheme.errorContainer,
            scheme.onErrorContainer,
          );

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
class SettingsCard extends StatelessWidget {
  /// Creates a settings card.
  const new({required this.children, super.key});

  /// Rows displayed in the card.
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
class SettingsRow extends StatelessWidget {
  /// Creates a settings row.
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Secondary description.
  final String subtitle;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Tap handler.
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
