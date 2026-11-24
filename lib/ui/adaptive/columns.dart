import 'package:flutter/material.dart';

import 'package:keyel/ui/adaptive/content.dart';
import 'package:keyel/ui/adaptive/window.dart';

/// Lays out two groups of cards side by side when the effective content width
/// allows it, and stacks them into one scrollable column otherwise.
///
/// Callers keep their existing card widgets; this primitive only decides the
/// composition. Columns scroll independently on wide screens so a long audit
/// list cannot push unrelated settings off-screen, and each column keeps the
/// caller's page padding. When text is scaled up, two-column mode is false
/// and both groups return to a single, comfortably wide column.
class KeyelResponsiveColumns extends StatelessWidget {
  /// Creates a two-column-aware body.
  const new({
    required this.leading,
    required this.trailing,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Cards shown in the first (reading start) column.
  final List<Widget> leading;

  /// Cards shown in the second (reading end) column.
  final List<Widget> trailing;

  /// Padding applied to each column.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (!context.supportsTwoColumns) {
      return ListView(padding: padding, children: [...leading, ...trailing]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(padding: padding, children: leading),
        ),
        SizedBox(width: context.contentGap),
        Expanded(
          child: ListView(padding: padding, children: trailing),
        ),
      ],
    );
  }
}
