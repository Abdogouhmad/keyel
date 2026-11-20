import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Folders from the unlocked vault, ordered as the vault stores them.
///
/// Screens invalidate this provider after any folder mutation. It resolves to
/// an empty list instead of throwing when the vault is not open, which keeps
/// pickers usable while a lock is in flight.
final foldersProvider = FutureProvider<List<FolderDto>>((ref) {
  if (ref.watch(vaultSessionProvider.select((state) => state.status)) !=
      VaultStatus.unlocked) {
    return Future.value(const <FolderDto>[]);
  }
  return ref.watch(vaultRepositoryProvider).listFolders();
});
