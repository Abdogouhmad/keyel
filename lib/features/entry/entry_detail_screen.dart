import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_detail_controller.dart';
import 'package:keyel/features/entry/entry_url.dart';
import 'package:keyel/features/entry/widgets/detail/detail_delete_dialog.dart';
import 'package:keyel/features/entry/widgets/detail/detail_scaffold.dart';
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
      launchUrl: launchEntryUrl,
      confirmDelete: (title) => confirmEntryDelete(context, title),
      pushEdit: (entryId) => context.push(KeyelRoutes.entryEdit(entryId)),
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
    if (!mounted) return;
    // Never claim a copy happened when the field is empty: that would write
    // nothing useful and show a misleading "copied" snackbar.
    if (value.isEmpty) {
      showKeyelSnack(
        context,
        'Nothing to copy',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    unawaited(SensitiveClipboard.instance.copy(value));
    unawaited(Haptics.light());
    showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
  }

  void _closeAfterDelete() {
    if (mounted && !widget.isEmbedded && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // A revealed secret must never survive the vault locking or the app going
    // to the background, even if the 15 s timer has not fired yet.
    ref.listen(vaultSessionProvider.select((state) => state.status), (
      _,
      status,
    ) {
      if (status != VaultStatus.unlocked) _controller.hideAll();
    });

    final entry = _controller.entry;
    final detail = _controller.detail;
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (entry == null || detail == null) {
      return MissingEntry(entryId: widget.entryId);
    }

    return DetailScaffold(
      entry: entry,
      detail: detail,
      isEmbedded: widget.isEmbedded,
      revealedPassword: _controller.revealedPassword,
      revealedCardNumber: _controller.revealedCardNumber,
      revealedCvv: _controller.revealedCvv,
      revealedNote: _controller.revealedNote,
      revealedCustomFields: _controller.revealedCustomFields,
      onBack: () => context.pop(),
      onFavorite: _controller.toggleFavorite,
      onEdit: _controller.openEdit,
      onDelete: _controller.confirmDelete,
      onToggleRevealPassword: _controller.toggleRevealPassword,
      onToggleRevealCard: _controller.toggleRevealCard,
      onToggleRevealNote: _controller.toggleRevealNote,
      onToggleRevealCustomField: _controller.toggleRevealCustomField,
      onCopy: _copy,
      onCopyPassword: _controller.copyPassword,
      onCopyCustomField: _controller.copyCustomField,
      onOpenUrl: _controller.openUrl,
    );
  }
}
