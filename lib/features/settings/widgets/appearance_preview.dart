import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A live, non-interactive preview of the selected palette, mode and dark
/// surfaces.
///
/// The preview renders with the chosen theme rather than the surrounding app
/// theme, so switching to Dark while the device is in Light mode still shows
/// what the change will look like. It deliberately contains no secrets and no
/// tappable controls — it is a sample of the design language only.
class AppearancePreview extends StatelessWidget {
  /// Creates a preview for [appearance].
  const new({required this.appearance, super.key});

  /// Appearance settings currently selected by the user.
  final AppearanceState appearance;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final previewTheme = switch (appearance.themeMode) {
      ThemeMode.light => appearance.lightTheme,
      ThemeMode.dark => appearance.darkTheme,
      ThemeMode.system =>
        platformBrightness == Brightness.dark
            ? appearance.darkTheme
            : appearance.lightTheme,
    };
    final modeLabel = KeyelPaletteX.themeModeLabel(appearance.themeMode);

    return Semantics(
      container: true,
      label: l10n.prefThemePreviewSemantics(
        appearance.palette.label,
        modeLabel,
      ),
      child: Theme(
        data: previewTheme,
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            return Container(
              padding: const EdgeInsets.all(KeyelSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: KeyelSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.prefLivePreview,
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  Wrap(
                    spacing: KeyelSpacing.xs,
                    runSpacing: KeyelSpacing.xs,
                    children: [
                      KeyelBadge(
                        label: appearance.palette.label,
                        compact: true,
                        background: scheme.primaryContainer,
                        foreground: scheme.onPrimaryContainer,
                      ),
                      KeyelBadge(
                        label: modeLabel,
                        compact: true,
                        background: scheme.secondaryContainer,
                        foreground: scheme.onSecondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(KeyelSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(KeyelRadii.tile),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(KeyelRadii.sm),
                          ),
                          child: Icon(
                            Icons.key_rounded,
                            size: 18,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: KeyelSpacing.sm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.prefExampleLogin,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'user@example.com',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: KeyelSpacing.xs),
                        KeyelBadge(
                          label: l10n.prefLoginBadge,
                          compact: true,
                          background: scheme.tertiaryContainer,
                          foreground: scheme.onTertiaryContainer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  const KeyelRule(),
                  const SizedBox(height: KeyelSpacing.sm),
                  KeyelPillButton(
                    label: l10n.prefCopyPasswordLabel,
                    icon: Icons.copy_rounded,
                    height: 40,
                    expand: false,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  Text(
                    l10n.prefAppearanceChangesInstant,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
