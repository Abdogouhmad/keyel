import 'package:flutter/material.dart';

import 'package:keyel/ui/adaptive/window.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Presents the widget [builder] returns as a bottom sheet on phones and as a
/// direction-correct side sheet on tablet and desktop windows.
///
/// The side sheet is anchored to the *end* edge, so it slides in from the
/// right in LTR and from the left in RTL. Its rounded corners always face the
/// content it overlays. Returns a future that resolves with the dismissal
/// payload.
Future<T?> showKeyelAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => switch (WindowSizeClass.of(context)) {
  WindowSizeClass.compact => _showBottom<T>(context, builder),
  _ => _showSide<T>(context, builder),
};

Future<T?> _showBottom<T>(BuildContext context, WidgetBuilder builder) {
  // Routes are built under the navigator's Directionality, which can differ
  // from the caller's. Carry the caller's direction into the sheet so its
  // content mirrors correctly in RTL.
  final direction = Directionality.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (sheetContext) => Directionality(
      textDirection: direction,
      child: _SheetSurface(child: Builder(builder: builder)),
    ),
  );
}

Future<T?> _showSide<T>(BuildContext context, WidgetBuilder builder) {
  // A side sheet must never cover the whole content area: cap it at 480 dp and
  // at 90 % of the space the caller can actually see (nav chrome included).
  final available = effectiveWidthOf(context);
  final width = (available * 0.9).clamp(320.0, 480.0);

  // Capture the caller's direction once: the dialog route's own context is
  // built under the navigator, which may still be LTR in a mirrored layout.
  final direction = Directionality.of(context);
  final rtl = direction == TextDirection.rtl;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10nOf(context).entrySheetBarrier,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    pageBuilder: (dialogContext, _, _) => Directionality(
      textDirection: direction,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _SheetSurface(
          side: true,
          rtl: rtl,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
            ),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
    transitionBuilder: (transitionContext, animation, _, child) {
      final offset = Tween<Offset>(
        begin: Offset(rtl ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return SlideTransition(position: offset, child: child);
    },
  );
}

/// Shared surface styling for both sheet orientations.
class _SheetSurface extends StatelessWidget {
  const new({required this.child, this.side = false, this.rtl = false});

  final Widget child;
  final bool side;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // The side sheet sits at the end edge. Its rounded corners face the
    // content: physical left in LTR, physical right in RTL.
    final radius = side
        ? BorderRadius.horizontal(
            left: rtl ? Radius.zero : const Radius.circular(KeyelRadii.card),
            right: rtl ? const Radius.circular(KeyelRadii.card) : Radius.zero,
          )
        : const BorderRadius.vertical(top: Radius.circular(KeyelRadii.sheet));

    return ClipRRect(
      borderRadius: radius,
      child: Container(
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
      ),
    );
  }
}
