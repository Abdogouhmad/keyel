import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/breach/breach_service.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/error.dart';
import 'package:keyel/src/rust/api/models.dart';

/// Lifecycle of one manual breach check.
enum BreachCheckStatus {
  /// No check has been run in this session.
  idle,

  /// Prefixes are being fetched and compared.
  running,

  /// A secret-free report is available.
  done,

  /// The check failed; no result is available.
  failed,
}

/// Immutable snapshot of the breach-check UI state.
class BreachCheckState {
  /// Creates a state snapshot.
  const new({this.status = BreachCheckStatus.idle, this.report, this.error});

  /// Current lifecycle state.
  final BreachCheckStatus status;

  /// Last report, containing entry titles and counts only.
  final BreachReportDto? report;

  /// User-facing error, already formatted and non-sensitive.
  final String? error;
}

/// Injectable HTTPS client for range requests.
final breachServiceProvider = Provider<BreachService>((ref) => BreachService());

/// Explicit, revocable opt-in. Never inferred from a previous check.
final breachOptInProvider = NotifierProvider<BreachOptInNotifier, bool>(
  BreachOptInNotifier.new,
);

/// State and actions for the manual check.
final breachCheckProvider =
    NotifierProvider<BreachCheckNotifier, BreachCheckState>(
      BreachCheckNotifier.new,
    );

/// Persists only the non-secret opt-in flag in `settings.json`.
class BreachOptInNotifier extends Notifier<bool> {
  @override
  bool build() => AppPreferences.instance.breachCheckEnabled;

  /// Enable or disable checks. Disabling also cancels any in-flight check.
  Future<void> set(bool enabled) async {
    AppPreferences.instance.breachCheckEnabled = enabled;
    // Update the UI first: settings.json is best-effort and disk I/O must not
    // delay the user's explicit choice.
    state = enabled;
    if (!enabled) ref.read(breachCheckProvider.notifier).cancel();
    try {
      await AppPreferences.instance.save();
    } on Object catch (_) {
      // Preferences are optional; the in-memory choice still applies.
    }
  }
}

/// Runs a two-phase check: Rust hashes, Dart fetches, Rust compares.
class BreachCheckNotifier extends Notifier<BreachCheckState> {
  /// Incremented whenever a check is reset, so an older async run can notice
  /// that the user disabled opt-in or the vault locked while it was fetching.
  int _generation = 0;

  @override
  BreachCheckState build() => const BreachCheckState();

  /// Reset to the idle state without touching Rust.
  void reset() {
    _generation++;
    state = const BreachCheckState();
  }

  /// Discard an in-flight check and reset the UI.
  void cancel() {
    _discardPending();
    reset();
  }

  /// Start a check. Refuses to run unless unlocked and explicitly opted in.
  Future<void> run() async {
    if (state.status == BreachCheckStatus.running) return;
    final optedIn = ref.read(breachOptInProvider);
    final status = ref.read(vaultSessionProvider).status;
    if (!optedIn || status != VaultStatus.unlocked) {
      reset();
      return;
    }

    final generation = ++_generation;
    state = const BreachCheckState(status: BreachCheckStatus.running);
    try {
      final repository = ref.read(vaultRepositoryProvider);
      final request = await repository.beginBreachCheck();
      if (!_stillValid(generation)) {
        _abort();
        return;
      }
      final service = ref.read(breachServiceProvider);
      final responses = <BreachRangeResponseDto>[];
      for (final prefix in request.prefixes) {
        final body = await service.fetchRange(prefix);
        if (!_stillValid(generation)) {
          _abort();
          return;
        }
        responses.add(BreachRangeResponseDto(prefix: prefix, body: body));
      }
      final report = await repository.finishBreachCheck(
        token: request.token,
        responses: responses,
      );
      // finishBreachCheck already wiped the pending digests, even here.
      if (!_stillValid(generation)) {
        reset();
        return;
      }
      state = BreachCheckState(status: BreachCheckStatus.done, report: report);
    } on Object catch (error) {
      _discardPending();
      if (!_stillValid(generation)) {
        // The row may have been disposed, so no lock listener will reset us.
        reset();
        return;
      }
      state = BreachCheckState(
        status: BreachCheckStatus.failed,
        error: switch (error) {
          VaultApiError() => describeVaultError(error),
          ArgumentError() ||
          HttpException() => 'Could not reach the breach service.',
          _ => 'Breach check failed. Please try again.',
        },
      );
    }
  }

  bool _stillValid(int generation) =>
      generation == _generation &&
      ref.read(breachOptInProvider) &&
      ref.read(vaultSessionProvider).status == VaultStatus.unlocked;

  /// Discard an in-flight check and return to idle without showing a result.
  void _abort() {
    _discardPending();
    reset();
  }

  void _discardPending() {
    try {
      ref.read(vaultRepositoryProvider).cancelBreachCheck();
    } on Object catch (_) {
      // Rust also wipes pending state on lock and on the next begin(), so a
      // cleanup failure here must never mask the original UI error.
    }
  }
}
