import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/vault_list_callbacks.dart';
import 'package:keyel/features/vault/widgets/vault_filter.dart';
import 'package:keyel/features/vault/widgets/vault_folder_bar.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Owns the vault list loading, search/filter state and multi-row selection.
class VaultListController extends ChangeNotifier {
  /// Creates a controller; the screen owns and disposes it.
  new({required this.repository, required this.callbacks});

  /// Vault repository used for all data access.
  final VaultRepository repository;

  /// Screen hooks for rebuilds and user feedback.
  final VaultListCallbacks callbacks;

  List<VaultEntry> _entries = [];
  List<FolderDto> _folders = [];
  bool _loading = false;
  VaultFilter _filter = VaultFilter.all;
  String _query = '';
  String? _folderId;
  String? _selectedEntryId;
  final Set<String> _selectedIds = {};

  /// The entries currently loaded from the repository.
  List<VaultEntry> get entries => _entries;

  /// Folders available for filtering.
  List<FolderDto> get folders => _folders;

  /// Whether an entry list reload is in flight.
  bool get loading => _loading;

  /// Currently selected filter family.
  VaultFilter get filter => _filter;

  /// The active search query.
  String get query => _query;

  /// `null` for all folders, [noFolderSelection] for unfiled, or a folder id.
  String? get folderId => _folderId;

  /// Identifier of the entry selected in the wide detail pane.
  String? get selectedEntryId => _selectedEntryId;

  /// Whether the user is currently selecting multiple rows.
  bool get selectionMode => _selectedIds.isNotEmpty;

  /// Ids of the rows marked in selection mode.
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Entries backing [selectedIds], in list order.
  List<VaultEntry> get selectedEntries => _entries
      .where((entry) => _selectedIds.contains(entry.id))
      .toList();

  /// Whether every visible row is marked.
  bool get allSelected =>
      _entries.isNotEmpty && _entries.every((e) => _selectedIds.contains(e.id));

  void _notifyStateChanged() => callbacks.rebuild();

  bool get _unlocked {
    try {
      return repository.isUnlocked;
    } on Object catch (_) {
      // The bridge is not initialized (widget tests); treat as locked.
      return false;
    }
  }

  /// Reload entries and folders for the current query and filters.
  Future<void> load() async {
    if (!_unlocked) return;
    _loading = true;
    _notifyStateChanged();
    try {
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

      _entries = entries;
      _folders = folders;
      // Drop a folder filter that no longer exists (for example after the
      // folder was deleted in Settings).
      if (_folderId != null &&
          _folderId != noFolderSelection &&
          !folders.any((folder) => folder.id == _folderId)) {
        _folderId = null;
      }
      // Keep the selection valid when rows disappeared after a reload.
      _selectedIds.removeWhere(
        (id) => !_entries.any((entry) => entry.id == id),
      );
      if (_selectedEntryId != null &&
          !_entries.any((e) => e.id == _selectedEntryId)) {
        _selectedEntryId = _entries.isNotEmpty ? _entries.first.id : null;
      }
    } on Object catch (error) {
      callbacks.notifyError(error);
    } finally {
      _loading = false;
      _notifyStateChanged();
    }
  }

  /// Apply a new filter family and reload.
  void setFilter(VaultFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _notifyStateChanged();
    unawaited(load());
  }

  /// Apply a new folder filter and reload.
  void setFolder(String? folderId) {
    if (_folderId == folderId) return;
    _folderId = folderId;
    _notifyStateChanged();
    unawaited(load());
  }

  /// Live search callback from the search field.
  void onSearchChanged(String value) {
    if (_query == value) return;
    _query = value;
    _notifyStateChanged();
    unawaited(load());
  }

  /// Reset the search text, folder and kind filters.
  void clearFilters() {
    _query = '';
    _folderId = null;
    _filter = VaultFilter.all;
    _notifyStateChanged();
    unawaited(load());
  }

  /// Show an entry in the wide detail pane.
  void selectDetail(String entryId) {
    if (_selectedEntryId == entryId) return;
    _selectedEntryId = entryId;
    _notifyStateChanged();
  }

  /// Clear the detail pane selection after its entry was deleted.
  Future<void> onDetailDeleted() async {
    _selectedEntryId = null;
    await load();
  }

  /// Enter selection mode with a single row marked.
  void startSelection(String entryId) {
    _selectedIds
      ..clear()
      ..add(entryId);
    _notifyStateChanged();
  }

