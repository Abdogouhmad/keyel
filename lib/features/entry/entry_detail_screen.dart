import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Detail screen for a single login, card or secure note.
class EntryDetailScreen extends ConsumerStatefulWidget {
  /// Creates an entry detail screen.
  const new({
    required this.entryId,
    this.isEmbedded = false,
    this.onDeleted,
    this.onEdited,
    super.key,
  });

  /// Identifier of the entry to show.
  final String entryId;

  /// Whether this view is embedded in a wide-screen multi-pane layout.
  final bool isEmbedded;

  /// Optional callback when entry is deleted.
  final VoidCallback? onDeleted;

  /// Optional callback when entry is edited.
  final VoidCallback? onEdited;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  EntryDetailDto? _detail;
  VaultEntry? _entry;
  bool _loading = true;
  String? _revealedPassword;
  String? _revealedCardNumber;
  String? _revealedCvv;
  String? _revealedNote;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEntry());
  }

  @override
  void didUpdateWidget(covariant EntryDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryId != widget.entryId) {
      _revealedPassword = null;
      _revealedCardNumber = null;
      _revealedCvv = null;
      _revealedNote = null;
      _hideTimer?.cancel();
      unawaited(_loadEntry());
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() => _loading = true);
    try {
      final detail = await ref
          .read(vaultRepositoryProvider)
          .getEntry(widget.entryId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _entry = VaultEntry.fromDetail(detail);
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _entry = null;
        _loading = false;
      });
      showKeyelSnack(context, describeVaultError(error));
    }
  }

  Future<void> _toggleRevealPassword() async {
    if (_revealedPassword != null) {
      setState(() => _revealedPassword = null);
      _hideTimer?.cancel();
      return;
    }

    try {
      final plain = await ref
          .read(vaultRepositoryProvider)
          .revealField(widget.entryId, SecretFieldDto.loginPassword);
      if (!mounted) return;
      setState(() => _revealedPassword = plain);
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) setState(() => _revealedPassword = null);
      });
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  Future<void> _toggleRevealCard() async {
    if (_revealedCardNumber != null) {
      setState(() {
        _revealedCardNumber = null;
        _revealedCvv = null;
      });
      return;
    }

    try {
      final number = await ref
          .read(vaultRepositoryProvider)
          .revealField(widget.entryId, SecretFieldDto.cardNumber);
      String? cvv;
      try {
        cvv = await ref
            .read(vaultRepositoryProvider)
            .revealField(widget.entryId, SecretFieldDto.cardCvv);
      } on Object catch (_) {}

      if (!mounted) return;
      setState(() {
        _revealedCardNumber = number;
        _revealedCvv = cvv;
      });
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  Future<void> _toggleRevealNote() async {
    if (_revealedNote != null) {
      setState(() => _revealedNote = null);
      return;
    }

    try {
      final content = await ref
          .read(vaultRepositoryProvider)
          .revealField(widget.entryId, SecretFieldDto.noteContent);
      if (!mounted) return;
      setState(() => _revealedNote = content);
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  void _copy(String value, String message) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
  }

  Future<void> _copyPassword() async {
    if (_revealedPassword != null) {
      _copy(_revealedPassword!, 'Password copied • Clears in 30s');
      return;
    }

    try {
      final plain = await ref
          .read(vaultRepositoryProvider)
          .revealField(widget.entryId, SecretFieldDto.loginPassword);
      if (!mounted) return;
      _copy(plain, 'Password copied • Clears in 30s');
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  Future<void> _toggleFavorite() async {
    final detail = _detail;
    if (detail == null) return;

    final newFav = !detail.favorite;
    try {
      await ref
          .read(vaultRepositoryProvider)
          .upsertEntry(
            EntryDraft(
              id: detail.id,
              kind: detail.kind,
              title: detail.title,
              tags: detail.tags,
              folderId: detail.folderId,
              favorite: newFav,
              username: detail.login?.username ?? '',
              url: detail.login?.url ?? '',
              totpAlgorithm:
                  detail.login?.totpAlgorithm ?? TotpAlgorithmDto.sha1,
              totpDigits: detail.login?.totpDigits ?? 6,
              totpPeriod: detail.login?.totpPeriod ?? 30,
              cardholder: detail.card?.cardholder ?? '',
              cardExpiry: detail.card?.expiry ?? '',
              cardBrand: detail.card?.brand,
            ),
          );
      await _loadEntry();
      if (!mounted) return;
      showKeyelSnack(
        context,
        newFav ? '${detail.title} pinned to favorites' : 'Favorite removed',
        icon: newFav ? Icons.star_rounded : Icons.star_outline_rounded,
      );
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  Future<void> _confirmDelete() async {
    final detail = _detail;
    if (detail == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${detail.title}?'),
        content: const Text('This item will be moved to the trash.'),
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
      try {
        await ref.read(vaultRepositoryProvider).deleteEntry(detail.id);
        if (!mounted) return;
        showKeyelSnack(
          context,
          '${detail.title} moved to trash',
          icon: Icons.delete_outline_rounded,
        );
        widget.onDeleted?.call();
        if (!widget.isEmbedded && context.canPop()) {
          context.pop();
        }
      } on Object catch (error) {
        if (mounted) showKeyelSnack(context, describeVaultError(error));
      }
    }
  }

  Future<void> _openEdit() async {
    final detail = _detail;
    if (detail == null) return;

    await context.push(KeyelRoutes.entryEdit(detail.id));
    if (mounted) {
      await _loadEntry();
      widget.onEdited?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final entry = _entry;
    final detail = _detail;
    if (entry == null || detail == null) {
      return _MissingEntry(entryId: widget.entryId);
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailBar(
              favorite: detail.favorite,
              isEmbedded: widget.isEmbedded,
              onBack: () => context.pop(),
              onFavorite: _toggleFavorite,
              onEdit: _openEdit,
              onDelete: _confirmDelete,
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
                    _CardDetails(
                      entry: entry,
                      detail: detail,
                      revealedNumber: _revealedCardNumber,
                      revealedCvv: _revealedCvv,
                      onToggleReveal: _toggleRevealCard,
                      onCopy: _copy,
                    )
                  else if (entry.kind == VaultEntryKind.login)
                    _Credentials(
                      entry: entry,
                      detail: detail,
                      revealedPassword: _revealedPassword,
                      onToggleReveal: _toggleRevealPassword,
                      onCopy: _copy,
                      onCopyPassword: _copyPassword,
                      onOpenWebsite: () => showKeyelSnack(
                        context,
                        'Website: ${detail.login?.url ?? ""}',
                        icon: Icons.open_in_new_rounded,
                      ),
                    )
                  else
                    _NoteDetails(
                      entry: entry,
                      detail: detail,
                      revealedContent: _revealedNote,
                      onToggleReveal: _toggleRevealNote,
                      onCopy: _copy,
                    ),
                  const SizedBox(height: KeyelSpacing.md),
                  _HealthCard(
                    entry: entry,
                    revealedPassword: _revealedPassword,
                  ),
                  if (detail.hasNotes) ...[
                    const SizedBox(height: KeyelSpacing.md),
                    _NotesCard(entryId: detail.id, onCopy: _copy),
                  ],
                  const SizedBox(height: KeyelSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isEmbedded
          ? null
          : SafeArea(
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
                  label: switch (entry.kind) {
                    VaultEntryKind.card => 'Edit card',
                    VaultEntryKind.note => 'Edit note',
                    VaultEntryKind.login => 'Edit login',
                  },
                  icon: Icons.edit_rounded,
                  tone: KeyelButtonTone.tonal,
                  onPressed: _openEdit,
                ),
              ),
            ),
    );
  }
}

class _DetailBar extends StatelessWidget {
  const new({
    required this.favorite,
    required this.isEmbedded,
    required this.onBack,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  final bool favorite;
  final bool isEmbedded;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KeyelSpacing.sm,
        vertical: KeyelSpacing.xs,
      ),
      child: Row(
        children: [
          if (!isEmbedded)
            KeyelIconHull(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: onBack,
            )
          else
            const SizedBox(width: KeyelSpacing.md),
          const Spacer(),
          KeyelIconHull(
            icon: favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            tooltip: favorite ? 'Remove favorite' : 'Add to favorites',
            foreground: favorite ? scheme.primary : scheme.onSurfaceVariant,
            onPressed: onFavorite,
          ),
          const SizedBox(width: KeyelSpacing.xs),
          KeyelIconHull(
            icon: Icons.edit_rounded,
            tooltip: 'Edit entry',
            onPressed: onEdit,
          ),
          const SizedBox(width: KeyelSpacing.xs),
          KeyelIconHull(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete entry',
            foreground: scheme.error,
            onPressed: onDelete,
          ),
        ],
      ),
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
                icon: Icons.folder_rounded,
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
    required this.detail,
    required this.revealedPassword,
    required this.onToggleReveal,
    required this.onCopy,
    required this.onCopyPassword,
    required this.onOpenWebsite,
  });

  final VaultEntry entry;
  final EntryDetailDto detail;
  final String? revealedPassword;
  final VoidCallback onToggleReveal;
  final void Function(String value, String message) onCopy;
  final VoidCallback onCopyPassword;
  final VoidCallback onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final username = detail.login?.username ?? entry.username;
    final isRevealed = revealedPassword != null;
    final displayPass = isRevealed ? revealedPassword! : '••••••••••••';

    return KeyelSectionCard(
      title: 'Credentials',
      icon: Icons.key_rounded,
      showBorder: true,
      child: Column(
        children: [
          if (username.isNotEmpty)
            KeyelFieldSurface(
              label: 'Username',
              trailing: KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy username',
                onPressed: () =>
                    onCopy(username, 'Username copied to clipboard'),
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (username.isNotEmpty) const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelFieldSurface(
            label: 'Password',
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
                    icon: isRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    tooltip: isRevealed ? 'Hide password' : 'Reveal password',
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
                    onPressed: onCopyPassword,
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            child: Text(
              displayPass,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KeyelTheme.mono(
                context,
                fontSize: isRevealed ? 18 : 19,
                fontWeight: FontWeight.w700,
                letterSpacing: isRevealed ? 1.2 : 3,
              ),
            ),
          ),
          if ((detail.login?.url ?? '').isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            KeyelFieldSurface(
              label: 'Website URL',
              trailing: KeyelIconHull(
                icon: Icons.open_in_new_rounded,
                tooltip: 'Website link',
                onPressed: onOpenWebsite,
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                detail.login!.url,
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
  const new({
    required this.entry,
    required this.detail,
    required this.revealedNumber,
    required this.revealedCvv,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final VaultEntry entry;
  final EntryDetailDto detail;
  final String? revealedNumber;
  final String? revealedCvv;
  final VoidCallback onToggleReveal;
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final card = detail.card;
    final isRevealed = revealedNumber != null;
    final displayNum = isRevealed ? revealedNumber! : '•••• •••• •••• ••••';

    return KeyelSectionCard(
      title: 'Card details',
      icon: Icons.credit_card_rounded,
      showBorder: true,
      child: Column(
        children: [
          KeyelFieldSurface(
            label: 'Card number',
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
                    icon: isRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    tooltip: isRevealed ? 'Hide number' : 'Reveal number',
                    onPressed: onToggleReveal,
                    size: 44,
                    iconSize: 20,
                  ),
                  KeyelIconHull(
                    icon: Icons.content_copy_rounded,
                    tooltip: 'Copy card number',
                    onPressed: () => onCopy(
                      revealedNumber ?? '',
                      'Card number copied to clipboard',
                    ),
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            child: Text(
              displayNum,
              style: KeyelTheme.mono(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
          if ((card?.cardholder ?? '').isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            KeyelFieldSurface(
              label: 'Cardholder name',
              trailing: KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy cardholder',
                onPressed: () =>
                    onCopy(card!.cardholder, 'Cardholder name copied'),
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                card!.cardholder,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if ((card?.expiry ?? '').isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            Row(
              children: [
                Expanded(
                  child: KeyelFieldSurface(
                    label: 'Expires',
                    child: Text(
                      card!.expiry,
                      style: KeyelTheme.mono(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Expanded(
                  child: KeyelFieldSurface(
                    label: 'Security code (CVV)',
                    child: Text(
                      revealedCvv ?? '•••',
                      style: KeyelTheme.mono(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteDetails extends StatelessWidget {
  const new({
    required this.entry,
    required this.detail,
    required this.revealedContent,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final VaultEntry entry;
  final EntryDetailDto detail;
  final String? revealedContent;
  final VoidCallback onToggleReveal;
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KeyelSectionCard(
      title: 'Secure note content',
      icon: Icons.description_rounded,
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                revealedContent != null
                    ? 'Decrypted note:'
                    : 'Encrypted content',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              KeyelPillButton(
                label: revealedContent != null ? 'Hide content' : 'Reveal note',
                icon: revealedContent != null
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                tone: KeyelButtonTone.tonal,
                onPressed: onToggleReveal,
              ),
            ],
          ),
          if (revealedContent != null) ...[
            const SizedBox(height: KeyelSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KeyelSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.field),
              ),
              child: SelectableText(
                revealedContent!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onCopy(revealedContent!, 'Note copied'),
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                label: const Text('Copy full note'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const new({required this.entry, this.revealedPassword});

  final VaultEntry entry;
  final String? revealedPassword;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pass = revealedPassword;

    if (pass == null) {
      return KeyelSectionCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.field),
              ),
              child: Icon(Icons.lock_rounded, color: scheme.primary),
            ),
            const SizedBox(width: KeyelSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Encrypted & Protected',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Secrets stay encrypted with Argon2id & ChaCha20-Poly1305.',
                    style: textTheme.bodySmall?.copyWith(
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

    final strength = PasswordStrength.estimate(pass);
    final (accent, container, onContainer) = switch (strength.level) {
      PasswordStrengthLevel.strong => (
        scheme.strong,
        scheme.strongContainer,
        scheme.onStrongContainer,
      ),
      PasswordStrengthLevel.fair => (
        scheme.fair,
        scheme.fairContainer,
        scheme.onFairContainer,
      ),
      PasswordStrengthLevel.weak => (
        scheme.weak,
        scheme.weakContainer,
        scheme.onWeakContainer,
      ),
    };

    return KeyelSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: container,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(Icons.security_rounded, color: accent),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${strength.label} password (${pass.length} chars)',
                  style: textTheme.titleMedium?.copyWith(
                    color: onContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Score: ${(strength.score * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                KeyelStrengthMeter(strength: strength),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends ConsumerWidget {
  const new({required this.entryId, required this.onCopy});

  final String entryId;
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: ref
          .read(vaultRepositoryProvider)
          .revealField(entryId, SecretFieldDto.entryNotes),
      builder: (context, snapshot) {
        final notes = snapshot.data;
        if (notes == null || notes.isEmpty) return const SizedBox.shrink();

        return KeyelSectionCard(
          title: 'Notes',
          icon: Icons.notes_rounded,
          showBorder: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KeyelSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: SelectableText(
              notes,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurface, height: 1.5),
            ),
          ),
        );
      },
    );
  }
}

class _MissingEntry extends StatelessWidget {
  const new({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KeyelSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 56),
              const SizedBox(height: KeyelSpacing.md),
              Text(
                'No entry with ID "$entryId" exists.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KeyelSpacing.md),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
