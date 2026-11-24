import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';

/// Immutable snapshot of the autofill settings shown in Settings.
@immutable
class AutofillSettings {
  /// Creates an autofill settings snapshot.
  const new({
    required this.askToSave,
    required this.matchMode,
    required this.verifiedOnly,
    required this.neverForSites,
  });

  /// Whether the platform autofill service may offer to save new credentials.
  final bool askToSave;

  /// Either `domain` (broad) or `exact` (strict identity match).
  final String matchMode;

  /// Fail-closed gate: only offer credentials with a verified host/package.
  ///
  /// Defaults to `true`; only an explicit persisted `false` relaxes it.
  final bool verifiedOnly;

  /// Targets the user chose to never autofill.
  final List<String> neverForSites;
}

/// Reactive mirror of the autofill preferences.
///
/// [AppPreferences] has no change notification. Settings watches this provider
/// so a toggle updates the UI immediately; the singleton stays the persisted
/// source of truth. Every setter writes through to it before saving, so the
/// fail-closed picker still reads the same value on its next async load.
final autofillSettingsProvider =
    NotifierProvider<AutofillSettingsNotifier, AutofillSettings>(
      AutofillSettingsNotifier.new,
    );

/// Persists and exposes the autofill choices.
class AutofillSettingsNotifier extends Notifier<AutofillSettings> {
  @override
  AutofillSettings build() => _snapshot(AppPreferences.instance);

  AutofillSettings _snapshot(AppPreferences prefs) => AutofillSettings(
    askToSave: prefs.autofillAskToSave,
    matchMode: prefs.autofillMatchMode,
    verifiedOnly: prefs.autofillVerifiedOnly,
    neverForSites: List<String>.unmodifiable(prefs.autofillNeverForSites),
  );

  /// Update a preference through the singleton, publish the new snapshot and
  /// persist it. Kept as one path so no setter can forget to notify listeners.
  void _write(void Function(AppPreferences prefs) change) {
    final prefs = AppPreferences.instance;
    change(prefs);
    state = _snapshot(prefs);
    unawaited(prefs.save());
  }

  /// Enable or disable offering to save credentials.
  void setAskToSave({required bool value}) =>
      _write((prefs) => prefs.autofillAskToSave = value);

  /// Toggle between broad domain matching and strict exact matching.
  void toggleMatchMode() => _write((prefs) {
    prefs.autofillMatchMode = prefs.autofillMatchMode == 'exact'
        ? 'domain'
        : 'exact';
  });

  /// Relax or restore the verified-only gate.
  void setVerifiedOnly({required bool value}) =>
      _write((prefs) => prefs.autofillVerifiedOnly = value);

  /// Remove one target from the "never autofill" list.
  void removeNeverSite(String site) => _write((prefs) {
    prefs.autofillNeverForSites = prefs.autofillNeverForSites
        .where((value) => value != site)
        .toList();
  });
}
