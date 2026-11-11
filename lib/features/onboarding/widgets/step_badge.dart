import 'package:flutter/material.dart';

/// A circular badge with a subtle gradient and shadow.
///
/// Anchors the centered welcome and finish frames of onboarding.
class OnboardingStepBadge extends StatelessWidget {
  /// Creates the badge.
  const new({required this.icon, required this.color, super.key});

  /// Glyph shown inside the badge.
  final IconData icon;

  /// Tint used for the gradient, border and glyph.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 32,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(icon, size: 48, color: color),
      ),
    );
  }
}
