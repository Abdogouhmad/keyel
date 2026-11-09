import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_detail_controller.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/detail/detail_bar.dart';
import 'package:keyel/features/entry/widgets/detail/detail_content.dart';
import 'package:keyel/features/entry/widgets/detail/missing_entry.dart';
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
  late EntryDetailController _controller = _createController();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
  }

  @override
  void didUpdateWidget(covariant EntryDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryId != widget.entryId) {
      _controller.dispose();
      _controller = _createController();
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  EntryDetailController _createController() => EntryDetailController(
    entryId: widget.entryId,
    repository: ref.read(vaultRepositoryProvider),
    callbacks: EntryDetailCallbacks(
      rebuild: _rebuild,
      notify: _notify,
      notifyError: _notifyError,
      copy: _copy,
      confirmDelete: _confirmDeleteDialog,
      pushEdit: _pushEdit,
      closeEntry: _closeAfterDelete,
      onDeleted: widget.onDeleted,
      onEdited: widget.onEdited,
    ),
  );

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _notify(String message, {IconData? icon}) {
    if (mounted) {
      showKeyelSnack(context, message, icon: icon ?? Icons.key_rounded);
    }
  }

  void _notifyError(Object error) {
    if (mounted) showKeyelSnack(context, describeVaultError(error));
  }

  void _copy(String value, String message) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
  }

  Future<bool> _confirmDeleteDialog(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $title?'),
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
    return confirmed ?? false;
  }

  Future<void> _pushEdit(String entryId) =>
      context.push(KeyelRoutes.entryEdit(entryId));

  void _closeAfterDelete() {
    if (!mounted) return;
    if (!widget.isEmbedded && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final entry = _controller.entry;
    final detail = _controller.detail;
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (entry == null || detail == null) {
      return MissingEntry(entryId: widget.entryId);
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailBar(
              favorite: detail.favorite,
              isEmbedded: widget.isEmbedded,
              onBack: () => context.pop(),
              onFavorite: _controller.toggleFavorite,
              onEdit: _controller.openEdit,
              onDelete: _controller.confirmDelete,
            ),
            Expanded(
              child: DetailContent(
                entry: entry,
                detail: detail,
                revealedPassword: _controller.revealedPassword,
                revealedCardNumber: _controller.revealedCardNumber,
                revealedCvv: _controller.revealedCvv,
                revealedNote: _controller.revealedNote,
                onToggleRevealPassword: _controller.toggleRevealPassword,
                onToggleRevealCard: _controller.toggleRevealCard,
                onToggleRevealNote: _controller.toggleRevealNote,
                onCopy: _copy,
                onCopyPassword: _controller.copyPassword,
                onOpenWebsite: () => _notify(
                  'Website: ${detail.login?.url ?? ''}',
                  icon: Icons.open_in_new_rounded,
                ),
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
                  onPressed: _controller.openEdit,
                ),
              ),
            ),
    );
  }
}
