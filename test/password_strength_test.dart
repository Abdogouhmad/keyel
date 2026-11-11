import 'package:flutter_test/flutter_test.dart';
import 'package:keyel/core/security/password_strength.dart';

void main() {
  group('PasswordStrength.estimatePassphrase', () {
    test('uses ten bits per word for the 1024-word list', () {
      // 8 words x 10 bits = 80 bits, the strong threshold.
      final eight = PasswordStrength.estimatePassphrase(8);
      expect(eight.bits, 80);
      expect(eight.level, PasswordStrengthLevel.strong);

      // 4 words x 10 bits = 40 bits, still weak.
      final four = PasswordStrength.estimatePassphrase(4);
      expect(four.bits, 40);
      expect(four.level, PasswordStrengthLevel.weak);
    });

    test('zero or negative words are empty', () {
      expect(PasswordStrength.estimatePassphrase(0).bits, 0);
      expect(PasswordStrength.estimatePassphrase(-3).bits, 0);
    });
  });

  group('PasswordStrength.estimate', () {
    test('a longer mixed password scores higher than a short one', () {
      final weak = PasswordStrength.estimate('abc');
      final strong = PasswordStrength.estimate('Tr0ub4dour&3xtra-Long!');
      expect(strong.bits, greaterThan(weak.bits));
      expect(strong.isStrong, isTrue);
    });
  });
}
