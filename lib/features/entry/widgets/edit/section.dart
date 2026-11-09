import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Rounded container wrapping editor form sections.
class EditSection extends StatelessWidget {
  /// Creates a section wrapper.
  const new({required this.child, super.key});

  /// Section content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: child,
    );
  }
}
