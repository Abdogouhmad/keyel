import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/ui/keyel.dart';

/// Appearance and interaction preferences.
class AppearanceScreen extends ConsumerWidget {
  /// Creates the appearance screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: KeyelContent(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: KeyelTopBar(
                  title: 'Appearance',
                  icon: Icons.arrow_back_rounded,
                  onIconTap: () => context.pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.xs,
                  KeyelSpacing.lg,
                  KeyelSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalize Keyel',
                        style: textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your theme, accent palette, and interaction '
                        'preferences. Security indicators stay consistent.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.md,
                ),
                sliver: SliverList.list(
                  children: [
                    const KeyelSectionLabel(
                      label: 'Theme mode',
                      icon: Icons.brightness_6_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    KeyelSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<ThemeMode>(
                            segments: ThemeMode.values
                                .map(
                                  (mode) => ButtonSegment<ThemeMode>(
                                    value: mode,
                                    label: Text(
                                      KeyelPaletteX.themeModeLabel(mode),
                                    ),
                                    icon: Icon(_modeIcon(mode)),
                                  ),
                                )
                                .toList(),
                            selected: {appearance.themeMode},
                            onSelectionChanged: (selection) =>
                                notifier.setThemeMode(selection.first),
                            showSelectedIcon: false,
                          ),
                          const SizedBox(height: KeyelSpacing.sm),
                          Text(
                            'System follows your device appearance setting.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    const KeyelSectionLabel(
                      label: 'Color palette',
                      icon: Icons.palette_outlined,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    KeyelSectionCard(
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < KeyelPalette.values.length;
                            i++
                          ) ...[
                            _PaletteTile(
                              palette: KeyelPalette.values[i],
                              selected:
                                  appearance.palette == KeyelPalette.values[i],
                              onTap: () =>
                                  notifier.setPalette(KeyelPalette.values[i]),
                            ),
                            if (i < KeyelPalette.values.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: KeyelRule(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    const KeyelSectionLabel(
                      label: 'Dark mode',
                      icon: Icons.dark_mode_outlined,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: Icons.contrast_rounded,
                          title: 'Pure black (AMOLED)',
                          subtitle:
                              'Use true black backgrounds in dark mode to reduce '
                              'OLED glow and save power on supported displays.',
                          trailing: Switch.adaptive(
                            value: appearance.amoledBlack,
                            onChanged: (value) =>
                                notifier.setAmoledBlack(enabled: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    const KeyelSectionLabel(
                      label: 'Interaction',
                      icon: Icons.touch_app_outlined,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: Icons.animation_rounded,
                          title: 'Animations',
                          subtitle:
                              'Enable motion and transitions throughout the app. '
                              'System reduced-motion settings are always respected.',
                          trailing: Switch.adaptive(
                            value: appearance.animationsEnabled,
                            onChanged: (value) =>
                                notifier.setAnimationsEnabled(enabled: value),
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.vibration_rounded,
                          title: 'Haptics',
                          subtitle:
                              'Enable tactile feedback for taps and actions where '
                              'supported by your device.',
                          trailing: Switch.adaptive(
                            value: appearance.hapticsEnabled,
                            onChanged: (value) =>
                                notifier.setHapticsEnabled(enabled: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _modeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };
}

class _PaletteTile extends StatelessWidget {
  const new({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final KeyelPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final swatchScheme = Theme.of(context).brightness == Brightness.dark
        ? palette.darkScheme()
        : palette.lightScheme();

    return InkWell(
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
    );
  }
}
