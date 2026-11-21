import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/trash/widgets/trash_widgets.dart';
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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
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
      setState(() {
        _loading = false;
        _loadError = describeVaultError(error);
      });
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

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Trash',
              icon: Icons.arrow_back_rounded,
              iconTooltip: 'Back',
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
            const TrashInfoBanner(),
            Expanded(child: KeyelContent(child: _buildBody(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const KeyelStateMessage(
        kind: KeyelStateMessageKind.loading,
        message: 'Loading deleted items…',
      );
    }
    if (_loadError != null) {
      return KeyelStateMessage(
        kind: KeyelStateMessageKind.error,
        message: _loadError!,
        actionLabel: 'Retry',
        onAction: () => unawaited(_load()),
      );
    }
    if (_deleted.isEmpty) {
      return const TrashEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.pageMargin,
        KeyelSpacing.sm,
        context.pageMargin,
        KeyelSpacing.xxl,
      ),
      itemCount: _deleted.length,
      separatorBuilder: (_, _) => const SizedBox(height: KeyelSpacing.sm),
      itemBuilder: (context, index) {
        final entry = _deleted[index];
        return TrashEntryTile(
          entry: entry,
          busy: _busy,
          onRestore: () => unawaited(_restore(entry)),
          onPurge: () => unawaited(_purge(entry)),
        );
      },
    );
  }
}
