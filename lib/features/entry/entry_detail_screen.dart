import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_route_observer.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_callbacks.dart';
import 'package:keyel/features/entry/entry_detail_controller.dart';
import 'package:keyel/features/entry/entry_url.dart';
import 'package:keyel/features/entry/widgets/detail/detail_delete_dialog.dart';
import 'package:keyel/features/entry/widgets/detail/detail_scaffold.dart';
import 'package:keyel/features/entry/widgets/detail/missing_entry.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Detail screen for a single login, card or secure note.
class EntryDetailScreen extends ConsumerStatefulWidget {
  /// Creates an entry detail screen.
  const new({
    required this.entryId,
    this.isEmbedded = false,
    this.onDeleted,
    this.onEdited,
    this.onBack,
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

  /// Optional override for the back action.
  ///
  /// The wide master/detail pane uses this to clear the canonical route instead
  /// of popping a navigator route that was never pushed.
  final VoidCallback? onBack;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen>
    with WidgetsBindingObserver, RouteAware {
  late EntryDetailController _controller = _createController();
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (identical(route, _route)) return;
    if (_route != null) keyelRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) keyelRouteObserver.subscribe(this, route);
  }

  /// A route pushed on top of the detail screen (editor, confirm dialog,
  /// another entry) must not leave a revealed secret in the tree underneath.
  @override
  void didPushNext() => _controller.hideAll();

  /// Mask again when returning, in case the timer fired while away.
  @override
  void didPopNext() => _controller.hideAll();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-lock only fires after a background grace period, so a revealed
    // secret would otherwise stay on screen during that whole window when the
    // app is backgrounded. Mask immediately instead.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _controller.hideAll();
    }
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
    if (_route != null) keyelRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
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
        l10nOf(context).entryNothingToCopy,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    unawaited(SensitiveClipboard.instance.copy(value));
    unawaited(Haptics.light());
    showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
  }

  void _closeAfterDelete() {
    if (!mounted) return;
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
    } else if (!widget.isEmbedded && context.canPop()) {
      context.pop();
    }
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
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
    // Loading and error states need the same themed surface and safe area as
    // DetailScaffold; on compact screens KeyelSubShell passes us through bare.
    if (_controller.loading) {
      return _EntryStateScaffold(
        child: KeyelStateMessage(
          kind: KeyelStateMessageKind.loading,
          message: l10n.entryLoading,
        ),
      );
    }
    if (_controller.loadError != null) {
      return _EntryStateScaffold(
        child: KeyelStateMessage(
          kind: KeyelStateMessageKind.error,
          message: _controller.loadError!,
          actionLabel: l10n.actionRetry,
          onAction: () => unawaited(_controller.load()),
        ),
      );
    }
    if (_controller.missing || entry == null || detail == null) {
      return MissingEntry(entryId: widget.entryId, onBack: _goBack);
    }

    return DetailScaffold(
      entry: entry,
      detail: detail,
      isEmbedded: widget.isEmbedded,
      revealedPassword: _controller.revealedPassword,
      revealedCardNumber: _controller.revealedCardNumber,
      revealedCvv: _controller.revealedCvv,
      revealedNote: _controller.revealedNote,
      revealedEntryNotes: _controller.revealedEntryNotes,
      revealedCustomFields: _controller.revealedCustomFields,
      onBack: _goBack,
      onFavorite: _controller.toggleFavorite,
      onEdit: _controller.openEdit,
      onDelete: _controller.confirmDelete,
      onToggleRevealPassword: _controller.toggleRevealPassword,
      onToggleRevealCard: _controller.toggleRevealCard,
      onToggleRevealNote: _controller.toggleRevealNote,
      onToggleRevealEntryNotes: _controller.toggleRevealEntryNotes,
      onToggleRevealCustomField: _controller.toggleRevealCustomField,
      onCopy: _copy,
      onCopyPassword: _controller.copyPassword,
      onCopyCustomField: _controller.copyCustomField,
      onOpenUrl: _controller.openUrl,
    );
  }
}

/// Themed surface for the entry's loading and inline-error states.
class _EntryStateScaffold extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: SafeArea(child: child),
  );
}
