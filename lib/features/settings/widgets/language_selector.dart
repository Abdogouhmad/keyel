import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/l10n/generated/app_localizations.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/l10n/locale_provider.dart';

const _languageOptions = ['system', 'en', 'fr'];

/// Settings row that switches the app language without a restart.
class LanguageSelector extends ConsumerWidget {
  /// Creates the language row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = l10nOf(context);
    final locale = ref.watch(localeProvider);
    final label = locale == null
        ? l10n.languageFollowSystem
        : locale.languageCode == 'fr'
        ? l10n.languageFrench
        : l10n.languageEnglish;

    Future<void> pickLanguage() async {
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final dialogL10n = l10nOf(dialogContext);
          return SimpleDialog(
            title: Text(dialogL10n.settingsLanguageTitle),
            children: [
              for (final id in _languageOptions)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(id),
                  child: Row(
                    children: [
                      Icon(
                        id == (locale?.languageCode ?? 'system')
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: KeyelSpacing.sm),
                      Text(_optionLabel(dialogL10n, id)),
                    ],
                  ),
                ),
            ],
          );
        },
      );
      if (selected == null || !context.mounted) return;
      ref.read(localeProvider.notifier).setLocaleId(selected);
    }

    return SettingsRow(
      icon: Icons.language_rounded,
      title: l10n.settingsLanguageTitle,
      subtitle: l10n.settingsLanguageSubtitle,
      trailing: Text(label),
      onTap: pickLanguage,
    );
  }

  String _optionLabel(AppLocalizations l10n, String id) => switch (id) {
    'en' => l10n.languageEnglish,
    'fr' => l10n.languageFrench,
    _ => l10n.languageFollowSystem,
  };
}
