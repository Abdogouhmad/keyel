import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Selectable color palette tile used on the appearance screen.
class AppearancePaletteTile extends StatelessWidget {
  /// Creates a palette tile.
  const new({
    required this.palette,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Palette represented by this tile.
  final KeyelPalette palette;

  /// Whether this palette is currently selected.
  final bool selected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final swatchScheme = Theme.of(context).brightness == Brightness.dark
        ? palette.darkScheme()
        : palette.lightScheme();

    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.label}. ${palette.description}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KeyelSpacing.sm,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KeyelRadii.field),
                  gradient: LinearGradient(
                    colors: [swatchScheme.primary, swatchScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: KeyelSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.label,
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A radio-style picker for System / Light / Dark.
///
/// Each option explains what it does, so the choice is understandable without
/// opening the preview or guessing what "System" resolves to on this device.
class ThemeModeSelector extends StatelessWidget {
  /// Creates a theme-mode picker.
  const new({required this.selected, required this.onChanged, super.key});

  /// Currently selected mode.
  final ThemeMode selected;

  /// Called with the newly selected mode.
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);

    return Semantics(
      label: l10n.prefThemeModeSemantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mode in ThemeMode.values) ...[
            _ThemeModeOption(
              mode: mode,
              selected: mode == selected,
              platformBrightness: platformBrightness,
              onTap: () => onChanged(mode),
            ),
            if (mode != ThemeMode.values.last)
              const SizedBox(height: KeyelSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const new({
    required this.mode,
    required this.selected,
    required this.platformBrightness,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final Brightness platformBrightness;
  final VoidCallback onTap;

  IconData get _icon => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };

  String get _label => KeyelPaletteX.themeModeLabel(mode);

  String get _description => switch (mode) {
    ThemeMode.system => currentL10n.prefThemeSystemDescription,
    ThemeMode.light => currentL10n.prefThemeLightDescription,
    ThemeMode.dark => currentL10n.prefThemeDarkDescription,
  };

  String get _semanticLabel {
    final l10n = currentL10n;
    if (mode != ThemeMode.system) {
      return l10n.prefThemeSemanticLabel(_label, _description);
    }
    final current = platformBrightness == Brightness.dark
        ? l10n.prefDeviceDarkValue
        : l10n.prefDeviceLightValue;
    return l10n.prefThemeSemanticWithDevice(_label, _description, current);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final duration = KeyelMotion.resolve(context, KeyelMotion.fast);
    final foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: _semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KeyelRadii.tile),
        child: AnimatedContainer(
          duration: duration,
          curve: KeyelMotion.spring,
          padding: const EdgeInsets.all(KeyelSpacing.sm + 4),
          decoration: BoxDecoration(
            color: selected
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(KeyelRadii.tile),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(KeyelRadii.field),
                ),
                child: Icon(
                  _icon,
                  color: selected ? scheme.onPrimary : scheme.primary,
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.xs),
                    Text(
                      _description,
                      style: textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onSecondaryContainer.withValues(
                                alpha: 0.85,
                              )
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (mode == ThemeMode.system) ...[
                      const SizedBox(height: KeyelSpacing.xs),
                      KeyelBadge(
                        label: l10n.prefDeviceCurrently(
                          platformBrightness == Brightness.dark
                              ? l10n.prefDeviceDarkValue
                              : l10n.prefDeviceLightValue,
                        ),
                        compact: true,
                        background: scheme.surfaceContainerHigh,
                        foreground: scheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: KeyelSpacing.xs),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
