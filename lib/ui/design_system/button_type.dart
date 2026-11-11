import 'package:flutter/material.dart';
import 'package:keyel/ui/design_system/keyel_button.dart' show KeyelButtonM3;
import 'package:keyel/ui/keyel.dart';

/// The visual variants a [KeyelButtonM3] can take.
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
/// Sizes are expressed through `sp`/`w`/`h` so they scale with the user's font
/// and display settings instead of being pinned to physical pixels.
class AppButtonMetrics {
  /// new construction
  const new(this.size);

  /// button size
  final ButtonSize size;

  /// The label's font size.
  double fontSize(BuildContext context) => switch (size) {
    ButtonSize.small => context.sp(13),
    ButtonSize.medium => context.sp(15),
    ButtonSize.large => context.sp(17),
    ButtonSize.extended => context.sp(15),
  };

  /// The padding around the label.
  EdgeInsets padding(BuildContext context) => switch (size) {
    ButtonSize.small => EdgeInsets.symmetric(
      horizontal: context.w(12),
      vertical: context.h(8),
    ),
    ButtonSize.medium => EdgeInsets.symmetric(
      horizontal: context.w(20),
      vertical: context.h(12),
    ),
    ButtonSize.large => EdgeInsets.symmetric(
      horizontal: context.w(28),
      vertical: context.h(16),
    ),
    ButtonSize.extended => EdgeInsets.symmetric(
      horizontal: context.w(20),
      vertical: context.h(12),
    ),
  };

  /// The icon's edge length.
  double iconSize(BuildContext context) => switch (size) {
    ButtonSize.small => context.w(16),
    ButtonSize.medium => context.w(20),
    ButtonSize.large => context.w(24),
    ButtonSize.extended => context.w(24),
  };

  /// The loading spinner's edge length.
  double spinnerSize(BuildContext context) => switch (size) {
    ButtonSize.small => context.w(14),
    ButtonSize.medium => context.w(18),
    ButtonSize.large => context.w(22),
    ButtonSize.extended => context.w(18),
  };
}
