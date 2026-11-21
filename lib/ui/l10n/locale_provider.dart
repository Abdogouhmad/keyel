import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Resolves a stored language id to a [Locale], or `null` for the system locale.
Locale? localeFromId(String id) => switch (id) {
  'en' => const Locale('en'),
  'fr' => const Locale('fr'),
  _ => null,
};

/// The user's language choice. `null` means "follow the system".
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Persists and exposes the selected app language.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => localeFromId(AppPreferences.instance.localeId);

  /// Changes the language at runtime. Unknown ids are ignored.
  void setLocaleId(String id) {
    final resolved = localeFromId(id);
    if (resolved == null && id != 'system') return;
    final prefs = AppPreferences.instance..localeId = id;
    setCurrentLocaleId(id);
    state = resolved;
    unawaited(prefs.save());
  }
}
