import 'dart:math' as math;

/// Qualitative bucket for a password's estimated entropy.
enum PasswordStrengthLevel {
  /// Below 50 bits: trivially guessable.
  weak,

  /// 50–79 bits: acceptable, but worth improving.
  fair,

  /// 80 bits and above: air-tight for a vault credential.
  strong,
}

/// A UI-facing password strength estimate.
///
/// This is deliberately a fast heuristic for the interface only — the vault
/// never stores or transmits the analysed secret. Real zxcvbn-style analysis
/// lands with the storage phase.
class PasswordStrength {
  /// Creates an explicit strength result.
  const new({
    required this.level,
    required this.bits,
    required this.label,
    required this.descriptor,
    required this.hint,
  });

  /// Builds a result from an entropy estimate.
  factory fromBits(double bits) {
    final rounded = bits.round();
    if (bits >= 80) {
      return PasswordStrength(
        level: PasswordStrengthLevel.strong,
        bits: rounded,
        label: 'Strong',
        descriptor: 'Air-tight',
        hint: 'Hard to guess. Keep this one unique to this service.',
      );
    }
    if (bits >= 50) {
      return PasswordStrength(
        level: PasswordStrengthLevel.fair,
        bits: rounded,
        label: 'Fair',
        descriptor: 'Decent',
        hint: 'Add a few more characters to push this into the strong range.',
      );
    }
    return PasswordStrength(
      level: PasswordStrengthLevel.weak,
      bits: rounded,
      label: 'Weak',
      descriptor: 'At risk',
      hint: 'Too short or too predictable. Generate a longer password.',
    );
  }

  /// Estimates the strength of a raw password string.
  factory estimate(String password) {
    if (password.isEmpty) return PasswordStrength.fromBits(0);

    var alphabet = 0;
    if (RegExp('[a-z]').hasMatch(password)) alphabet += 26;
    if (RegExp('[A-Z]').hasMatch(password)) alphabet += 26;
    if (RegExp('[0-9]').hasMatch(password)) alphabet += 10;
    if (RegExp('[^A-Za-z0-9]').hasMatch(password)) alphabet += 33;

    final perCharacter = math.log(alphabet == 0 ? 1 : alphabet) / math.ln2;
    final bits = password.length * perCharacter;
    return PasswordStrength.fromBits(bits);
  }

  /// Estimates the strength of a hyphen-joined passphrase.
  ///
  /// The generator draws uniformly from its built-in 128-word list, so each
  /// word contributes roughly seven bits of entropy.
  factory estimatePassphrase(int words) {
    if (words <= 0) return PasswordStrength.fromBits(0);
    return PasswordStrength.fromBits(words * 7);
  }

  /// Bucket used for colour resolution.
  final PasswordStrengthLevel level;

  /// Estimated entropy in bits.
  final int bits;

  /// Short label such as `Strong`.
  final String label;

  /// Expressive suffix such as `Air-tight`.
  final String descriptor;

  /// Human guidance shown under the meter.
  final String hint;

  /// Progress in the `0..1` range.
  double get score => (bits / 100).clamp(0, 1).toDouble();

  /// Short entropy word for the trailing label.
  String get entropyLabel => switch (level) {
    PasswordStrengthLevel.strong => 'High',
    PasswordStrengthLevel.fair => 'Medium',
    PasswordStrengthLevel.weak => 'Low',
  };

  /// Whether the strength is in the secure bucket.
  bool get isStrong => level == PasswordStrengthLevel.strong;
}
