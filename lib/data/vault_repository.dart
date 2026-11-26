import 'dart:io';

import 'package:keyel/src/rust/api/autofill.dart' as autofill_api;
import 'package:keyel/src/rust/api/breach.dart' as breach_api;
import 'package:keyel/src/rust/api/entries.dart' as entries_api;
import 'package:keyel/src/rust/api/health.dart' as health_api;
import 'package:keyel/src/rust/api/import_export.dart' as import_export_api;
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/src/rust/api/passkeys.dart' as passkeys_api;
import 'package:keyel/src/rust/api/session.dart' as session_api;
import 'package:keyel/src/rust/api/sync.dart' as sync_api;

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

  /// Check a master password without changing the current session.
  Future<bool> verifyMaster(String master) =>
      session_api.verifyMaster(master: master);

  /// Reset the master password using the recovery key; leaves the vault open.
  Future<void> resetMasterWithRecovery({
    required String recoveryKey,
    required String newMaster,
  }) => session_api.resetMasterWithRecovery(
    recoveryKey: recoveryKey,
    newMaster: newMaster,
  );

  /// Toggle an entry's favorite flag without touching its secrets.
  Future<void> setFavorite(String id, {required bool favorite}) async {
    final detail = await getEntry(id);
    await upsertEntry(
      EntryDraft(
        id: detail.id,
        kind: detail.kind,
        title: detail.title,
        tags: detail.tags,
        folderId: detail.folderId,
        favorite: favorite,
        username: detail.login?.username ?? '',
        url: detail.login?.url ?? '',
        totpAlgorithm: detail.login?.totpAlgorithm ?? TotpAlgorithmDto.sha1,
        totpDigits: detail.login?.totpDigits ?? 6,
        totpPeriod: detail.login?.totpPeriod ?? 30,
        cardholder: detail.card?.cardholder ?? '',
        cardExpiry: detail.card?.expiry ?? '',
        cardBrand: detail.card?.brand,
        customFields: [
          for (final f in detail.customFields)
            CustomFieldDraft(
              id: f.id,
              label: f.label,
              kind: f.kind,
              value: f.kind == CustomFieldKindDto.hidden ? null : f.value,
            ),
        ],
      ),
    );
  }

  /// Move several entries to a folder, or to "No folder" with `null`.
  Future<void> moveEntries(List<String> ids, String? folderId) =>
      entries_api.moveEntries(ids: ids, folderId: folderId);

  /// Emits `"locked"` whenever Rust drops the session.
  Stream<String> lockEvents() => session_api.lockEvents();

  /// Analyze the unlocked vault and return a secret-free health report.
  Future<HealthReportDto> analyzeHealth() => health_api.analyzeHealth();

  /// Hash active login passwords in Rust and return only prefixes to fetch.
  ///
  /// No password or full digest crosses this boundary.
  Future<BreachCheckRequestDto> beginBreachCheck() =>
      breach_api.beginBreachCheck();

  /// Compare HIBP range bodies in Rust and return only breach counts.
  Future<BreachReportDto> finishBreachCheck({
    required String token,
    required List<BreachRangeResponseDto> responses,
  }) => breach_api.finishBreachCheck(token: token, responses: responses);

  /// Discard an in-flight breach check (also done automatically on lock).
  void cancelBreachCheck() => breach_api.cancelBreachCheck();

  /// Find logins that can fill the requesting app or site.
  ///
  /// Pass the Android `package` and/or `webDomain`, plus a free-text `query`
  /// for the picker's search box. Results carry no secrets; fetch the chosen
  /// password afterwards with [revealField].
  Future<List<AutofillMatchDto>> findAutofillMatches({
    String? package,
    String? webDomain,
    String query = '',
    bool requireVerified = false,
  }) => autofill_api.findAutofillMatches(
    package: package,
    webDomain: webDomain,
    query: query,
    requireVerified: requireVerified,
  );

  /// Parse an import file and report its contents without changing anything.
  Future<ImportPreviewDto> previewImport(String path) =>
      import_export_api.previewImport(path: path);

  /// Import a Bitwarden or Chrome CSV export into the unlocked vault.
  Future<ImportReportDto> importCsv(String path, ImportModeDto mode) =>
      import_export_api.importCsv(path: path, mode: mode);

  /// Write the unlocked vault to [path] as an encrypted backup.
  Future<void> exportBackup({required String path, required String password}) =>
      import_export_api.exportBackup(path: path, password: password);

  /// Restore an encrypted backup into the unlocked vault.
  Future<ImportReportDto> importBackup({
    required String path,
    required String password,
    required ImportModeDto mode,
  }) => import_export_api.importBackup(
    path: path,
    password: password,
    mode: mode,
  );

  /// Write the unlocked vault to [path] as an **unencrypted** CSV export.
  Future<void> exportCsv(String path) =>
      import_export_api.exportCsv(path: path);

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

  /// List the folders in display order.
  Future<List<FolderDto>> listFolders() => entries_api.listFolders();

  /// Create a folder and return its id.
  Future<String> addFolder(String name) => entries_api.addFolder(name: name);

  /// Rename an existing folder.
  Future<void> renameFolder(String id, String name) =>
      entries_api.renameFolder(id: id, name: name);

  /// Delete a folder. Its entries move to "No folder".
  Future<void> deleteFolder(String id) => entries_api.deleteFolder(id: id);

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
        customFields: const [],
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

  /// Reveal a hidden custom field's plaintext value for an entry.
  ///
  /// Only hidden custom fields can be revealed through this path.
  Future<String> revealCustomField(String id, String fieldId) =>
      entries_api.revealCustomField(id: id, fieldId: fieldId);

  /// List passkey entries matching a relying party ID (secret-free summaries).
  Future<List<EntrySummaryDto>> listPasskeysForRp(String rpId) =>
      passkeys_api.listPasskeysForRp(rpId: rpId);

  /// Create and store a passkey from a WebAuthn creation request.
  ///
  /// Returns the created entry id and the platform response JSON. Private key
  /// material and signing never leave the Rust/session boundary.
  Future<passkeys_api.PasskeyCreateResultDto> createPasskeyForRequest({
    required String requestJson,
    required String origin,
  }) => passkeys_api.createPasskeyForRequest(
    requestJson: requestJson,
    origin: origin,
  );

  /// Build a WebAuthn assertion response for a stored passkey.
  ///
  /// If [credentialIdB64] is omitted, the request succeeds only when there is
  /// exactly one matching passkey for the RP.
  Future<String> getPasskeyAssertionResponse({
    required String requestJson,
    required String origin,
    String? credentialIdB64,
  }) => passkeys_api.getPasskeyAssertionResponse(
    requestJson: requestJson,
    origin: origin,
    credentialIdB64: credentialIdB64,
  );

  /// Non-secret state of opt-in sync.
  Future<SyncStatusDto> syncStatus() => sync_api.syncStatus();

  /// Enable sync and return the one-time pairing code (a bearer secret).
  Future<String> syncEnable(String folderHint) =>
      sync_api.syncEnable(folderHint: folderHint);

  /// Re-display the pairing code from the vault's stored sync secret.
  Future<String> syncPairingCode() => sync_api.syncPairingCode();

  /// Join a sync group with a pairing code from another device.
  Future<SyncStatusDto> syncJoin(String code, String folderHint) =>
      sync_api.syncJoin(code: code, folderHint: folderHint);

  /// Disable sync locally, leaving remote files untouched.
  Future<void> syncDisable() => sync_api.syncDisable();

  /// Pull, merge, push and save in one manual foreground operation.
  Future<SyncReportDto> syncNow(String folderPath) =>
      sync_api.syncNow(folderPath: folderPath);

  /// Force delete the vault file from disk.
  /// Useful for debugging or implementing a "Factory Reset" feature in settings.
  ///
  /// The session key is always wiped, even if the delete fails, so a partial
  /// failure can never leave an unlocked session pointing at a stale file.
  Future<void> forceDeleteVault() async {
    final path = vaultPath;
    try {
      if (path != null) {
        // A reset must remove every copy, not just the main file: the Rust
        // store can recover from `vault.keyel.bak`, and a stale `.tmp` may
        // still hold a complete encrypted vault after an interrupted write.
        for (final suffix in ['', '.bak', '.tmp']) {
          final file = File('$path$suffix');
          try {
            // ignore: avoid_slow_async_io - async keeps the destructive reset off the UI isolate.
            if (await file.exists()) await file.delete();
          } on Object catch (_) {
            // Try the remaining copies even when one delete fails.
          }
        }
      }
    } finally {
      session_api.lock();
    }
  }
}
