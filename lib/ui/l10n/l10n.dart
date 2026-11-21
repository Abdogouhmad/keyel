import 'package:flutter/widgets.dart';

import 'package:keyel/l10n/generated/app_localizations.dart';
import 'package:keyel/l10n/generated/app_localizations_en.dart';
import 'package:keyel/l10n/generated/app_localizations_fr.dart';

/// Resolves the generated messages for a stored language id.
AppLocalizations localizationsFor(String id) => switch (id) {
  'fr' => AppLocalizationsFr(),
  _ => AppLocalizationsEn(),
};

AppLocalizations _current = AppLocalizationsEn();

/// Messages for non-widget code (controllers, providers, services).
///
/// Widgets should prefer [l10nOf], which rebuilds when the locale changes.
/// This holder is updated at startup and by the language selector, so messages
/// produced outside the widget tree follow the same choice.
AppLocalizations get currentL10n => _current;

/// Updates the messages used by [currentL10n].
void setCurrentLocaleId(String id) => _current = localizationsFor(id);

/// Looks up localized copy for [context], falling back to the English template
/// when no delegate is mounted (for example in isolated widget tests that do
/// not install [AppLocalizations.localizationsDelegates]).
///
/// The running app always installs the delegates, so this fallback never
/// changes production behaviour; it only keeps tests and early startup frames
/// resilient.
AppLocalizations l10nOf(BuildContext context) =>
    AppLocalizations.of(context) ?? _current;
