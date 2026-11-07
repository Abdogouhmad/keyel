import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/features/vault/vault_entry.dart';
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

  bool matches(VaultEntry entry, Set<String> favorites) => switch (this) {
    _VaultFilter.all => true,
    _VaultFilter.logins => entry.kind == VaultEntryKind.login,
    _VaultFilter.cards => entry.kind == VaultEntryKind.card,
    _VaultFilter.notes => entry.kind == VaultEntryKind.note,
    _VaultFilter.favorites => favorites.contains(entry.id),
    _VaultFilter.twoFactor => entry.hasTotp,
  };
}

/// Vault screen — the home tab showing saved credentials.
class VaultScreen extends StatefulWidget {
  /// Creates the vault screen.
  const new({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  late final Set<String> _favoriteIds = {
    for (final entry in sampleVaultEntries)
      if (entry.favorite) entry.id,
  };

  _VaultFilter _filter = _VaultFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VaultEntry> get _visibleEntries {
    final query = _query.trim().toLowerCase();
    return sampleVaultEntries.where((entry) {
      final matchesFilter = _filter.matches(entry, _favoriteIds);
      final matchesQuery = query.isEmpty || entry.searchTerms.contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  int _countFor(_VaultFilter filter) => sampleVaultEntries
      .where((entry) => filter.matches(entry, _favoriteIds))
      .length;

  void _toggleFavorite(VaultEntry entry) {
    final isFavorite = _favoriteIds.contains(entry.id);
    setState(() {
      if (isFavorite) {
        _favoriteIds.remove(entry.id);
      } else {
        _favoriteIds.add(entry.id);
      }
    });
    showKeyelSnack(
      context,
      isFavorite
          ? '${entry.title} removed from favourites'
          : '${entry.title} pinned to favourites',
      icon: isFavorite ? Icons.star_outline_rounded : Icons.star_rounded,
    );
  }

  void _copyRowValue(VaultEntry entry) {
    final value = switch (entry.kind) {
      VaultEntryKind.login => entry.username,
      VaultEntryKind.card => entry.cardNumber ?? '',
      VaultEntryKind.note => '',
    };
    if (value.isEmpty) {
      unawaited(context.push(KeyelRoutes.entryDetail(entry.id)));
      return;
    }
    showKeyelSnack(
      context,
      entry.kind == VaultEntryKind.card
          ? 'Card number copied to clipboard'
          : 'Username copied to clipboard',
      icon: Icons.content_copy_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entries = _visibleEntries;
    final favorites = entries
        .where((entry) => _favoriteIds.contains(entry.id))
        .toList();
    final others = entries
        .where((entry) => !_favoriteIds.contains(entry.id))
        .toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KeyelTopBar(
                title: 'Keyel Vault',
                icon: Icons.shield_rounded,
                onIconTap: () => showKeyelSnack(
                  context,
                  'Vault profiles arrive with multi-vault support.',
                  icon: Icons.shield_rounded,
                ),
                trailing: KeyelIconHull(
                  icon: Icons.lock_rounded,
                  tooltip: 'Lock vault',
                  onPressed: () => showKeyelSnack(
                    context,
                    'Vault lock is coming with biometric unlock.',
                    icon: Icons.lock_rounded,
                  ),
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
                          '${sampleVaultEntries.length} entries saved offline',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
                  onChanged: (value) => setState(() => _query = value),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.md,
                  ),
                  child: Row(
                    children: [
                      for (final filter in _VaultFilter.values) ...[
                        KeyelFilterChip(
                          label: filter.label,
                          count: _countFor(filter),
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
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
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  query: _query,
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                      _filter = _VaultFilter.all;
                    });
                  },
                ),
              )
            else if (_query.trim().isNotEmpty)
              ..._section(
                title: 'Results',
                count: entries.length,
                entries: entries,
              )
            else ...[
              if (favorites.isNotEmpty)
                ..._section(
                  title: 'Favourites',
                  count: favorites.length,
                  entries: favorites,
                  icon: Icons.star_rounded,
                ),
              ..._alphabeticalSections(others),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
      floatingActionButton: _NewEntryFab(
        onTap: () => context.push(KeyelRoutes.newEntry),
      ),
    );
  }

  List<Widget> _alphabeticalSections(List<VaultEntry> entries) {
    final groups = <String, List<VaultEntry>>{};
    for (final entry in entries) {
      final letter = entry.title.substring(0, 1).toUpperCase();
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
                  favorite: _favoriteIds.contains(entry.id),
                  onTap: () => context.push(KeyelRoutes.entryDetail(entry.id)),
                  onFavorite: () => _toggleFavorite(entry),
                  onCopy: () => _copyRowValue(entry),
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
    required String title,
    required int count,
    required List<VaultEntry> entries,
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
                favorite: _favoriteIds.contains(entry.id),
                onTap: () => context.push(KeyelRoutes.entryDetail(entry.id)),
                onFavorite: () => _toggleFavorite(entry),
                onCopy: () => _copyRowValue(entry),
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
    required this.onTap,
    required this.onFavorite,
    required this.onCopy,
  });

  final VaultEntry entry;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final showStar = favorite;
    final showCopy = entry.kind != VaultEntryKind.note;

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
          color: scheme.surfaceContainer,
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
                    entry.subtitle,
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
            if (showStar)
              KeyelIconHull(
                icon: Icons.star_rounded,
                tooltip: 'Remove from favourites',
                onPressed: onFavorite,
                foreground: scheme.primary,
              )
            else if (showCopy)
              KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: entry.kind == VaultEntryKind.card
                    ? 'Copy card number'
                    : 'Copy username',
                onPressed: onCopy,
              )
            else
              KeyelIconHull(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Open note',
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const new({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

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
              searching ? 'No matches found' : 'Nothing here yet',
              style: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              searching
                  ? 'Try a different search term or filter.'
                  : 'Try a different filter to see your entries.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: 'Clear filters',
              icon: Icons.refresh_rounded,
              tone: KeyelButtonTone.tonal,
              height: 48,
              expand: false,
              onPressed: onClear,
            ),
          ],
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: KeyelSpacing.sm),
      child: PressableScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KeyelRadii.pill),
        semanticLabel: 'Add new entry',
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: scheme.primaryFixed,
            borderRadius: BorderRadius.circular(KeyelRadii.pill),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: scheme.onPrimaryFixed),
              const SizedBox(width: KeyelSpacing.sm),
              Text(
                'New entry',
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryFixed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
