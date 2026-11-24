import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/trash/widgets/trash_widgets.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
        l10nOf(context).trashRestored(entry.title),
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
    final l10n = l10nOf(context);
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.trashDeleteForeverTitle,
      body: l10n.trashDeleteForeverBody(entry.title),
      confirmLabel: l10n.trashDeleteForever,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(vaultRepositoryProvider).purgeEntry(entry.id);
      if (!mounted) return;
      showKeyelSnack(
        context,
        l10n.trashPermanentlyDeleted,
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
    final l10n = l10nOf(context);
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.trashEmptyConfirmTitle,
      body: l10n.trashEmptyConfirmBody(_deleted.length),
      confirmLabel: l10n.trashEmptyAction,
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
        l10n.trashEmptied,
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
    final l10n = l10nOf(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: l10n.trashTitle,
              icon: context.backArrow,
              iconTooltip: l10n.actionBack,
              onIconTap: () => context.pop(),
              trailing: KeyelIconHull(
                icon: Icons.delete_sweep_rounded,
                tooltip: l10n.trashEmptyAction,
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
    final l10n = l10nOf(context);
    if (_loading) {
      return KeyelStateMessage(
        kind: KeyelStateMessageKind.loading,
        message: l10n.trashLoading,
      );
    }
    if (_loadError != null) {
      return KeyelStateMessage(
        kind: KeyelStateMessageKind.error,
        message: _loadError!,
        actionLabel: l10n.actionRetry,
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
