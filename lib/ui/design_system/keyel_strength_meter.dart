import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_colors.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// The expressive wavy entropy meter used by the generator and entry editor.
class KeyelStrengthMeter extends StatelessWidget {
  /// Creates an entropy meter.
  const new({required this.strength, this.showHint = true, super.key});

  /// Estimate to visualise.
  final PasswordStrength strength;

  /// Whether to show the guidance line below the wave.
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    final (accent, container, onContainer, icon) = switch (strength.level) {
      PasswordStrengthLevel.strong => (
        scheme.strong,
        scheme.strongContainer,
        scheme.onStrongContainer,
        Icons.verified_rounded,
      ),
      PasswordStrengthLevel.fair => (
        scheme.fair,
        scheme.fairContainer,
        scheme.onFairContainer,
        Icons.balance_rounded,
      ),
      PasswordStrengthLevel.weak => (
        scheme.weak,
        scheme.weakContainer,
        scheme.onWeakContainer,
        Icons.warning_amber_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: KeyelSpacing.xs + 2),
              Expanded(
                child: Text(
                  l10n.entryStrengthSummary(
                    strength.label,
                    strength.bits,
                    strength.descriptor,
                  ),
                  style: textTheme.titleSmall?.copyWith(
                    color: onContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Flexible(
                child: Text(
                  l10n.entryStrengthEntropy(strength.entropyLabel),
                  textAlign: TextAlign.end,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Container(
            height: 12,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(KeyelRadii.pill),
            ),
            child: CustomPaint(
              painter: _WaveMeterPainter(
                progress: strength.score,
                accent: accent,
                track: scheme.outlineVariant,
              ),
            ),
          ),
          if (showHint) ...[
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              strength.hint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaveMeterPainter extends CustomPainter {
  const new({
    required this.progress,
    required this.accent,
    required this.track,
  });

  final double progress;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final mid = size.height / 2;
    const wavelength = 28.0;
    const halfWave = wavelength / 2;
    const amplitude = 2.6;

    final wave = Path()..moveTo(0, mid);
    for (double x = 0; x < size.width; x += wavelength) {
      wave
        ..relativeQuadraticBezierTo(halfWave * 0.5, -amplitude * 2, halfWave, 0)
        ..relativeQuadraticBezierTo(halfWave * 0.5, amplitude * 2, halfWave, 0);
    }

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(wave, trackPaint);

    if (progress <= 0) return;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height))
      ..drawPath(wave, accentPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_WaveMeterPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}
