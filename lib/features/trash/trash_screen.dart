import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Soft-deleted entries with restore, delete-forever and empty-trash actions.
class TrashScreen extends ConsumerStatefulWidget {
  /// Creates the trash screen.
  const new({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  List<EntrySummaryDto> _deleted = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summaries = await ref
          .read(vaultRepositoryProvider)
          .listEntries(includeDeleted: true);
      if (!mounted) return;
      setState(() {
        _deleted = summaries.where((entry) => entry.deletedAt != null).toList();
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _restore(EntrySummaryDto entry) async {
    setState(() => _busy = true);
    try {
      await ref.read(vaultRepositoryProvider).restoreEntry(entry.id);
      if (!mounted) return;
      showKeyelSnack(
        context,
        '"${entry.title}" restored',
        icon: Icons.restore_rounded,
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purge(EntrySummaryDto entry) async {
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: 'Delete forever?',
      body: '"${entry.title}" cannot be recovered after this.',
      confirmLabel: 'Delete forever',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(vaultRepositoryProvider).purgeEntry(entry.id);
      if (!mounted) return;
      showKeyelSnack(
        context,
        'Entry permanently deleted',
        icon: Icons.delete_forever_rounded,
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emptyTrash() async {
    if (_deleted.isEmpty) return;
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: 'Empty trash?',
      body:
          'All ${_deleted.length} trashed '
          '${_deleted.length == 1 ? "entry" : "entries"} will be deleted '
          'forever.',
      confirmLabel: 'Empty trash',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final repository = ref.read(vaultRepositoryProvider);
      for (final entry in _deleted) {
        await repository.purgeEntry(entry.id);
      }
      if (!mounted) return;
      showKeyelSnack(
        context,
        'Trash emptied',
        icon: Icons.delete_sweep_rounded,
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Trash',
              icon: Icons.arrow_back_rounded,
              onIconTap: () => context.pop(),
              trailing: KeyelIconHull(
                icon: Icons.delete_sweep_rounded,
                tooltip: 'Empty trash',
                foreground: _deleted.isEmpty ? null : scheme.error,
                onPressed: _deleted.isEmpty || _busy
                    ? null
                    : () => unawaited(_emptyTrash()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KeyelSpacing.lg,
                KeyelSpacing.xs,
                KeyelSpacing.lg,
                KeyelSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KeyelSpacing.sm),
                  Expanded(
                    child: Text(
                      'Deleted items stay here for 30 days, then disappear '
                      'automatically.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_deleted.isEmpty) {
      return _TrashEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        KeyelSpacing.md,
        KeyelSpacing.sm,
        KeyelSpacing.md,
        KeyelSpacing.xxl,
      ),
      itemCount: _deleted.length,
      separatorBuilder: (_, _) => const SizedBox(height: KeyelSpacing.sm),
      itemBuilder: (context, index) {
        final entry = _deleted[index];
        return _TrashTile(
          entry: entry,
          busy: _busy,
          onRestore: () => unawaited(_restore(entry)),
          onPurge: () => unawaited(_purge(entry)),
        );
      },
    );
  }
}

class _TrashTile extends StatelessWidget {
  const new({
    required this.entry,
    required this.busy,
    required this.onRestore,
    required this.onPurge,
  });

  final EntrySummaryDto entry;
  final bool busy;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  String get _remainingLabel {
    final deletedAt = entry.deletedAt;
    if (deletedAt == null) return 'Deleted';
    final deleted = DateTime.fromMillisecondsSinceEpoch(
      deletedAt.toInt() * 1000,
    );
    final days = 30 - DateTime.now().difference(deleted).inDays;
    final remaining = days < 0 ? 0 : days;
    return 'Auto-deletes in $remaining ${remaining == 1 ? "day" : "days"}';
  }

  IconData get _kindIcon => switch (entry.kind) {
    EntryKindDto.login => Icons.key_rounded,
    EntryKindDto.card => Icons.credit_card_rounded,
    EntryKindDto.note => Icons.sticky_note_2_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KeyelSectionCard(
      showBorder: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(_kindIcon, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _remainingLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          KeyelIconHull(
            icon: Icons.restore_rounded,
            tooltip: 'Restore',
            foreground: scheme.primary,
            size: 40,
            iconSize: 20,
            onPressed: busy ? null : onRestore,
          ),
          KeyelIconHull(
            icon: Icons.delete_forever_rounded,
            tooltip: 'Delete forever',
            foreground: scheme.error,
            size: 40,
            iconSize: 20,
            onPressed: busy ? null : onPurge,
          ),
        ],
      ),
    );
  }
}

class _TrashEmptyState extends StatelessWidget {
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
            Icon(
              Icons.delete_outline_rounded,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              'Trash is empty',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KeyelSpacing.xs),
            Text(
              'Deleted entries appear here for 30 days before they are '
              'removed permanently.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
