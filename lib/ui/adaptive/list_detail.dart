import 'package:flutter/material.dart';

import 'package:keyel/ui/adaptive/hinge.dart';
import 'package:keyel/ui/adaptive/window.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Navigation chrome: shows the list pane alone on compact and medium
/// windows (details navigate via routes), and the list and detail panes
/// side by side on expanded and large windows.
///
/// On a foldable with a usable hinge the panes are split around the hinge
/// so no content is hidden in the fold (docs/design.md §Adaptive).
class KeyelListDetail extends StatelessWidget {
  /// Creates a list-detail layout.
  const new({
    required this.listPane,
    required this.detailPaneBuilder,
    super.key,
  });

  /// The first/bottom level: the master list. Always visible.
  final Widget listPane;

  /// Builds the detail pane from the currently selected item.
  ///
  /// Returning `null` (no selection yet) shows [KeyelEmptyDetail].
  final Widget? Function(BuildContext context) detailPaneBuilder;

  @override
  Widget build(BuildContext context) {
    final windowClass = WindowSizeClass.of(context);

    // Compact and medium keep the single-pane push-navigation layout.
    if (!windowClass.supportsListDetail) {
      return listPane;
    }

    final hinge = KeyelFold.of(context);
    final detail = detailPaneBuilder(context) ?? const KeyelEmptyDetail();

    if (hinge == null) {
      return _Panes(listPane: listPane, detail: detail, barrierWidth: 0);
    }

    // Split the panes around the hinge so nothing lands in the fold.
    return _Panes(
      listPane: listPane,
      detail: detail,
      barrierWidth: hinge.barrierWidth,
    );
  }
}

/// Two panes with an optional hinge barrier between them.
class _Panes extends StatelessWidget {
  const new({
    required this.listPane,
    required this.detail,
    required this.barrierWidth,
  });

  final Widget listPane;
  final Widget detail;
  final double barrierWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: listPane),
        SizedBox(width: barrierWidth),
        Expanded(flex: 3, child: detail),
      ],
    );
  }
}

/// Placeholder shown in the detail pane until an item is selected.
class KeyelEmptyDetail extends StatelessWidget {
  /// Creates the placeholder pane.
  const new({this.label = 'Select an item to see details', super.key});

  /// Message under the glyph.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 40,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
