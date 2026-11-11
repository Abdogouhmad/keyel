import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';

/// A clean report used before the vault is open and in tests.
const emptyHealthReport = HealthReportDto(
  score: 100,
  totalLogins: 0,
  weak: [],
  reused: [],
  old: [],
  noTwoFactor: [],
  insecureUrl: [],
);

/// Vault health analysis from the unlocked vault.
///
/// Screens invalidate this provider after an entry is edited. It resolves to a
/// clean report instead of throwing when the vault is not open, which keeps
/// the dashboard renderable while a lock is in flight.
final healthProvider = FutureProvider<HealthReportDto>((ref) {
  if (ref.watch(vaultSessionProvider).status != VaultStatus.unlocked) {
    return Future.value(emptyHealthReport);
  }
  return ref.watch(vaultRepositoryProvider).analyzeHealth();
});
