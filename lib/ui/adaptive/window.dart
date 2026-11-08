import 'package:flutter/widgets.dart';

/// Material window size classes (docs/design.md §7).
enum WindowSizeClass {
  /// Under 600 dp: phones.
  compact,

  /// 600-839 dp: foldables, small tablets.
  medium,

  /// 840-1199 dp: tablets.
  expanded,

  /// 1200 dp and up.
  large;

  /// Maps a width in dp to its class.
  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    if (width < 1200) return expanded;
    return large;
  }

  /// The class for the current window.
  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// Whether this is the phone layout.
  bool get isCompact => this == compact;

  /// Whether two-pane list-detail layouts fit in this window.
  bool get supportsListDetail => this == expanded || this == large;
}

/// Convenience access to the window size class.
extension WindowSizeContext on BuildContext {
  /// The [WindowSizeClass] for the current window.
  WindowSizeClass get windowSize => WindowSizeClass.of(this);
}
