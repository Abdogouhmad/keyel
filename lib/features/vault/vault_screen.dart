import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_revision_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/vault_list_callbacks.dart';
import 'package:keyel/features/vault/vault_list_controller.dart';
import 'package:keyel/features/vault/vault_list_dialogs.dart';
import 'package:keyel/features/vault/widgets/create_vault_view.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/features/vault/widgets/vault_layout.dart';
import 'package:keyel/features/vault/widgets/vault_list_pane.dart';
import 'package:keyel/ui/keyel.dart';

/// Vault screen — the home tab showing saved credentials or unlock state.
class VaultScreen extends ConsumerStatefulWidget {
  /// Creates the vault screen.
  const new({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  late final VaultListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VaultListController(
      repository: ref.read(vaultRepositoryProvider),
      callbacks: _createCallbacks(),
    );
    if (ref.read(vaultSessionProvider).status == VaultStatus.unlocked) {
      unawaited(_controller.load());
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
      unawaited(SensitiveClipboard.instance.copy(value));
      if (mounted) {
        showKeyelSnack(context, message, icon: Icons.content_copy_rounded);
      }
    },
    confirmDelete: (count) => confirmVaultDelete(context, count),
    pickFolder: () => pickVaultFolder(context, _controller.folders),
  );

  void _openEntry(VaultEntry entry, {required bool isWide}) {
    if (isWide) return _controller.selectDetail(entry.id);
    unawaited(
      context.push(KeyelRoutes.entryDetail(entry.id)).then((_) {
        if (mounted) unawaited(_controller.load());
      }),
    );
  }

  Future<void> _openNewEntry() async {
    await context.push(KeyelRoutes.newEntry);
    if (mounted) unawaited(_controller.load());
  }

  void _lockVault() {
    ref.read(vaultSessionProvider.notifier).lock();
    showKeyelSnack(context, 'Vault locked', icon: Icons.lock_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultSessionProvider);
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

    return switch (session.status) {
      VaultStatus.noVault => const CreateVaultView(),
      VaultStatus.locked => const UnlockVaultView(),
      VaultStatus.unlocked => _buildUnlockedVault(context),
    };
  }

  Widget _buildUnlockedVault(BuildContext context) {
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
      ),
    );

    return VaultLayout(
      listPane: listPane,
      entryId: _controller.selectedEntryId,
      onDeleted: () => unawaited(_controller.onDetailDeleted()),
      onEdited: () => unawaited(_controller.load()),
      onNewItem: () => unawaited(_openNewEntry()),
    );
  }
}
