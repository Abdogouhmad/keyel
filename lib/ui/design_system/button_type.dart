import 'package:flutter/material.dart';

/// The visual variants the app button can take.
enum ButtonType {
  /// Solid filled button for the primary action.
  primary,

  /// Outlined button for a secondary action.
  secondary,

  /// Flat text button.
  text,

  /// Text button with a leading icon.
  textIcon,

  /// Square icon-only button.
  iconOnly,

  /// Floating action button.
  fab,
}

/// The standard button sizes.
enum ButtonSize {
  /// Compact height, used in dense layouts.
  small,

  /// Default height for most touch targets.
  medium,

  /// Prominent height for primary actions.
  large,

  /// Wider FAB shape with an extended touch target.
  extended,
}

/// The measurements of one [ButtonSize] preset.
///
/// Metrics are fixed dp values, not fractions of the window: a 16 dp icon must
/// stay 16 dp on a phone and on a 1600 dp desktop. Only the user's text scale
/// is allowed to grow the touch target, and even that is capped so a button
/// cannot swallow a screen at 200 %. Flutter scales the label itself, so the
/// base font sizes below are deliberately not multiplied by the text scaler.
class AppButtonMetrics {
  /// new construction
  const new(this.size);

  /// button size
  final ButtonSize size;

  /// Modest, bounded response to the accessibility text scale.
  double _scale(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

  /// The label's base font size. Flutter applies the text scaler to [Text].
  double fontSize(BuildContext _) => switch (size) {
    ButtonSize.small => 13,
    ButtonSize.medium => 15,
    ButtonSize.large => 17,
    ButtonSize.extended => 15,
  };

  /// The padding around the label.
  EdgeInsets padding(BuildContext context) {
    final scale = _scale(context);
    return switch (size) {
      ButtonSize.small => EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      ButtonSize.medium => EdgeInsets.symmetric(
        horizontal: 20 * scale,
        vertical: 12 * scale,
      ),
      ButtonSize.large => EdgeInsets.symmetric(
        horizontal: 28 * scale,
        vertical: 16 * scale,
      ),
      ButtonSize.extended => EdgeInsets.symmetric(
        horizontal: 20 * scale,
        vertical: 12 * scale,
      ),
    };
  }

  /// The icon's edge length.
  double iconSize(BuildContext context) => switch (size) {
    ButtonSize.small => 16 * _scale(context),
    ButtonSize.medium => 20 * _scale(context),
    ButtonSize.large => 24 * _scale(context),
    ButtonSize.extended => 24 * _scale(context),
  };

  /// The loading spinner's edge length.
  double spinnerSize(BuildContext context) => switch (size) {
    ButtonSize.small => 14 * _scale(context),
    ButtonSize.medium => 18 * _scale(context),
    ButtonSize.large => 22 * _scale(context),
    ButtonSize.extended => 18 * _scale(context),
  };
}
