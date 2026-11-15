import 'dart:math' as math;

/// Exponential backoff for repeated failed master-password attempts.
///
/// Keyel never wipes the vault after failed attempts: a destructive response
/// punishes the legitimate owner and rewards a thief who wants deniability.
/// Instead the next attempt is delayed, growing after the first few free tries
/// and capped so a user who mistypes is never locked out for long. Argon2id is
/// still the real cost per guess; this is an online speed bump only.
///
/// See `docs/threat-model.md` (T9) and `docs/hardening-checklist.md`.
class UnlockThrottle {
  /// Creates a throttle with the default policy: three free attempts, then
  /// 1s, 2s, 4s, ... capped at [maxDelay].
  new({this.freeAttempts = 3, this.maxDelay = const Duration(seconds: 30)})
    : assert(freeAttempts >= 0, 'freeAttempts must not be negative');

  /// Consecutive failures allowed before any delay is imposed.
  final int freeAttempts;

  /// Upper bound on the delay between attempts.
  final Duration maxDelay;

  int _failures = 0;
  DateTime? _lockedUntil;

  /// Consecutive failures recorded since the last success.
  int get failures => _failures;

  /// Wall-clock time before which attempts are refused, or `null`.
  DateTime? get lockedUntil => _lockedUntil;

  /// The delay imposed after [failures] consecutive failures.
  ///
  /// Exposed for tests and for a UI that wants to preview the schedule.
  Duration delayFor(int failures) {
    if (failures <= freeAttempts) return Duration.zero;
    final exponent = failures - freeAttempts - 1;
    // 2^exponent seconds, clamped so the shift can never overflow and the
    // delay never exceeds `maxDelay`.
    final seconds = exponent >= 32
        ? maxDelay.inSeconds
        : math.min(1 << exponent, maxDelay.inSeconds);
    return Duration(seconds: seconds);
  }

  /// How long the caller must still wait before the next attempt at [now].
  Duration remaining(DateTime now) {
    final until = _lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Whether an attempt is currently blocked at [now].
  bool isLocked(DateTime now) => remaining(now) > Duration.zero;

  /// Record a failed attempt and return the new lockout deadline, or `null`
  /// when the attempt was still within the free allowance.
  DateTime? recordFailure(DateTime now) {
    _failures += 1;
    final delay = delayFor(_failures);
    return _lockedUntil = delay == Duration.zero ? null : now.add(delay);
  }

  /// Clear the throttle after a successful unlock.
  void recordSuccess() {
    _failures = 0;
    _lockedUntil = null;
  }

  /// Restore persisted state at startup. A negative [failures] is clamped to
  /// zero; a deadline in the past simply imposes no delay.
  void restore({required int failures, DateTime? lockedUntil}) {
    _failures = failures < 0 ? 0 : failures;
    _lockedUntil = lockedUntil;
  }
}

/// Thrown when an unlock attempt is refused because of the backoff delay.
class UnlockThrottledException implements Exception {
  /// Creates the exception carrying the time left before the next attempt.
  const new(this.remaining);

  /// How long the user must wait before trying again.
  final Duration remaining;

  @override
  String toString() =>
      'UnlockThrottledException(${remaining.inSeconds}s remaining)';
}
