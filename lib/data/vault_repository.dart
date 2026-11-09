import 'dart:io';

import 'package:keyel/src/rust/api/entries.dart' as entries_api;
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/src/rust/api/session.dart' as session_api;

/// Thin Dart wrapper around the generated FRB vault API.
class VaultRepository {
  /// Creates a repository. The app owns a single instance via Riverpod.
  new();

  String? _initializedPath;

  /// Configure the vault file path. Must run once during startup.
  void init(String path) {
    _initializedPath = path;
    session_api.init(path: path);
  }

  /// Configured vault path, or `null` before [init].
  String? get vaultPath => _initializedPath ?? session_api.vaultPath();

  /// Whether a vault file exists at [vaultPath].
  ///
  /// Rust owns the configured path, so it is the source of truth. The Dart
  /// [File] check stays as a fallback for tests and for the short window where
  /// the bridge has not been initialized yet.
  bool get vaultExists {
    try {
      if (session_api.vaultExists()) return true;
    } on Object catch (_) {
      // Bridge not initialized (widget tests): fall through to the file check.
    }
    final path = vaultPath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  /// Whether Rust currently holds an unlocked session.
  bool get isUnlocked => session_api.isUnlocked();

  /// Create a vault and return the one-time recovery key.
  Future<String> createVault(String master) =>
      session_api.createVault(master: master);

  /// Unlock with the master password.
  Future<void> unlockWithMaster(String master) =>
      session_api.unlockWithMaster(master: master);

  /// Unlock with the one-time recovery key.
  Future<void> unlockWithRecovery(String recoveryKey) =>
      session_api.unlockWithRecovery(recoveryKey: recoveryKey);

  /// Lock the vault and wipe the session key.
  void lock() => session_api.lock();

  /// Re-wrap the vault key with a new master password.
  Future<void> changeMaster({
    required String oldMaster,
    required String newMaster,
  }) => session_api.changeMaster(oldMaster: oldMaster, newMaster: newMaster);

  /// Emits `"locked"` whenever Rust drops the session.
  Stream<String> lockEvents() => session_api.lockEvents();

  /// Search entries. Results contain no secrets.
  Future<List<EntrySummaryDto>> listEntries({
    String query = '',
    EntryKindDto? kind,
    bool? favorite,
    bool includeDeleted = false,
  }) => entries_api.listEntries(
    query: query,
    kind: kind,
    favorite: favorite,
    includeDeleted: includeDeleted,
  );

  /// Fetch one entry with masked secrets.
  Future<EntryDetailDto> getEntry(String id) => entries_api.getEntry(id: id);

  /// Create or update an entry.
  Future<String> upsertEntry(EntryDraft draft) =>
      entries_api.upsertEntry(draft: draft);

  /// Create a login entry with the defaults used by the debug screen.
  Future<String> createLogin({
    required String title,
    required String username,
    required String password,
    String url = '',
    String? notes,
  }) {
    return upsertEntry(
      EntryDraft(
        kind: EntryKindDto.login,
        title: title,
        notes: notes,
        tags: const [],
        favorite: false,
        username: username,
        password: password,
        url: url,
        totpAlgorithm: TotpAlgorithmDto.sha1,
        totpDigits: 6,
        totpPeriod: 30,
        cardholder: '',
        cardExpiry: '',
      ),
    );
  }

  /// Soft-delete an entry (move to trash).
  Future<void> deleteEntry(String id) => entries_api.deleteEntry(id: id);

  /// Restore an entry from the trash.
  Future<void> restoreEntry(String id) => entries_api.restoreEntry(id: id);

  /// Permanently remove an entry.
  Future<void> purgeEntry(String id) => entries_api.purgeEntry(id: id);

  /// Reveal one secret field. The only path that returns plaintext secrets.
  Future<String> revealField(String id, SecretFieldDto field) =>
      entries_api.revealField(id: id, field: field);

  /// Force delete the vault file from disk.
  /// Useful for debugging or implementing a "Factory Reset" feature in settings.
  void forceDeleteVault() {
    final path = vaultPath;
    if (path != null && File(path).existsSync()) {
      File(path).deleteSync();
    }
    // Ensure Rust session state is also wiped
    session_api.lock();
  }
}
