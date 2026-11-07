import 'package:flutter/material.dart';

import 'package:keyel/ui/theme/keyel_theme.dart';

/// A borderless tonal card, the base container of the Keyel design system.
class KeyelSectionCard extends StatelessWidget {
  /// Creates a tonal section card.
  const new({
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(KeyelSpacing.md),
    this.color,
    this.radius = KeyelRadii.card,
    this.showBorder = false,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Optional section heading.
  final String? title;

  /// Optional heading glyph.
  final IconData? icon;

  /// Optional trailing widget aligned with the heading.
  final Widget? trailing;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Overrides the default `surface-container-low` chassis.
  final Color? color;

  /// Corner radius.
  final double radius;

  /// Adds the hairline used by detail screens.
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: KeyelSpacing.sm - 2),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: KeyelSpacing.md - 4),
          ],
          child,
        ],
      ),
    );
  }
}

/// A nested key/value block used inside cards (16 dp radius).
class KeyelFieldSurface extends StatelessWidget {
  /// Creates a nested field block.
  const new({
    required this.label,
    required this.child,
    this.trailing,
    this.color,
    this.padding = const EdgeInsets.symmetric(
      horizontal: KeyelSpacing.md,
      vertical: KeyelSpacing.sm + 4,
    ),
    super.key,
  });

  /// Small uppercase label.
  final String label;

  /// Value / editable content.
  final Widget child;

  /// Optional action anchored to the right.
  final Widget? trailing;

  /// Overrides the default `surface-container` fill.
  final Color? color;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: KeyelSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A pill tag used for 2FA, folders and audit status.
class KeyelBadge extends StatelessWidget {
  /// Creates a tonal badge.
  const new({
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.iconSize = 15,
    this.compact = false,
    super.key,
  });

  /// Badge copy.
  final String label;

  /// Optional leading glyph.
  final IconData? icon;

  /// Background override.
  final Color? background;

  /// Foreground override.
  final Color? foreground;

  /// Glyph size.
  final double iconSize;

  /// Denser padding for list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = background ?? scheme.surfaceContainerHigh;
    final fg = foreground ?? scheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KeyelRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 1 dp tonal rule.
class KeyelRule extends StatelessWidget {
  /// Creates a horizontal rule.
  const new({this.color, super.key});

  /// Optional colour override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: color ?? Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// A small uppercase section heading with an optional trailing count.
class KeyelSectionLabel extends StatelessWidget {
  /// Creates a section label.
  const new({
    required this.label,
    this.icon,
    this.trailing,
    this.color,
    super.key,
  });

  /// Heading copy; automatically uppercased.
  final String label;

  /// Optional leading glyph.
  final IconData? icon;

  /// Optional trailing widget, usually a count.
  final Widget? trailing;

  /// Overrides the default `primary` colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = color ?? scheme.primary;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: KeyelSpacing.xs + 2),
        ],
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// An alphabet divider used by the grouped vault list.
class KeyelLetterHeader extends StatelessWidget {
  /// Creates a letter divider.
  const new({required this.letter, super.key});

  /// The letter shown before the rule.
  final String letter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            letter,
            style: textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: KeyelSpacing.sm),
        Expanded(child: KeyelRule(color: scheme.outlineVariant)),
      ],
    );
  }
}
