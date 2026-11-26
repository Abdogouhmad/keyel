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

/// Width of a focused, single-column task at the current text scale.
///
/// Text scaling enlarges glyphs but not layout dp, so a fixed 560 dp column at
/// 200 % would only fit ~280 dp of 1x text. Growing the cap with the scaler
/// keeps line lengths readable; the physical window still wins on phones.
double focusedContentWidthOf(BuildContext context) =>
    KeyelContentWidth.form *
    MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

/// Shared body for short, focused screens such as onboarding and unlock.
///
/// The cap and the centering both live *inside* the vertical scroll view.
/// Putting `Center` outside a vertical `SingleChildScrollView` is a no-op on
/// desktop: the scroll view passes tight width constraints and paints its
/// child at the leading edge. This body also mirrors both page margins for RTL
/// and gives short steps enough height to center without clipping tall ones.
class KeyelFocusedBody extends StatelessWidget {
  /// Creates a scrollable, width-capped focused body.
  const new({required this.child, this.center = true, super.key});

  /// Key of the capped content column, so layout tests can measure it.
  static const contentKey = Key('keyel-focused-content');

  /// The form content.
  final Widget child;

  /// Whether short content is centered vertically as well as horizontally.
  ///
  /// Welcome and finish steps opt in; longer form steps stay top-aligned so
  /// their first field remains near the top of the window.
  final bool center;

  @override
  Widget build(BuildContext context) {
    const verticalPadding = KeyelSpacing.xl;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - (verticalPadding * 2)).clamp(
                  0.0,
                  constraints.maxHeight,
                )
              : 0.0;

          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.pageMargin,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Align(
                  alignment: center ? Alignment.center : Alignment.topCenter,
                  child: ConstrainedBox(
                    key: contentKey,
                    constraints: BoxConstraints(
                      maxWidth: focusedContentWidthOf(context),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
