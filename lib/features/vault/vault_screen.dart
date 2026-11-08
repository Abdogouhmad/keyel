import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
// import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Filter families available in the vault.
enum _VaultFilter {
  all,
  logins,
  cards,
  notes,
  favorites,
  twoFactor;

  String get label => switch (this) {
    _VaultFilter.all => 'All',
    _VaultFilter.logins => 'Logins',
    _VaultFilter.cards => 'Cards',
    _VaultFilter.notes => 'Notes',
    _VaultFilter.favorites => 'Favorites',
    _VaultFilter.twoFactor => '2FA',
  };
}

/// Vault screen — the home tab showing saved credentials or unlock/setup state.
class VaultScreen extends ConsumerStatefulWidget {
  /// Creates the vault screen.
  const new({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _searchController = TextEditingController();
  List<VaultEntry> _entries = [];
  bool _loading = false;
  _VaultFilter _filter = _VaultFilter.all;
  String _query = '';
  String? _selectedEntryId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEntries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final session = ref.read(vaultSessionProvider);
    if (session.status != VaultStatus.unlocked) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(vaultRepositoryProvider);
      final summaries = await repo.listEntries(
        query: _query,
        kind: switch (_filter) {
          _VaultFilter.logins => EntryKindDto.login,
          _VaultFilter.cards => EntryKindDto.card,
          _VaultFilter.notes => EntryKindDto.note,
          _ => null,
        },
        favorite: _filter == _VaultFilter.favorites ? true : null,
      );

      var entries = summaries.map(VaultEntry.fromSummary).toList();
      if (_filter == _VaultFilter.twoFactor) {
        entries = entries.where((e) => e.hasTotp).toList();
      }

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        if (_selectedEntryId != null &&
            !_entries.any((e) => e.id == _selectedEntryId)) {
          _selectedEntryId = _entries.isNotEmpty ? _entries.first.id : null;
        }
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        showKeyelSnack(context, describeVaultError(error));
      }
    }
  }

  Future<void> _toggleFavorite(VaultEntry entry) async {
    try {
      final repo = ref.read(vaultRepositoryProvider);
      final detail = await repo.getEntry(entry.id);
      final newFav = !entry.favorite;

      await repo.upsertEntry(
        EntryDraft(
          id: detail.id,
          kind: detail.kind,
          title: detail.title,
          tags: detail.tags,
          folderId: detail.folderId,
          favorite: newFav,
          username: detail.login?.username ?? '',
          url: detail.login?.url ?? '',
          totpAlgorithm: detail.login?.totpAlgorithm ?? TotpAlgorithmDto.sha1,
          totpDigits: detail.login?.totpDigits ?? 6,
          totpPeriod: detail.login?.totpPeriod ?? 30,
          cardholder: detail.card?.cardholder ?? '',
          cardExpiry: detail.card?.expiry ?? '',
          cardBrand: detail.card?.brand,
        ),
      );

      await _loadEntries();
      if (!mounted) return;
      showKeyelSnack(
        context,
        newFav
            ? '${entry.title} pinned to favorites'
            : '${entry.title} removed from favorites',
        icon: newFav ? Icons.star_rounded : Icons.star_outline_rounded,
      );
    } on Object catch (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    }
  }

  Future<void> _copyRowValue(VaultEntry entry) async {
    if (entry.kind == VaultEntryKind.login) {
      if (entry.username.isNotEmpty) {
        unawaited(Clipboard.setData(ClipboardData(text: entry.username)));
        showKeyelSnack(
          context,
          'Username copied to clipboard',
          icon: Icons.content_copy_rounded,
        );
      } else {
        try {
          final pass = await ref
              .read(vaultRepositoryProvider)
              .revealField(entry.id, SecretFieldDto.loginPassword);
          unawaited(Clipboard.setData(ClipboardData(text: pass)));
          if (mounted) {
            showKeyelSnack(
              context,
              'Password copied • Clears in 30s',
              icon: Icons.content_copy_rounded,
            );
          }
        } on Object catch (error) {
          if (mounted) showKeyelSnack(context, describeVaultError(error));
        }
      }
    } else if (entry.kind == VaultEntryKind.card) {
      try {
        final cardNum = await ref
            .read(vaultRepositoryProvider)
            .revealField(entry.id, SecretFieldDto.cardNumber);
        unawaited(Clipboard.setData(ClipboardData(text: cardNum)));
        if (mounted) {
          showKeyelSnack(
            context,
            'Card number copied to clipboard',
            icon: Icons.content_copy_rounded,
          );
        }
      } on Object catch (_) {
        if (mounted) {
          unawaited(context.push(KeyelRoutes.entryDetail(entry.id)));
        }
      }
    } else {
      unawaited(context.push(KeyelRoutes.entryDetail(entry.id)));
    }
  }

  void _openEntry(VaultEntry entry, {required bool isWide}) {
    if (isWide) {
      setState(() => _selectedEntryId = entry.id);
    } else {
      unawaited(
        context.push(KeyelRoutes.entryDetail(entry.id)).then((_) {
          if (mounted) unawaited(_loadEntries());
        }),
      );
    }
  }

  Future<void> _openNewEntry() async {
    await context.push(KeyelRoutes.newEntry);
    if (mounted) unawaited(_loadEntries());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultSessionProvider);

    return switch (session.status) {
      VaultStatus.noVault => const _CreateVaultView(),
      VaultStatus.locked => const _UnlockVaultView(),
      VaultStatus.unlocked => _buildUnlockedVault(context),
    };
  }

  Widget _buildUnlockedVault(BuildContext context) {
    final windowClass = WindowSizeClass.of(context);
    final isWide =
        !windowClass.isCompact && MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              SizedBox(
                width: 380,
                child: _buildListPane(context, isWide: true),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: 0.5),
              ),
              Expanded(
                child: _selectedEntryId != null
                    ? EntryDetailScreen(
                        key: ValueKey(_selectedEntryId),
                        entryId: _selectedEntryId!,
                        isEmbedded: true,
                        onDeleted: () {
                          setState(() => _selectedEntryId = null);
                          unawaited(_loadEntries());
                        },
                        onEdited: () => unawaited(_loadEntries()),
                      )
                    : const _EmptyDetailPlaceholder(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: _buildListPane(context, isWide: false),
      ),
      floatingActionButton: _NewEntryFab(
        onTap: () => unawaited(_openNewEntry()),
      ),
    );
  }

  Widget _buildListPane(BuildContext context, {required bool isWide}) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favorites = _entries.where((e) => e.favorite).toList();
    final others = _entries.where((e) => !e.favorite).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KeyelTopBar(
            title: 'Keyel Vault',
            icon: Icons.shield_rounded,
            trailing: KeyelIconHull(
              icon: Icons.lock_rounded,
              tooltip: 'Lock vault',
              onPressed: () {
                ref.read(vaultSessionProvider.notifier).lock();
                showKeyelSnack(
                  context,
                  'Vault locked',
                  icon: Icons.lock_rounded,
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KeyelSpacing.lg,
              KeyelSpacing.xs,
              KeyelSpacing.lg,
              KeyelSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vault',
                        style: textTheme.headlineLarge?.copyWith(
                          color: scheme.onSurface,
                          fontSize: 28,
                          height: 36 / 28,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: KeyelSpacing.sm),
                          Text(
                            '${_entries.length} ${_entries.length == 1 ? "entry" : "entries"} saved offline',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isWide)
                  FilledButton.icon(
                    onPressed: () => unawaited(_openNewEntry()),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Item'),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
          sliver: SliverToBoxAdapter(
            child: KeyelSearchField(
              controller: _searchController,
              hintText: 'Search items, tags or notes...',
              onChanged: (value) {
                _query = value;
                unawaited(_loadEntries());
              },
              trailing: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: KeyelSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
              child: Row(
                children: [
                  for (final filter in _VaultFilter.values) ...[
                    KeyelFilterChip(
                      label: filter.label,
                      selected: _filter == filter,
                      onTap: () {
                        setState(() => _filter = filter);
                        unawaited(_loadEntries());
                      },
                    ),
                    if (filter != _VaultFilter.values.last)
                      const SizedBox(width: KeyelSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KeyelSpacing.lg)),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              query: _query,
              onClear: () {
                _searchController.clear();
                _query = '';
                setState(() => _filter = _VaultFilter.all);
                unawaited(_loadEntries());
              },
              onAddItem: () => unawaited(_openNewEntry()),
            ),
          )
        else if (_query.trim().isNotEmpty)
          ..._section(
            context: context,
            title: 'Results',
            count: _entries.length,
            entries: _entries,
            isWide: isWide,
          )
        else ...[
          if (favorites.isNotEmpty)
            ..._section(
              context: context,
              title: 'Favorites',
              count: favorites.length,
              entries: favorites,
              icon: Icons.star_rounded,
              isWide: isWide,
            ),
          ..._alphabeticalSections(context, others, isWide: isWide),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }

  List<Widget> _alphabeticalSections(
    BuildContext context,
    List<VaultEntry> entries, {
    required bool isWide,
  }) {
    final groups = <String, List<VaultEntry>>{};
    for (final entry in entries) {
      final letter = entry.title.isEmpty
          ? '#'
          : entry.title.substring(0, 1).toUpperCase();
      groups.putIfAbsent(letter, () => []).add(entry);
    }
    final letters = groups.keys.toList()..sort();

    return [
      for (final letter in letters) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KeyelSpacing.md + KeyelSpacing.xs,
              KeyelSpacing.sm,
              KeyelSpacing.md + KeyelSpacing.xs,
              KeyelSpacing.sm,
            ),
            child: KeyelLetterHeader(letter: letter),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
          sliver: SliverList.list(
            children: [
              for (final entry in groups[letter]!) ...[
                _VaultRow(
                  entry: entry,
                  favorite: entry.favorite,
                  isSelected: isWide && _selectedEntryId == entry.id,
                  onTap: () => _openEntry(entry, isWide: isWide),
                  onFavorite: () => unawaited(_toggleFavorite(entry)),
                  onCopy: () => unawaited(_copyRowValue(entry)),
                ),
                const SizedBox(height: KeyelSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _section({
    required BuildContext context,
    required String title,
    required int count,
    required List<VaultEntry> entries,
    required bool isWide,
    IconData? icon,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
        sliver: SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KeyelSpacing.xs,
              KeyelSpacing.xs,
              KeyelSpacing.xs,
              KeyelSpacing.sm + 2,
            ),
            child: KeyelSectionLabel(
              label: title,
              icon: icon,
              trailing: Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
        sliver: SliverList.list(
          children: [
            for (final entry in entries) ...[
              _VaultRow(
                entry: entry,
                favorite: entry.favorite,
                isSelected: isWide && _selectedEntryId == entry.id,
                onTap: () => _openEntry(entry, isWide: isWide),
                onFavorite: () => unawaited(_toggleFavorite(entry)),
                onCopy: () => unawaited(_copyRowValue(entry)),
              ),
              const SizedBox(height: KeyelSpacing.sm),
            ],
          ],
        ),
      ),
    ];
  }
}

class _VaultRow extends StatelessWidget {
  const new({
    required this.entry,
    required this.favorite,
    required this.isSelected,
    required this.onTap,
    required this.onFavorite,
    required this.onCopy,
  });

  final VaultEntry entry;
  final bool favorite;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.tile),
      semanticLabel: 'Open ${entry.title}',
      child: Container(
        height: favorite ? 76 : 72,
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.sm + 4,
          vertical: KeyelSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.6)
              : scheme.surfaceContainer,
          border: isSelected
              ? Border.all(
                  color: scheme.primary.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : null,
          borderRadius: BorderRadius.circular(KeyelRadii.tile),
        ),
        child: Row(
          children: [
            KeyelAvatar(
              icon: entry.icon,
              tone: entry.avatarTone,
              shape: entry.avatarShape,
              size: favorite ? 48 : 44,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (entry.hasTotp) ...[
                        const SizedBox(width: KeyelSpacing.sm),
                        KeyelBadge(
                          label: '2FA',
                          compact: true,
                          background: scheme.primaryFixed,
                          foreground: scheme.onPrimaryFixed,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    entry.subtitle.isNotEmpty
                        ? entry.subtitle
                        : switch (entry.kind) {
                            VaultEntryKind.login => 'Login',
                            VaultEntryKind.card => 'Payment card',
                            VaultEntryKind.note => 'Secure note',
                          },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: entry.kind == VaultEntryKind.login
                          ? KeyelTheme.monoFamily
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KeyelSpacing.sm),
            KeyelIconHull(
              icon: favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
              onPressed: onFavorite,
              foreground: favorite ? scheme.primary : scheme.outline,
            ),
            if (entry.kind != VaultEntryKind.note) ...[
              const SizedBox(width: KeyelSpacing.xs),
              KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: entry.kind == VaultEntryKind.card
                    ? 'Copy card'
                    : 'Copy credential',
                onPressed: onCopy,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const new({
    required this.query,
    required this.onClear,
    required this.onAddItem,
  });

  final String query;
  final VoidCallback onClear;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final searching = query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.card),
              ),
              child: Icon(
                searching ? Icons.search_off_rounded : Icons.lock_open_rounded,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            Text(
              searching ? 'No matches found' : 'Your vault is empty',
              style: textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              searching
                  ? 'Try a different search term or filter.'
                  : 'Start adding passwords, payment cards, or secure notes. '
                        'Everything is stored locally with zero-knowledge '
                        'encryption.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            if (searching)
              KeyelPillButton(
                label: 'Clear filters',
                icon: Icons.refresh_rounded,
                tone: KeyelButtonTone.tonal,
                height: 48,
                expand: false,
                onPressed: onClear,
              )
            else
              FilledButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add your first item'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(KeyelRadii.card),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 36,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              'No item selected',
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KeyelSpacing.xs),
            Text(
              'Select an item from the list to view and manage its details.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateVaultView extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_CreateVaultView> createState() => _CreateVaultViewState();
}

class _CreateVaultViewState extends ConsumerState<_CreateVaultView> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _creating = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (pass.isEmpty) {
      showKeyelSnack(context, 'Please choose a master password.');
      return;
    }
    if (pass != confirm) {
      showKeyelSnack(context, 'Passwords do not match.');
      return;
    }

    setState(() => _creating = true);
    try {
      final recoveryKey = await ref
          .read(vaultSessionProvider.notifier)
          .create(pass);
      if (!mounted) return;

      if (recoveryKey != null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.vpn_key_rounded, color: Colors.amber),
                SizedBox(width: KeyelSpacing.sm),
                Text('Recovery Key'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write down or securely store this recovery key offline. '
                  'If you forget your master password, this is the ONLY way '
                  'to regain access to your vault.',
                ),
                const SizedBox(height: KeyelSpacing.md),
                Container(
                  padding: const EdgeInsets.all(KeyelSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogCtx)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(KeyelRadii.field),
                  ),
                  child: SelectableText(
                    recoveryKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  unawaited(
                    Clipboard.setData(ClipboardData(text: recoveryKey)),
                  );
                  showKeyelSnack(
                    dialogCtx,
                    'Recovery key copied to clipboard',
                    icon: Icons.content_copy_rounded,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Key'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('I Have Saved It'),
              ),
            ],
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _creating = false);
        showKeyelSnack(context, describeVaultError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KeyelSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                Text(
                  'Welcome to Keyel',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xs),
                Text(
                  'Create your encrypted offline vault. Only you have the key '
                  'to your credentials.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: TextStyle(color: scheme.onSurface),
                  cursorColor: scheme.onSurface,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.md),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  style: TextStyle(color: scheme.onSurface),
                  cursorColor: scheme.onSurface,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Master Password',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  onSubmitted: (_) => unawaited(_create()),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _creating ? null : () => unawaited(_create()),
                    child: _creating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Encrypted Vault'),
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

class _UnlockVaultView extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_UnlockVaultView> createState() => _UnlockVaultViewState();
}

class _UnlockVaultViewState extends ConsumerState<_UnlockVaultView> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _unlocking = false;
  bool _useRecovery = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final input = _passwordController.text.trim();
    if (input.isEmpty) {
      showKeyelSnack(
        context,
        _useRecovery
            ? 'Enter your recovery key.'
            : 'Enter your master password.',
      );
      return;
    }

    setState(() => _unlocking = true);
    try {
      if (_useRecovery) {
        await ref.read(vaultSessionProvider.notifier).unlockWithRecovery(input);
      } else {
        await ref.read(vaultSessionProvider.notifier).unlockWithMaster(input);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _unlocking = false);
        showKeyelSnack(context, describeVaultError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KeyelSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                Text(
                  'Vault is Locked',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xs),
                Text(
                  _useRecovery
                      ? 'Enter your 24-word recovery key to restore access.'
                      : 'Enter your master password to decrypt your '
                            'credentials.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.xl),
                TextField(
                  controller: _passwordController,
                  obscureText: !_useRecovery && _obscure,
                  maxLines: _useRecovery ? 3 : 1,
                  decoration: InputDecoration(
                    labelText: _useRecovery
                        ? 'Recovery Key'
                        : 'Master Password',
                    prefixIcon: Icon(
                      _useRecovery
                          ? Icons.vpn_key_rounded
                          : Icons.password_rounded,
                    ),
                    suffixIcon: _useRecovery
                        ? null
                        : IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                  ),
                  onSubmitted: (_) => unawaited(_unlock()),
                ),
                const SizedBox(height: KeyelSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _unlocking ? null : () => unawaited(_unlock()),
                    child: _unlocking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock Vault'),
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useRecovery = !_useRecovery;
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _useRecovery
                        ? 'Unlock with Master Password'
                        : 'Forgot password? Use Recovery Key',
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

class _NewEntryFab extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: onTap,
      elevation: 3,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Item',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
