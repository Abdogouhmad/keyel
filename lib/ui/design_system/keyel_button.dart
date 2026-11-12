import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/app_button_fab.dart';
import 'package:keyel/ui/design_system/app_button_filled.dart';
import 'package:keyel/ui/design_system/app_button_quiet.dart';
import 'package:keyel/ui/design_system/app_button_spec.dart';
import 'package:keyel/ui/design_system/button_type.dart';

/// The app's one button component (spec §1.3) — every tap target in Keyel
/// flows through this widget so press feedback, corner radius and type scale
/// stay identical app-wide.
class KeyelButtonM3 extends StatelessWidget {
  /// Creates the app button.
  const new({
    required this.onPressed,
    super.key,
    this.label,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.isFullWidth = false,
    this.iconColor,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : assert(
         type == ButtonType.iconOnly || type == ButtonType.fab || label != null,
         'label is required unless type is iconOnly or fab',
       ),
       assert(
         (type != ButtonType.textIcon &&
                 type != ButtonType.iconOnly &&
                 type != ButtonType.fab) ||
             icon != null,
         'icon is required for textIcon, iconOnly, and fab types',
       ),
       assert(
         type != ButtonType.fab || size != ButtonSize.extended || label != null,
         'label is required for extended FAB',
       );

  /// The button label. Required unless [type] is [ButtonType.iconOnly] or
  /// [ButtonType.fab].
  final String? label;

  /// The tap callback.
  final VoidCallback? onPressed;

  /// The visual variant.
  final ButtonType type;

  /// The height/size variant.
  final ButtonSize size;

  /// An optional leading icon.
  final IconData? icon;

  /// Whether to show a spinner instead of the label.
  final bool isLoading;

  /// Whether the action is destructive (uses the error colour role).
  final bool isDestructive;

  /// Whether the button should stretch to fill its parent's width.
  final bool isFullWidth;

  /// An override for the icon colour.
  final Color? iconColor;

  /// An override for the background colour.
  final Color? backgroundColor;

  /// An override for the foreground colour.
  final Color? foregroundColor;

  /// An optional tooltip.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metrics = AppButtonMetrics(size);

    final accent = foregroundColor ?? (isDestructive ? cs.error : cs.primary);
    final fill = backgroundColor ?? (isDestructive ? cs.error : cs.primary);
    final onFill =
        foregroundColor ?? (isDestructive ? cs.onError : cs.onPrimary);

    final spec = AppButtonSpec(
      context: context,
      label: label,
      icon: icon,
      onPressed: isLoading ? null : onPressed,
      metrics: metrics,
      accent: accent,
      fill: fill,
      onFill: onFill,
      iconColor:
          iconColor ??
          foregroundColor ??
          (isDestructive ? cs.error : cs.onSurfaceVariant),
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      tooltip: tooltip,
    );

    final button = switch (type) {
      ButtonType.primary => AppButtonFilled.primary(spec),
      ButtonType.secondary => AppButtonFilled.secondary(spec),
      ButtonType.text => AppButtonQuiet.text(spec),
      ButtonType.textIcon => AppButtonQuiet.textIcon(spec),
      ButtonType.iconOnly => AppButtonQuiet.iconOnly(spec),
      ButtonType.fab => AppButtonFab.build(spec),
    };

    if (!isFullWidth || type == ButtonType.fab) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
