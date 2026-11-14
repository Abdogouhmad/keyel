import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/core/security/unlock_throttle.dart';

void main() {
  final t0 = DateTime(2026, 11, 14, 12);

  group('delay schedule', () {
    test('the first three failures are free', () {
      final throttle = UnlockThrottle();
      for (var i = 1; i <= 3; i++) {
        expect(throttle.delayFor(i), Duration.zero, reason: 'failure $i');
      }
    });

    test('the delay doubles from one second and is capped', () {
      final throttle = UnlockThrottle();
      expect(throttle.delayFor(4), const Duration(seconds: 1));
      expect(throttle.delayFor(5), const Duration(seconds: 2));
      expect(throttle.delayFor(6), const Duration(seconds: 4));
      expect(throttle.delayFor(7), const Duration(seconds: 8));
      expect(throttle.delayFor(8), const Duration(seconds: 16));
      // 32s is clamped to the 30s ceiling and stays there.
      expect(throttle.delayFor(9), const Duration(seconds: 30));
      expect(throttle.delayFor(20), const Duration(seconds: 30));
      expect(throttle.delayFor(1 << 30), const Duration(seconds: 30));
    });

    test('a custom policy is honoured', () {
      final throttle = UnlockThrottle(
        freeAttempts: 0,
        maxDelay: const Duration(seconds: 5),
      );
      expect(throttle.delayFor(1), const Duration(seconds: 1));
      expect(throttle.delayFor(4), const Duration(seconds: 5));
    });
  });

  group('recordFailure', () {
    test('does not lock while within the free allowance', () {
      final throttle = UnlockThrottle();
      for (var i = 0; i < 3; i++) {
        expect(throttle.recordFailure(t0), isNull);
      }
      expect(throttle.failures, 3);
      expect(throttle.isLocked(t0), isFalse);
      expect(throttle.remaining(t0), Duration.zero);
    });

    test('locks for the scheduled delay on the fourth failure', () {
      final throttle = UnlockThrottle();
      for (var i = 0; i < 3; i++) {
        throttle.recordFailure(t0);
      }

      final until = throttle.recordFailure(t0);

      expect(until, t0.add(const Duration(seconds: 1)));
      expect(throttle.failures, 4);
      expect(throttle.isLocked(t0), isTrue);
      expect(throttle.remaining(t0), const Duration(seconds: 1));
    });

    test('remaining shrinks with time and unlocks after the deadline', () {
      final throttle = UnlockThrottle()
        ..restore(failures: 4)
        ..recordFailure(t0);

      expect(throttle.remaining(t0.add(const Duration(seconds: 1))),
          const Duration(seconds: 1));
      expect(
        throttle.isLocked(t0.add(const Duration(seconds: 2))),
        isFalse,
      );
      expect(throttle.remaining(t0.add(const Duration(minutes: 1))),
          Duration.zero);
    });
  });

  group('recordSuccess', () {
    test('clears the failure count and the deadline', () {
      final throttle = UnlockThrottle();
      for (var i = 0; i < 4; i++) {
        throttle.recordFailure(t0);
      }
      expect(throttle.isLocked(t0), isTrue);

      throttle.recordSuccess();

      expect(throttle.failures, 0);
      expect(throttle.lockedUntil, isNull);
      expect(throttle.isLocked(t0), isFalse);
    });
  });

  group('restore', () {
    test('clamps a negative failure count to zero', () {
      final throttle = UnlockThrottle()..restore(failures: -5);
      expect(throttle.failures, 0);
    });

    test('a deadline in the past imposes no delay', () {
      final throttle = UnlockThrottle()
        ..restore(
          failures: 7,
          lockedUntil: t0.subtract(const Duration(minutes: 1)),
        );

      expect(throttle.failures, 7);
      expect(throttle.isLocked(t0), isFalse);
    });

    test('a future deadline keeps the lock and the failure count', () {
      final until = t0.add(const Duration(seconds: 20));
      final throttle = UnlockThrottle()
        ..restore(failures: 8, lockedUntil: until);

      expect(throttle.failures, 8);
      expect(throttle.lockedUntil, until);
      expect(throttle.remaining(t0), const Duration(seconds: 20));
    });
  });
}
