import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/keyel_buttons.dart';
import 'package:keyel/ui/theme/keyel_colors.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A live TOTP token with a circular countdown ring.
///
/// The code itself is supplied by the caller — the vault will compute it from
/// the stored seed in a later phase. The ring runs against the real clock so
/// it rolls over exactly on the 30-second boundary.
class KeyelTotpDisplay extends StatefulWidget {
  /// Creates a TOTP token.
  const new({
    required this.code,
    required this.onCopy,
    this.period = 30,
    super.key,
  });

  /// Numeric TOTP code, usually six digits.
  final String code;

  /// Copy handler.
  final VoidCallback onCopy;

  /// Token lifetime in seconds.
  final int period;

  @override
  State<KeyelTotpDisplay> createState() => _KeyelTotpDisplayState();
}

class _KeyelTotpDisplayState extends State<KeyelTotpDisplay> {
  Timer? _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _secondsRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _secondsRemaining());
    });
  }

  int _secondsRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now % widget.period;
    return widget.period - elapsed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final urgent = _remaining <= 5;
    final accent = urgent ? scheme.weak : scheme.primary;

    final half = widget.code.length ~/ 2;
    final leading = widget.code.substring(0, half);
    final trailing = widget.code.substring(half);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    leading,
                    style: KeyelTheme.mono(
                      context,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeyelSpacing.sm,
                    ),
                    child: Text(
                      '•',
                      style: textTheme.headlineMedium?.copyWith(
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
                  Text(
                    trailing,
                    style: KeyelTheme.mono(
                      context,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Refreshes automatically',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KeyelSpacing.sm),
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(52),
                painter: _RingPainter(
                  progress: _remaining / widget.period,
                  accent: accent,
                  track: scheme.surfaceContainerHighest,
                ),
              ),
              Text(
                '${_remaining}s',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontFamily: KeyelTheme.monoFamily,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KeyelSpacing.sm),
        KeyelIconHull(
          icon: Icons.content_copy_rounded,
          tooltip: 'Copy 2FA code',
          onPressed: widget.onCopy,
          background: scheme.primary,
          foreground: scheme.onPrimary,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
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
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawCircle(center, radius, trackPaint)
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        accentPaint,
      );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}
