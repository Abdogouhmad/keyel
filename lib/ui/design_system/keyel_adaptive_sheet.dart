import 'package:flutter/material.dart';

import 'package:keyel/ui/adaptive/window.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Presents the widget [builder] returns as a bottom sheet on compact
/// windows and as a right-hand side sheet on medium and wider windows.
///
/// Returns a future that resolves with the sheet's dismissal payload.
Future<T?> showKeyelAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    switch (WindowSizeClass.of(context)) {
      WindowSizeClass.compact => _showBottom<T>(context, builder),
      _ => _showSide<T>(context, builder),
    };

Future<T?> _showBottom<T>(
  BuildContext context,
  WidgetBuilder builder,
) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: 0.4),
  builder: (sheetContext) => _SheetSurface(child: builder(sheetContext)),
);

Future<T?> _showSide<T>(
  BuildContext context,
  WidgetBuilder builder,
) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Sheet',
  barrierColor: Colors.black.withValues(alpha: 0.4),
  pageBuilder: (dialogContext, _, _) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: _SheetSurface(
        side: true,
        child: SizedBox(
          width: 400,
          child: builder(dialogContext),
        ),
      ),
    );
  },
  transitionBuilder: (context, animation, _, child) {
    final offset = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    return SlideTransition(position: offset, child: child);
  },
);

/// Shared surface styling for both sheet orientations.
class _SheetSurface extends StatelessWidget {
  const new({required this.child, this.side = false});

  final Widget child;
  final bool side;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final radius = side
        ? const BorderRadius.horizontal(left: Radius.circular(KeyelRadii.card))
        : const BorderRadius.vertical(top: Radius.circular(KeyelRadii.sheet));

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}
