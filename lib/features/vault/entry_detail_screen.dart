import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/vault/vault_entry.dart';
import 'package:keyel/ui/keyel.dart';

/// Detail screen for a single login, card or secure note.
class EntryDetailScreen extends StatefulWidget {
  /// Creates an entry detail screen.
  const new({required this.entryId, super.key});

  /// Identifier of the demo entry to show.
  final String entryId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  VaultEntry? _entry;
  bool _revealed = false;
  bool _favorite = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _entry = vaultEntryById(widget.entryId);
    _favorite = _entry?.favorite ?? false;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _toggleReveal() {
    _hideTimer?.cancel();
    setState(() => _revealed = !_revealed);
    if (_revealed) {
      _hideTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) setState(() => _revealed = false);
      });
    }
  }

  void _copy(String value, String message) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
  }

  void _toggleFavorite(VaultEntry entry) {
    setState(() => _favorite = !_favorite);
    showKeyelSnack(
      context,
      _favorite ? '${entry.title} pinned to favourites' : 'Favourite removed',
      icon: _favorite ? Icons.star_rounded : Icons.star_outline_rounded,
    );
  }

  Future<void> _confirmDelete(VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${entry.title}?'),
        content: const Text(
          'This demo entry is not connected to encrypted storage yet, so '
          'nothing will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      showKeyelSnack(
        context,
        'Deleting entries arrives with encrypted storage.',
        icon: Icons.delete_outline_rounded,
      );
    }
  }

  void _handleMenu(String action, VaultEntry entry) {
    switch (action) {
      case 'edit':
        unawaited(context.push(KeyelRoutes.entryEdit(entry.id)));
        return;
      case 'move':
        showKeyelSnack(
          context,
          'Moving entries between folders is coming soon.',
          icon: Icons.drive_file_move_rounded,
        );
        return;
      case 'duplicate':
        showKeyelSnack(
          context,
          'Duplicating entries is coming with the storage layer.',
          icon: Icons.content_copy_rounded,
        );
        return;
      case 'delete':
        unawaited(_confirmDelete(entry));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    if (entry == null) return _MissingEntry(entryId: widget.entryId);

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailBar(
              favorite: _favorite,
              onBack: () => context.pop(),
              onFavorite: () => _toggleFavorite(entry),
              onMenu: (action) => _handleMenu(action, entry),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.md,
                  0,
                  KeyelSpacing.md,
                  KeyelSpacing.lg,
                ),
                children: [
                  _Hero(entry: entry),
                  if (entry.kind == VaultEntryKind.card)
                    _CardDetails(entry: entry, onCopy: _copy)
                  else
                    _Credentials(
                      entry: entry,
                      revealed: _revealed,
                      onToggleReveal: _toggleReveal,
                      onCopy: _copy,
                      onOpenWebsite: () => showKeyelSnack(
                        context,
                        'Opening links arrives in a later update.',
                        icon: Icons.open_in_new_rounded,
                      ),
                    ),
                  if (entry.hasTotp && entry.totpCode != null) ...[
                    const SizedBox(height: KeyelSpacing.md),
                    KeyelSectionCard(
                      title: 'One-time code (2FA)',
                      icon: Icons.phonelink_lock_rounded,
                      showBorder: true,
                      trailing: Text(
                        'RFC 6238 TOTP',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.outline),
                      ),
                      child: KeyelTotpDisplay(
                        code: entry.totpCode!,
                        onCopy: () => _copy(
                          entry.totpCode!,
                          '2FA code copied to clipboard',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: KeyelSpacing.md),
                  _HealthCard(entry: entry),
                  if (entry.notes != null) ...[
                    const SizedBox(height: KeyelSpacing.md),
                    KeyelSectionCard(
                      title: 'Secure notes',
                      icon: Icons.description_rounded,
                      showBorder: true,
                      child: Container(
                        padding: const EdgeInsets.all(KeyelSpacing.md - 2),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(KeyelRadii.field),
                        ),
                        child: Text(
                          entry.notes!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurface, height: 1.5),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: KeyelSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: scheme.surface,
          padding: const EdgeInsets.fromLTRB(
            KeyelSpacing.md,
            KeyelSpacing.sm,
            KeyelSpacing.md,
            KeyelSpacing.md,
          ),
          child: KeyelPillButton(
            label: entry.kind == VaultEntryKind.card
                ? 'Edit card'
                : 'Edit login',
            icon: Icons.edit_rounded,
            tone: KeyelButtonTone.tonal,
            onPressed: () => context.push(KeyelRoutes.entryEdit(entry.id)),
          ),
        ),
      ),
    );
  }
}

class _DetailBar extends StatelessWidget {
  const new({
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
    required this.onMenu,
  });

  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.sm),
        child: Row(
          children: [
            KeyelIconHull(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: onBack,
              foreground: scheme.onSurface,
            ),
            const Spacer(),
            KeyelIconHull(
              icon: favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              tooltip: favorite ? 'Remove favourite' : 'Add favourite',
              onPressed: onFavorite,
              foreground: favorite ? scheme.tertiary : scheme.onSurfaceVariant,
            ),
            PopupMenuButton<String>(
              tooltip: 'More options',
              icon: Icon(Icons.more_vert_rounded, color: scheme.onSurface),
              onSelected: onMenu,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: _MenuItem(icon: Icons.edit_rounded, label: 'Edit'),
                ),
                const PopupMenuItem(
                  value: 'move',
                  child: _MenuItem(
                    icon: Icons.drive_file_move_rounded,
                    label: 'Move',
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: _MenuItem(
                    icon: Icons.content_copy_rounded,
                    label: 'Duplicate',
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: _MenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: scheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const new({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? scheme.onSurfaceVariant),
        const SizedBox(width: KeyelSpacing.sm + 4),
        Text(label, style: TextStyle(color: foreground)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const new({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: KeyelSpacing.sm,
        bottom: KeyelSpacing.md + 4,
      ),
      child: Column(
        children: [
          KeyelAvatar(
            icon: entry.icon,
            tone: entry.avatarTone,
            shape: entry.avatarShape,
            size: 72,
          ),
          const SizedBox(height: KeyelSpacing.md),
          Text(
            entry.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(
              color: scheme.onSurface,
              fontSize: 28,
              height: 36 / 28,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: KeyelSpacing.sm,
            runSpacing: KeyelSpacing.sm,
            children: [
              KeyelBadge(
                label: entry.folder,
                icon: Icons.work_rounded,
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
              ),
              if (entry.hasTotp)
                KeyelBadge(
                  label: '2FA enabled',
                  icon: Icons.verified_user_rounded,
                  background: scheme.surfaceContainerHigh,
                  foreground: scheme.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Credentials extends StatelessWidget {
  const new({
    required this.entry,
    required this.revealed,
    required this.onToggleReveal,
    required this.onCopy,
    required this.onOpenWebsite,
  });

  final VaultEntry entry;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final void Function(String value, String message) onCopy;
  final VoidCallback onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final password = revealed ? entry.password : List.filled(16, '•').join();

    return KeyelSectionCard(
      title: 'Credentials',
      icon: Icons.key_rounded,
      showBorder: true,
      child: Column(
        children: [
          KeyelFieldSurface(
            label: 'Username',
            trailing: KeyelIconHull(
              icon: Icons.content_copy_rounded,
              tooltip: 'Copy username',
              onPressed: () =>
                  onCopy(entry.username, 'Username copied to clipboard'),
              background: scheme.surfaceContainerHighest,
            ),
            child: Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelFieldSurface(
            label: 'Master Password',
            trailing: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyelIconHull(
                    icon: revealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    tooltip: revealed ? 'Hide password' : 'Reveal password',
                    onPressed: onToggleReveal,
                    size: 44,
                    iconSize: 20,
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  KeyelIconHull(
                    icon: Icons.content_copy_rounded,
                    tooltip: 'Copy password',
                    onPressed: () => onCopy(
                      entry.password,
                      'Password copied • Clears in 30s',
                    ),
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            child: Text(
              password,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KeyelTheme.mono(
                context,
                fontSize: revealed ? 18 : 19,
                fontWeight: FontWeight.w700,
                letterSpacing: revealed ? 1.2 : 3,
              ),
            ),
          ),
          if (entry.website != null) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            KeyelFieldSurface(
              label: 'Website URL',
              trailing: KeyelIconHull(
                icon: Icons.open_in_new_rounded,
                tooltip: 'Open website',
                onPressed: onOpenWebsite,
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                entry.website!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: scheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardDetails extends StatelessWidget {
  const new({required this.entry, required this.onCopy});

  final VaultEntry entry;
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KeyelSectionCard(
      title: 'Card details',
      icon: Icons.credit_card_rounded,
      showBorder: true,
      child: Column(
        children: [
          KeyelFieldSurface(
            label: 'Card number',
            trailing: KeyelIconHull(
              icon: Icons.content_copy_rounded,
              tooltip: 'Copy card number',
              onPressed: () => onCopy(
                entry.cardNumber ?? '',
                'Card number copied to clipboard',
              ),
              background: scheme.surfaceContainerHighest,
            ),
            child: Text(
              entry.cardNumber ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KeyelTheme.mono(
                context,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: KeyelFieldSurface(
                  label: 'Expiry',
                  child: Text(
                    entry.cardExpiry ?? '',
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm + 4),
              Expanded(
                child: KeyelFieldSurface(
                  label: 'Cardholder',
                  child: Text(
                    entry.cardholder ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
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

class _HealthCard extends StatelessWidget {
  const new({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasPassword = entry.hasPassword;
    final strength = PasswordStrength.estimate(entry.password);

    final (accent, container, onContainer, message) = !hasPassword
        ? (
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHigh,
            scheme.onSurfaceVariant,
            'No password stored for this item.',
          )
        : switch (strength.level) {
            PasswordStrengthLevel.strong => (
              scheme.strong,
              scheme.strongContainer,
              scheme.onStrongContainer,
              'Last changed 4 months ago • No breaches found',
            ),
            PasswordStrengthLevel.fair => (
              scheme.fair,
              scheme.fairContainer,
              scheme.onFairContainer,
              'Consider rotating this password when convenient.',
            ),
            PasswordStrengthLevel.weak => (
              scheme.weak,
              scheme.weakContainer,
              scheme.onWeakContainer,
              'Rotate this password now.',
            ),
          };

    final label = hasPassword
        ? '${strength.label} password (${entry.password.length} chars)'
        : 'No password';

    return KeyelSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: container, shape: BoxShape.circle),
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 22,
              color: accent,
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyelBadge(
                  label: label,
                  background: container,
                  foreground: onContainer,
                ),
                const SizedBox(height: KeyelSpacing.sm),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingEntry extends StatelessWidget {
  const new({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KeyelSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 56, color: scheme.outline),
                const SizedBox(height: KeyelSpacing.lg),
                Text(
                  'Entry not found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: KeyelSpacing.sm),
                Text(
                  'No demo entry exists for "$entryId".',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                KeyelPillButton(
                  label: 'Back to vault',
                  expand: false,
                  onPressed: () => context.go(KeyelRoutes.vault),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
