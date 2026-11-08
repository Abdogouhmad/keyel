import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/src/rust/api/error.dart';

/// High-level state of the vault session.
enum VaultStatus {
  /// No vault file exists yet.
  noVault,

  /// A vault file exists but Rust holds no key.
  locked,

  /// Rust holds an unlocked session.
  unlocked,
}

/// Immutable snapshot of the vault session.
class VaultSessionState {
  /// Creates a session snapshot.
  const new({required this.status, this.busy = false, this.error});

  /// Current lifecycle state.
  final VaultStatus status;

  /// Whether an async session action is in flight.
  final bool busy;

  /// Last error, already formatted for display.
  final String? error;

  /// Copy with individual fields changed.
  VaultSessionState copyWith({
    VaultStatus? status,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return VaultSessionState(
      status: status ?? this.status,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Shared repository instance.
final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(),
);

/// Vault session state machine.
final vaultSessionProvider =
    NotifierProvider<VaultSessionNotifier, VaultSessionState>(
      VaultSessionNotifier.new,
    );

/// Owns create/unlock/lock actions and mirrors Rust session state.
class VaultSessionNotifier extends Notifier<VaultSessionState> {
  StreamSubscription<String>? _lockSubscription;

  @override
  VaultSessionState build() {
    _listenForLockEvents();
    ref.onDispose(() => _lockSubscription?.cancel());
    unawaited(refresh());
    return const VaultSessionState(status: VaultStatus.noVault, busy: true);
  }

  void _listenForLockEvents() {
    try {
      _lockSubscription = ref.read(vaultRepositoryProvider).lockEvents().listen(
        (event) {
          if (event == 'locked') {
            state = VaultSessionState(status: _lockedStatus());
          }
        },
      );
    } on Object catch (_) {
      // Rust is not initialized (for example in a widget test). Actions will
      // surface the real error when the user tries to use the vault.
    }
  }

  VaultStatus _lockedStatus() {
    try {
      return ref.read(vaultRepositoryProvider).vaultExists
          ? VaultStatus.locked
          : VaultStatus.noVault;
    } on Object catch (_) {
      return VaultStatus.noVault;
    }
  }

  /// Re-read the state from Rust.
  Future<void> refresh() async {
    try {
      final repository = ref.read(vaultRepositoryProvider);
      state = VaultSessionState(
        status: !repository.vaultExists
            ? VaultStatus.noVault
            : repository.isUnlocked
            ? VaultStatus.unlocked
            : VaultStatus.locked,
      );
    } on Object catch (_) {
      state = const VaultSessionState(status: VaultStatus.noVault);
    }
  }

  /// Create a vault and return its one-time recovery key.
  Future<String?> create(String master) async {
    final repository = ref.read(vaultRepositoryProvider);
    state = state.copyWith(busy: true, clearError: true);
    try {
      final recoveryKey = await repository.createVault(master);
      state = const VaultSessionState(status: VaultStatus.unlocked);
      return recoveryKey;
    } catch (error) {
      state = VaultSessionState(
        status: state.status,
        error: describeVaultError(error),
      );
      rethrow;
    }
  }

  /// Unlock with the master password.
  Future<void> unlockWithMaster(String master) async {
    final repository = ref.read(vaultRepositoryProvider);
    state = state.copyWith(busy: true, clearError: true);
    try {
      await repository.unlockWithMaster(master);
      state = const VaultSessionState(status: VaultStatus.unlocked);
    } catch (error) {
      state = VaultSessionState(
        status: state.status,
        error: describeVaultError(error),
      );
      rethrow;
    }
  }

  /// Unlock with the recovery key.
  Future<void> unlockWithRecovery(String recoveryKey) async {
    final repository = ref.read(vaultRepositoryProvider);
    state = state.copyWith(busy: true, clearError: true);
    try {
      await repository.unlockWithRecovery(recoveryKey);
      state = const VaultSessionState(status: VaultStatus.unlocked);
    } catch (error) {
      state = VaultSessionState(
        status: state.status,
        error: describeVaultError(error),
      );
      rethrow;
    }
  }

  /// Lock now and wipe the Rust session.
  void lock() {
    try {
      ref.read(vaultRepositoryProvider).lock();
    } finally {
      state = VaultSessionState(status: _lockedStatus());
    }
  }

  /// Change the master password.
  Future<void> changeMaster({
    required String oldMaster,
    required String newMaster,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref
          .read(vaultRepositoryProvider)
          .changeMaster(oldMaster: oldMaster, newMaster: newMaster);
      state = state.copyWith(busy: false);
    } catch (error) {
      state = VaultSessionState(
        status: state.status,
        error: describeVaultError(error),
      );
      rethrow;
    }
  }
}

/// Turn a bridge error into a short, non-sensitive message.
String describeVaultError(Object error) {
  if (error is VaultApiError) {
    return switch (error) {
      VaultApiError.notInitialized => 'Vault storage is not initialized.',
      VaultApiError.invalidPath => 'The vault path is invalid.',
      VaultApiError.vaultMissing => 'No vault file was found.',
      VaultApiError.vaultExists => 'A vault already exists.',
      VaultApiError.locked => 'Unlock the vault first.',
      VaultApiError.wrongPassword => 'Wrong password or damaged vault.',
      VaultApiError.corrupted => 'The vault file is damaged.',
      VaultApiError.unsupportedVersion =>
        'This vault was created by a newer Keyel version.',
      VaultApiError.invalidKdfParams => 'Invalid key-derivation parameters.',
      VaultApiError.invalidRecoveryKey => 'That recovery key is not valid.',
      VaultApiError.notFound => 'Entry not found.',
      VaultApiError.invalidId => 'Invalid entry id.',
      VaultApiError.invalidField => 'Please fill in the required fields.',
      VaultApiError.storage => 'Could not read or write the vault file.',
      VaultApiError.internal => 'Internal error.',
    };
  }
  return error.toString();
}
