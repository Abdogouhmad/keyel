import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/features/settings/widgets/appearance_preview.dart';
import 'package:keyel/features/settings/widgets/appearance_widgets.dart';
import 'package:keyel/features/settings/widgets/language_selector.dart';
import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
    final l10n = l10nOf(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: KeyelContent(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: KeyelTopBar(
                  title: l10n.appearanceTitle,
                  icon: context.backArrow,
                  iconTooltip: l10n.actionBack,
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
                        l10n.appearanceHeadline,
                        style: textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appearanceSubtitle,
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
                sliver: SliverToBoxAdapter(
                  child: AppearancePreview(appearance: appearance),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: KeyelSpacing.lg),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.md,
                ),
                sliver: SliverList.list(
                  children: [
                    KeyelSectionLabel(
                      label: l10n.themeModeTitle,
                      icon: Icons.brightness_6_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    KeyelSectionCard(
                      child: ThemeModeSelector(
                        selected: appearance.themeMode,
                        onChanged: notifier.setThemeMode,
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    KeyelSectionLabel(
                      label: l10n.paletteTitle,
                      icon: Icons.palette_outlined,
                      trailing: KeyelBadge(
                        label: l10n.paletteColors(KeyelPalette.values.length),
                        compact: true,
                      ),
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
                            AppearancePaletteTile(
                              palette: KeyelPalette.values[i],
                              selected:
                                  appearance.palette == KeyelPalette.values[i],
                              onTap: () =>
                                  notifier.setPalette(KeyelPalette.values[i]),
                            ),
                            if (i < KeyelPalette.values.length - 1)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 56,
                                ),
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
                    KeyelSectionLabel(
                      label: l10n.darkModeTitle,
                      icon: Icons.dark_mode_outlined,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: Icons.contrast_rounded,
                          title: l10n.amoledTitle,
                          subtitle: l10n.amoledSubtitle,
                          trailing: Switch.adaptive(
                            value: appearance.amoledBlack,
                            onChanged: (value) =>
                                notifier.setAmoledBlack(enabled: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    KeyelSectionLabel(
                      label: l10n.interactionTitle,
                      icon: Icons.touch_app_outlined,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: Icons.animation_rounded,
                          title: l10n.animationsTitle,
                          subtitle: l10n.animationsSubtitle,
                          trailing: Switch.adaptive(
                            value: appearance.animationsEnabled,
                            onChanged: (value) =>
                                notifier.setAnimationsEnabled(enabled: value),
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.vibration_rounded,
                          title: l10n.hapticsTitle,
                          subtitle: l10n.hapticsSubtitle,
                          trailing: Switch.adaptive(
                            value: appearance.hapticsEnabled,
                            onChanged: (value) =>
                                notifier.setHapticsEnabled(enabled: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    KeyelSectionLabel(
                      label: l10n.settingsLanguageTitle,
                      icon: Icons.language_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    const SettingsCard(children: [LanguageSelector()]),
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
}
