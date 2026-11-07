import 'package:flutter/material.dart';

import 'package:keyel/ui/theme/keyel_theme.dart';

/// Tonal flavours for [KeyelPillButton].
enum KeyelButtonTone {
  /// Filled primary CTA.
  primary,

  /// Secondary-container tonal action.
  tonal,

  /// Quiet surface-container action.
  neutral,

  /// Expressive `primary-fixed` action (the extended FAB).
  soft,
}

/// The standard 56 dp full-pill action from the Keyel design system.
class KeyelPillButton extends StatelessWidget {
  /// Creates a pill button.
  const new({
    required this.label,
    this.onPressed,
    this.icon,
    this.tone = KeyelButtonTone.primary,
    this.height = 56,
    this.expand = true,
    this.trailing,
    super.key,
  });

  /// Button copy.
  final String label;

  /// Tap handler.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Colour flavour.
  final KeyelButtonTone tone;

  /// Visual height (56 dp by default, 40 dp for compact header actions).
  final double height;

  /// Whether the button fills its available width.
  final bool expand;

  /// Optional trailing widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (background, foreground) = switch (tone) {
      KeyelButtonTone.primary => (scheme.primary, scheme.onPrimary),
      KeyelButtonTone.tonal => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      KeyelButtonTone.neutral => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
      ),
      KeyelButtonTone.soft => (scheme.primaryFixed, scheme.onPrimaryFixed),
    };

    final button = SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          minimumSize: Size(64, height),
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: KeyelTheme.pillRadius,
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            color: foreground,
            fontFamily: KeyelTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: height >= 48 ? 22 : 18),
              const SizedBox(width: KeyelSpacing.sm),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) ...[
              const SizedBox(width: KeyelSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );

    return button;
  }
}

/// A circular icon hull with a 48 dp minimum hit target and a 40 dp visual.
class KeyelIconHull extends StatelessWidget {
  /// Creates a circular icon action.
  const new({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.background,
    this.foreground,
    this.size = 48,
    this.iconSize = 22,
    super.key,
  });

  /// Glyph to show.
  final IconData icon;

  /// Accessibility / long-press label.
  final String tooltip;

  /// Tap handler.
  final VoidCallback? onPressed;

  /// Optional visual hull colour.
  final Color? background;

  /// Optional icon colour.
  final Color? foreground;

  /// Hit-target size.
  final double size;

  /// Glyph size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = background ?? Colors.transparent;
    final fg = foreground ?? scheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );
  }
}
