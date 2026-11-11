import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/button_type.dart';

/// Everything a button variant needs in order to render itself.
///
/// One immutable bundle, so a variant's signature stays a single parameter and
/// the variants cannot drift apart in what they are told: the colours, the
/// metrics and the loading state are resolved once, by AppButton, and every
/// variant then decides only the *shape* of the control.
class AppButtonSpec {
  /// new construction for the button specs
  const new({
    required this.context,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.metrics,
    required this.accent,
    required this.fill,
    required this.onFill,
    required this.iconColor,
    required this.isLoading,
    required this.isFullWidth,
    required this.tooltip,
  });

  /// The build context the button is being rendered in.
  final BuildContext context;

  /// The button's text. Null for the icon-only variant.
  final String? label;

  /// The button's leading icon. Null when the variant has none.
  final IconData? icon;

  /// The callback, already disabled while loading.
  final VoidCallback? onPressed;

  /// The size preset's measurements.
  final AppButtonMetrics metrics;

  /// The colour of the label and the icon outline.
  final Color accent;

  /// The colour of the filled surface.
  final Color fill;

  /// The colour of the content drawn on top of [fill].
  final Color onFill;

  /// The colour of a standalone icon.
  final Color iconColor;

  /// loading
  final bool isLoading;

  /// is full width button default false
  final bool isFullWidth;

  /// tool tip
  final String? tooltip;

  /// The loading spinner, sized to the preset.
  Widget spinner(Color color) => SizedBox(
    width: metrics.spinnerSize(context),
    height: metrics.spinnerSize(context),
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );

  /// The label's text style, sized to the preset.
  TextStyle labelStyle({FontWeight weight = FontWeight.w600}) =>
      TextStyle(fontSize: metrics.fontSize(context), fontWeight: weight);

  /// The minimum size: full-width buttons stretch, the rest size to content.
  Size? get minimumSize => isFullWidth ? const Size(double.infinity, 0) : null;
}
