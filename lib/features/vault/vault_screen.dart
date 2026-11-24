import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_revision_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/quick_actions/quick_actions_sheet.dart';
import 'package:keyel/features/vault/vault_list_callbacks.dart';
import 'package:keyel/features/vault/vault_list_controller.dart';
import 'package:keyel/features/vault/vault_list_dialogs.dart';
import 'package:keyel/features/vault/widgets/create_vault_view.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/features/vault/widgets/vault_layout.dart';
import 'package:keyel/features/vault/widgets/vault_list_pane.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Vault screen — the home tab showing saved credentials or unlock state.
///
/// When mounted at `/vault/entry/:id`, [selectedEntryId] comes from the URL.
/// The router is the only source of truth for the selection: a wide window
/// shows it in the detail pane, a compact window shows the full-screen detail.
class VaultScreen extends ConsumerStatefulWidget {
  /// Creates the vault screen.
  const new({this.selectedEntryId, super.key});

  /// Entry selected by the canonical route, or `null` for the plain list.
  final String? selectedEntryId;

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  late final VaultListController _controller;

  /// Resolved in [didChangeDependencies] because the callbacks are created in
  /// [initState], where no localized copy may be looked up yet.
  late String _nothingToCopy;

  @override
  void initState() {
    super.initState();
    _controller = VaultListController(
      repository: ref.read(vaultRepositoryProvider),
      callbacks: _createCallbacks(),
    );
    _controller.setSelectedEntry(widget.selectedEntryId);
    if (ref.read(vaultSessionProvider).status == VaultStatus.unlocked) {
      unawaited(_controller.load());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nothingToCopy = l10nOf(context).vaultNothingToCopy;
  }

  @override
  void didUpdateWidget(covariant VaultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEntryId != widget.selectedEntryId) {
      _controller.setSelectedEntry(widget.selectedEntryId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VaultListCallbacks _createCallbacks() => VaultListCallbacks(
    rebuild: () {
      if (mounted) setState(() {});
    },
    notify: (message, {icon, actionLabel, onAction}) {
      if (!mounted) return;
      showKeyelSnack(
        context,
        message,
        icon: icon ?? Icons.check_circle_rounded,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    },
    notifyError: (error) {
      if (mounted) showKeyelSnack(context, describeVaultError(error));
    },
    copy: (value, message) {
      if (!mounted) return;
      if (value.isEmpty) {
        showKeyelSnack(
          context,
          _nothingToCopy,
          icon: Icons.info_outline_rounded,
        );
        return;
      }
      unawaited(SensitiveClipboard.instance.copy(value));
      unawaited(Haptics.light());
      showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
    },
    confirmDelete: (count) => confirmVaultDelete(context, count),
    pickFolder: () => pickVaultFolder(context, _controller.folders),
  );

  /// Selecting a row always goes through the canonical URL, on every window
  /// size. `isWide` is still supplied by the list so it can highlight the row.
  void _openEntry(VaultEntry entry, {required bool isWide}) {
    context.go(KeyelRoutes.vaultEntryDetail(entry.id));
    unawaited(_controller.load());
  }

  Future<void> _openNewEntry() async {
    await context.push(KeyelRoutes.newEntry);
    if (mounted) unawaited(_controller.load());
  }

  void _lockVault() {
    ref.read(vaultSessionProvider.notifier).lock();
    showKeyelSnack(
      context,
      l10nOf(context).vaultLocked,
      icon: Icons.lock_rounded,
    );
  }

  /// Clears the canonical selection instead of popping a route that was never
  /// pushed for the embedded detail pane.
  void _closeDetail() {
    context.go(KeyelRoutes.vault);
    unawaited(_controller.load());
  }

  void _afterDetailDeleted() {
    _closeDetail();
  }

  @override
  Widget build(BuildContext context) {
    // Only the lifecycle drives the shell; a `busy`/`error` change must not
    // rebuild the whole vault list.
    final status = ref.watch(
      vaultSessionProvider.select((state) => state.status),
    );
    ref.listen(vaultSessionProvider.select((state) => state.status), (
      previous,
      next,
    ) {
      if (next == VaultStatus.unlocked && previous != VaultStatus.unlocked) {
        unawaited(_controller.load());
      } else if (previous == VaultStatus.unlocked && next != previous) {
        _controller.clearSelection();
      }
    });

    // A bulk mutation (import, restore) bumps the revision so the list reloads
    // even though this screen stays alive in its navigation branch.
    ref.listen(vaultRevisionProvider, (_, _) {
      if (ref.read(vaultSessionProvider).status == VaultStatus.unlocked) {
        unawaited(_controller.load());
      }
    });

    final content = switch (status) {
      VaultStatus.noVault => const CreateVaultView(),
      VaultStatus.locked => const UnlockVaultView(),
      VaultStatus.unlocked => _buildUnlockedVault(context),
    };

    // Back clears the canonical selection on both layouts. Nothing was pushed
    // for the embedded pane, so a plain pop would leave the vault tab.
    if (status != VaultStatus.unlocked || widget.selectedEntryId == null) {
      return content;
    }
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeDetail();
      },
      child: content,
    );
  }

  Widget _buildUnlockedVault(BuildContext context) {
    final selectedId = widget.selectedEntryId;
    final isWide =
        maybeEffectiveLayoutOf(context)?.supportsListDetail ??
        WindowSizeClass.of(context).supportsListDetail;

    // On a phone the same URL renders the full-screen detail. The list pane is
    // not mounted, so no masked row can remain behind the revealed fields.
    if (selectedId != null && !isWide) {
      return EntryDetailScreen(
        key: ValueKey(selectedId),
        entryId: selectedId,
        onBack: _closeDetail,
        onDeleted: _afterDetailDeleted,
        onEdited: () => unawaited(_controller.load()),
      );
    }

    // The system back button leaves selection mode instead of the screen.
    final listPane = PopScope(
      canPop: !_controller.selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.clearSelection();
      },
      child: VaultListPane(
        controller: _controller,
        onLock: _lockVault,
        onNewItem: () => unawaited(_openNewEntry()),
        onOpenEntry: _openEntry,
        onQuickActions: () => showQuickActions(context),
      ),
    );

    return VaultLayout(
      listPane: listPane,
      entryId: selectedId,
      onDeleted: _afterDetailDeleted,
      onEdited: () => unawaited(_controller.load()),
      onNewItem: () => unawaited(_openNewEntry()),
      onCloseDetail: _closeDetail,
    );
  }
}
