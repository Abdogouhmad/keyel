import 'package:keyel/core/wear/wear_totp_bridge.dart';
import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Pushes explicitly chosen TOTP seeds from an unlocked vault to the watch.
///
/// The service never persists a seed, never logs one, and keeps no copy after
/// the send completes. The vault schema is untouched: the watch holds the only
/// copy outside the encrypted vault, and only for entries the user selects.
class WatchTotpService {
  /// Creates a service for [repository] and [bridge].
  const new({required this.repository, this.bridge = wearTotpBridge});

  /// Unlocked vault access used to read the seed.
  final VaultRepository repository;

  /// Transport to the paired watch.
  final WearTotpBridge bridge;

  /// Sends the seed and TOTP parameters for one login entry.
  ///
  /// Returns false when the entry has no TOTP config, the vault is locked, or
  /// no watch can be reached. Nothing is retried in the background.
  Future<bool> pushEntry(String id) async {
    final detail = await repository.getEntry(id);
    final login = detail.login;
    final digits = login?.totpDigits;
    final period = login?.totpPeriod;
    if (login == null || digits == null || period == null) return false;

    final secret = await repository.revealField(
      id,
      SecretFieldDto.loginTotpSecret,
    );
    if (secret.isEmpty) return false;

    // Dart strings are immutable; dropping the local reference after the call
    // is the available best-effort cleanup. The native bridge also clears its
    // byte buffer in a finally block.
    return await bridge.push(
      id: id,
      label: detail.title,
      secret: secret,
      algorithm: (login.totpAlgorithm ?? TotpAlgorithmDto.sha1).name,
      digits: digits,
      period: period,
    );
  }

  /// Removes one seed from the watch without touching the vault.
  Future<bool> removeFromWatch(String id) => bridge.remove(id);

  /// Removes all seeds from the watch without touching the vault.
  Future<bool> clearWatch() => bridge.clear();
}
