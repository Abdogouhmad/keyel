import 'dart:ui';

import 'package:flutter/widgets.dart';

/// A foldable hinge detected in the current window.
final class KeyelHinge {
  /// Creates a hinge descriptor.
  const new({required this.rectangle, required this.isVertical});

  /// The raw platform-provided hinge bounds, in dp.
  final Rect rectangle;

  /// Whether the hinge splits the screen vertically (a seam running
  /// vertically down the middle, found on most foldable book-styles).
  ///
  /// Split panes are laid out left | hinge | right on a vertical hinge and
  /// top / hinge / bottom on a horizontal one.
  final bool isVertical;

  /// The gap in logical pixels that content must keep clear.
  double get barrierWidth => rectangle.width;

  /// The gap in logical pixels in the cross direction.
  double get barrierHeight => rectangle.height;
}

/// Foldable-window geometry helpers built on `MediaQuery.displayFeatures`.
///
/// Humidity-free rule: only fold *hinges* are treated as physical barriers;
/// cutouts and system-built-in display features are ignored.
abstract final class KeyelFold {
  /// The first usable hinge in the window, or `null` on a flat display.
  ///
  /// Hinges that overlap the content area (ignoring system insets) are
  /// preferred; a hinge is usable when it is tall or wide enough to matter.
  static KeyelHinge? of(BuildContext context) {
    final view = View.of(context);
    final size = MediaQuery.sizeOf(context);
    final features = MediaQuery.displayFeaturesOf(context);
    final window = Offset.zero & size;

    for (final feature in features) {
      if (feature.type != DisplayFeatureType.hinge) continue;

      final rect = _inDp(view, feature.bounds);
      if (!rect.overlaps(window)) continue;

      final isVertical = rect.width <= rect.height;
      // Treat the hinge as a barrier only when it spans the split axis.
      final spans =
          isVertical
              ? rect.height >= size.height * 0.5
              : rect.width >= size.width * 0.5;
      if (!spans) continue;

      return KeyelHinge(rectangle: rect, isVertical: isVertical);
    }
    return null;
  }

  /// Converts a Flutter physical-rect display feature into logical dp.
  static Rect _inDp(FlutterView view, Rect physicalRect) {
    final devicePixelRatio = view.devicePixelRatio;
    final origin = physicalRect.topLeft / devicePixelRatio;
    final dimensions = physicalRect.size / devicePixelRatio;
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      dimensions.width,
      dimensions.height,
    );
  }
}
