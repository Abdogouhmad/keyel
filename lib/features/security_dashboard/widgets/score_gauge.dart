import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Circular health gauge showing the vault score out of 100.
class ScoreGauge extends StatelessWidget {
  /// Creates a score gauge.
  const new({
    required this.score,
    required this.accent,
    required this.track,
    this.statusLabel = 'SECURE',
    super.key,
  });

  /// Vault health score from 0 to 100.
  final int score;

  /// Color used for the filled arc and the score text.
  final Color accent;

  /// Color of the unfilled remaining arc.
  final Color track;

  /// Short uppercase status word under the score.
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          CustomPaint(
            size: const Size.square(160),
            painter: _GaugePainter(
              progress: score / 100,
              accent: accent,
              track: track,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: KeyelTheme.mono(
                        context,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: KeyelSpacing.xs),
                    Text(
                      '/ 100',
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 15, color: accent),
                  const SizedBox(width: KeyelSpacing.xs),
                  Text(
                    statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws the gauge arc behind the gauge labels.
class _GaugePainter extends CustomPainter {
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
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawArc(rect, 0, 2 * math.pi, false, trackPaint)
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        accentPaint,
      );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}
