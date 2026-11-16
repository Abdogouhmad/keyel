import 'package:flutter/material.dart';

import 'package:keyel/ui/adaptive/window.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Standard maximum widths for a screen's centered content column.
///
/// Phones fill the window, but tablets and desktop windows would otherwise
/// stretch a single column of text and controls across the whole display.
/// Capping the column keeps line lengths readable and the layout calm
/// (docs/design.md §Layout).
abstract final class KeyelContentWidth {
  /// Focused, single-column tasks: onboarding, unlock, the generator and the
  /// entry editor on narrow windows.
  static const double form = 560;

  /// Reading-heavy pages: settings, the security dashboard, list pages and
  /// the entry detail body.
  static const double reading = 720;

  /// Wide, multi-column pages such as the two-column entry editor.
  static const double page = 1000;
}

/// Centers [child] and caps its width so content stays comfortable on
/// tablets and desktop windows.
///
/// On a compact phone the cap is wider than the window, so the widget is a
/// no-op there; it only starts to bite once the window is wider than
/// [maxWidth].
class KeyelContent extends StatelessWidget {
  /// Creates a width-capped content column.
  const new({
    required this.child,
    this.maxWidth = KeyelContentWidth.reading,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  /// The content to center and constrain.
  final Widget child;

  /// Maximum width of the content column, in dp.
  final double maxWidth;

  /// How the column is aligned when the window is wider than [maxWidth].
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive spacing derived from the window size class.
///
/// The base scale lives in [KeyelSpacing]; these getters add the one
/// window-dependent step the layout needs: page margins and card gaps grow
/// from phone to tablet to desktop (docs/design.md §spacing).
extension KeyelWindowSpacing on WindowSizeClass {
  /// Horizontal page margin: 16 dp on phones, 24 dp on tablets and 32 dp on
  /// large windows.
  double get pageMargin => switch (this) {
    WindowSizeClass.compact => KeyelSpacing.md,
    WindowSizeClass.medium || WindowSizeClass.expanded => KeyelSpacing.lg,
    WindowSizeClass.large => KeyelSpacing.xl,
  };

  /// Gap between sibling cards or columns: 16 dp on phones, 24 dp on larger
  /// windows.
  double get contentGap =>
      this == WindowSizeClass.compact ? KeyelSpacing.md : KeyelSpacing.lg;
}

/// Convenience access to the responsive spacing above.
extension KeyelWindowSpacingContext on BuildContext {
  /// Horizontal page margin for the current window.
  double get pageMargin => windowSize.pageMargin;

  /// Gap between sibling cards or columns for the current window.
  double get contentGap => windowSize.contentGap;
}