  /// Mark or unmark one row while in selection mode.
  void toggleSelection(String entryId) {
    if (!_selectedIds.remove(entryId)) _selectedIds.add(entryId);
    _notifyStateChanged();
  }

  /// Mark every visible row, or leave selection mode when all are marked.
  void toggleSelectAll() {
    if (allSelected) {
      clearSelection();
      return;
    }
    _selectedIds
      ..clear()
      ..addAll(_entries.map((entry) => entry.id));
    _notifyStateChanged();
  }

  /// Leave selection mode.
  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    _notifyStateChanged();
  }

  /// Pin or unpin every selected row in one go.
  Future<void> toggleFavoriteSelection() async {
    final targets = selectedEntries;
    if (targets.isEmpty) return;
    final makeFavorite = !targets.every((entry) => entry.favorite);
    try {
      for (final entry in targets) {
        await repository.setFavorite(entry.id, favorite: makeFavorite);
      }
      await load();
      callbacks.notify(
        '${targets.length} ${targets.length == 1 ? 'item' : 'items'} '
            '${makeFavorite ? 'pinned to favorites' : 'removed from favorites'}',
        icon: makeFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Move every selected row into a folder picked with the folder sheet.
  Future<void> moveSelection() async {
    if (_selectedIds.isEmpty) return;
    final selection = await callbacks.pickFolder();
    if (selection == null) return; // The sheet was dismissed.

    final ids = _selectedIds.toList();
    try {
      await repository.moveEntries(ids, selection.id);
      clearSelection();
      await load();
      callbacks.notify(
        'Moved ${ids.length} ${ids.length == 1 ? 'item' : 'items'} '
            'to ${_folderLabel(selection.id)}',
        icon: Icons.drive_file_move_rounded,
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Soft-delete every selected row after explicit confirmation.
  Future<void> deleteSelection() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    final confirmed = await callbacks.confirmDelete(ids.length);
    if (!confirmed) return;

    try {
      for (final id in ids) {
        await repository.deleteEntry(id);
      }
      if (_selectedEntryId != null && ids.contains(_selectedEntryId)) {
        _selectedEntryId = null;
      }
      clearSelection();
      await load();
      callbacks.notify(
        '${ids.length} ${ids.length == 1 ? 'item' : 'items'} '
            'moved to trash',
        icon: Icons.delete_outline_rounded,
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Copy the primary secret of one row (password, card number, username).
  Future<void> copyPrimarySecret(VaultEntry entry) async {
    try {
      switch (entry.kind) {
        case VaultEntryKind.login:
          final detail = await repository.getEntry(entry.id);
          if (detail.login?.hasPassword ?? false) {
            final secret = await repository.revealField(
              entry.id,
              SecretFieldDto.loginPassword,
            );
            if (secret.isNotEmpty) {
              callbacks.copy(secret, 'Password copied • Clears in 30s');
              return;
            }
          }
          if (entry.username.isNotEmpty) {
            callbacks.copy(entry.username, 'Username copied to clipboard');
            return;
          }
        case VaultEntryKind.card:
          final detail = await repository.getEntry(entry.id);
          if (detail.card?.hasNumber ?? false) {
            final number = await repository.revealField(
              entry.id,
              SecretFieldDto.cardNumber,
            );
            if (number.isNotEmpty) {
              callbacks.copy(number, 'Card number copied to clipboard');
              return;
            }
          }
        case VaultEntryKind.note:
          break;
      }
      callbacks.notify('Nothing to copy', icon: Icons.info_outline_rounded);
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Toggle one row's favorite flag, offering an undo action.
  Future<void> toggleFavorite(VaultEntry entry) async {
    final makeFavorite = !entry.favorite;
    try {
      await repository.setFavorite(entry.id, favorite: makeFavorite);
      await load();
      callbacks.notify(
        makeFavorite
            ? '${entry.title} pinned to favorites'
            : '${entry.title} removed from favorites',
        icon: makeFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
        actionLabel: 'Undo',
        onAction: () {
          unawaited(
            repository
                .setFavorite(entry.id, favorite: !makeFavorite)
                .then((_) => load()),
          );
        },
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  String _folderLabel(String? folderId) {
    if (folderId == null) return 'No folder';
    for (final folder in _folders) {
      if (folder.id == folderId) return folder.name;
    }
    return 'folder';
  }
}
