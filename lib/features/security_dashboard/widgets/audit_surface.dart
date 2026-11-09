import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Raised inner surface used for rows inside the vulnerability audit card.
class AuditSurface extends StatelessWidget {
  /// Creates an audit surface wrapping the given [child].
  const new({required this.child, super.key});

  /// The content displayed inside the surface.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.sm + 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
