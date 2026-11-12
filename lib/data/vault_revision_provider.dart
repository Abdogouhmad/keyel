import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A monotonically increasing counter that screens bump after a bulk mutation
/// (an import or a restore) to ask the vault list to reload.
///
/// The vault list is owned by a screen-local `VaultListController`, so there is
/// no provider to invalidate directly. Instead screens that change many entries
/// at once call `bumpVaultRevision(ref)`, and `VaultScreen` listens here and
/// reloads.
final vaultRevisionProvider = NotifierProvider<VaultRevisionNotifier, int>(
  VaultRevisionNotifier.new,
);

/// Owns the vault revision counter.
class VaultRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Increment the counter, notifying every listener.
  void bump() => state = state + 1;
}

/// Ask every vault view to reload from the repository.
void bumpVaultRevision(WidgetRef ref) {
  ref.read(vaultRevisionProvider.notifier).bump();
}
