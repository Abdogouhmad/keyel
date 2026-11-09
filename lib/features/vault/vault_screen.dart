import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/widgets/create_vault_view.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/features/vault/widgets/vault_filter.dart';
import 'package:keyel/features/vault/widgets/vault_folder_bar.dart';
import 'package:keyel/features/vault/widgets/vault_layout.dart';
import 'package:keyel/features/vault/widgets/vault_list_pane.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Vault screen — the home tab showing saved credentials or unlock state.
class VaultScreen extends ConsumerStatefulWidget {
  /// Creates the vault screen.
  const new({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  List<VaultEntry> _entries = [];
  List<FolderDto> _folders = [];
  bool _loading = false;
  VaultFilter _filter = VaultFilter.all;
  String _query = '';
  String? _folderId;
  String? _selectedEntryId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEntries());
  }

  Future<void> _loadEntries() async {
    if (ref.read(vaultSessionProvider).status != VaultStatus.unlocked) return;

    setState(() => _loading = true);
    try {
      final repository = ref.read(vaultRepositoryProvider);
      final summaries = await repository.listEntries(
        query: _query,
        kind: switch (_filter) {
          VaultFilter.logins => EntryKindDto.login,
          VaultFilter.cards => EntryKindDto.card,
          VaultFilter.notes => EntryKindDto.note,
          _ => null,
        },
        favorite: _filter == VaultFilter.favorites ? true : null,
      );
      final folders = await repository.listFolders();
      final folderNames = {
        for (final folder in folders) folder.id: folder.name,
      };

      var visible = summaries;
      final folderId = _folderId;
      if (folderId != null) {
        visible = folderId == noFolderSelection
            ? summaries.where((s) => s.folderId == null).toList()
            : summaries.where((s) => s.folderId == folderId).toList();
      }

      var entries = visible
          .map(
            (summary) =>
                VaultEntry.fromSummary(summary, folderNames: folderNames),
          )
          .toList();
      if (_filter == VaultFilter.twoFactor) {
        entries = entries.where((e) => e.hasTotp).toList();
      }

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _folders = folders;
        // Drop a folder filter that no longer exists (for example after the
        // folder was deleted in Settings).
        if (_folderId != null &&
            _folderId != noFolderSelection &&
            !folders.any((folder) => folder.id == _folderId)) {
          _folderId = null;
        }
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

  void _lockVault() {
    ref.read(vaultSessionProvider.notifier).lock();
    showKeyelSnack(context, 'Vault locked', icon: Icons.lock_rounded);
  }

  void _setFilter(VaultFilter filter) {
    setState(() => _filter = filter);
    unawaited(_loadEntries());
  }

  void _setFolder(String? folderId) {
    setState(() => _folderId = folderId);
    unawaited(_loadEntries());
  }

  void _onSearchChanged(String value) {
    _query = value;
    unawaited(_loadEntries());
  }

  void _clearFilters() {
    _query = '';
    _folderId = null;
    _setFilter(VaultFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultSessionProvider);
    ref.listen(vaultSessionProvider.select((state) => state.status), (
      previous,
      next,
    ) {
      if (next == VaultStatus.unlocked && previous != VaultStatus.unlocked) {
        unawaited(_loadEntries());
      }
    });

    return switch (session.status) {
      VaultStatus.noVault => const CreateVaultView(),
      VaultStatus.locked => const UnlockVaultView(),
      VaultStatus.unlocked => _buildUnlockedVault(context),
    };
  }

  Widget _buildUnlockedVault(BuildContext context) {
    final listPane = VaultListPane(
      entries: _entries,
      loading: _loading,
      filter: _filter,
      query: _query,
      selectedEntryId: _selectedEntryId,
      folders: _folders,
      selectedFolderId: _folderId,
      onLock: _lockVault,
      onNewItem: () => unawaited(_openNewEntry()),
      onSearchChanged: _onSearchChanged,
      onFilterChanged: _setFilter,
      onFolderChanged: _setFolder,
      onClearFilters: _clearFilters,
      onOpenEntry: _openEntry,
      onRefresh: _loadEntries,
    );

    return VaultLayout(
      listPane: listPane,
      entryId: _selectedEntryId,
      onDeleted: () {
        setState(() => _selectedEntryId = null);
        unawaited(_loadEntries());
      },
      onEdited: () => unawaited(_loadEntries()),
      onNewItem: () => unawaited(_openNewEntry()),
    );
  }
}
