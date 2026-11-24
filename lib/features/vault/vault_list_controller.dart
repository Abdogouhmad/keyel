import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart' show describeVaultError;
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/vault/primary_secret_copy.dart';
import 'package:keyel/features/vault/vault_list_callbacks.dart';
import 'package:keyel/features/vault/widgets/vault_filter.dart';
import 'package:keyel/features/vault/widgets/vault_folder_bar.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Owns the vault list loading, search/filter state and multi-row selection.
class VaultListController extends ChangeNotifier {
  /// Creates a controller; the screen owns and disposes it.
  new({required this.repository, required this.callbacks});

  /// Delay before a typed search query reaches Rust.
  static const searchDebounce = Duration(milliseconds: 200);

  /// Vault repository used for all data access.
  final VaultRepository repository;

  /// Screen hooks for rebuilds and user feedback.
  final VaultListCallbacks callbacks;

  List<VaultEntry> _entries = [];
  List<FolderDto> _folders = [];
  bool _loading = false;
  String? _loadError;
  VaultFilter _filter = VaultFilter.all;
  String _query = '';
  String? _folderId;
  String? _selectedEntryId;
  final Set<String> _selectedIds = {};
  Timer? _searchDebounceTimer;
  int _loadGeneration = 0;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// The entries currently loaded from the repository.
  List<VaultEntry> get entries => _entries;

  /// Folders available for filtering.
  List<FolderDto> get folders => _folders;

  /// Whether an entry list reload is in flight.
  bool get loading => _loading;

  /// Human-readable message for the last failed load, or `null` on success.
  ///
  /// Kept in UI state so a load failure is never mistaken for an empty vault
  /// once the transient snack bar disappears.
  String? get loadError => _loadError;

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
  List<VaultEntry> get selectedEntries =>
      _entries.where((entry) => _selectedIds.contains(entry.id)).toList();

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
  ///
  /// A generation counter discards results from a load that started before a
  /// newer one, so a slow response cannot overwrite fresher rows.
  Future<void> load() async {
    if (!_unlocked) return;
    // An explicit load (filter, refresh, revision) supersedes a pending typed
    // search, otherwise the debounce would fire against stale filter state.
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = null;
    final generation = ++_loadGeneration;
    _loading = true;
    _loadError = null;
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
      if (generation != _loadGeneration) return;
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
      // Multi-row selection is local and must stay valid after a reload. The
      // detail selection is not: it mirrors the canonical route, so a filtered
      // out entry stays selected until the route itself changes. Build the id
      // set once instead of rescanning for every selected row.
      final visibleIds = _entries.map((entry) => entry.id).toSet();
      _selectedIds.removeWhere((id) => !visibleIds.contains(id));
    } on Object catch (error) {
      if (generation == _loadGeneration) {
        _loadError = describeVaultError(error);
        callbacks.notifyError(error);
      }
    } finally {
      if (generation == _loadGeneration) {
        _loading = false;
        _notifyStateChanged();
      }
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
  ///
  /// The query updates the UI immediately, but the repository call is debounced
  /// so a fast typist does not start one Rust load per keystroke.
  void onSearchChanged(String value) {
    if (_query == value) return;
    _query = value;
    _notifyStateChanged();
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(searchDebounce, () {
      _searchDebounceTimer = null;
      unawaited(load());
    });
  }

  /// Reset the search text, folder and kind filters.
  void clearFilters() {
    _query = '';
    _folderId = null;
    _filter = VaultFilter.all;
    _notifyStateChanged();
    unawaited(load());
  }

  /// Mirror the entry selected by the canonical route into the list highlight.
  ///
  /// The router remains the source of truth; this only keeps the visible row
  /// highlight in sync without duplicating navigation state here.
  void setSelectedEntry(String? entryId) {
    if (_selectedEntryId == entryId) return;
    _selectedEntryId = entryId;
    _notifyStateChanged();
  }

  /// Drop the detail mirror after its entry was deleted.
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
        makeFavorite
            ? currentL10n.vaultItemsPinnedToFavorites(targets.length)
            : currentL10n.vaultItemsRemovedFromFavorites(targets.length),
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
        currentL10n.vaultMovedItemsToFolder(
          ids.length,
          _folderLabel(selection.id),
        ),
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
        currentL10n.vaultItemsMovedToTrash(ids.length),
        icon: Icons.delete_outline_rounded,
      );
    } on Object catch (error) {
      callbacks.notifyError(error);
    }
  }

  /// Copy the primary secret of one row (password, card number, username).
  ///
  /// Precedence lives in [PrimarySecretCopy] so the row button and the swipe
  /// action can never disagree again.
  Future<void> copyPrimarySecret(VaultEntry entry) async {
    try {
      final result = await PrimarySecretCopy.resolve(
        entry,
        repository: repository,
        l10n: currentL10n,
      );
      if (result.hasValue) {
        callbacks.copy(result.value!, result.message);
      } else {
        callbacks.notify(result.message, icon: Icons.info_outline_rounded);
      }
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
            ? currentL10n.vaultEntryPinnedToFavorites(entry.title)
            : currentL10n.vaultEntryRemovedFromFavorites(entry.title),
        icon: makeFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
        actionLabel: currentL10n.vaultUndo,
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
    if (folderId == null) return currentL10n.vaultNoFolder;
    for (final folder in _folders) {
      if (folder.id == folderId) return folder.name;
    }
    return currentL10n.vaultFolder;
  }
}
