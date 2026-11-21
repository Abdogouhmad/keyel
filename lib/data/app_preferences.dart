import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:keyel/data/autofill_target.dart';

/// Small, non-secret preference store kept next to the vault file.
///
/// The vault itself is the only source of truth for secrets; this file only
/// remembers UI preferences such as the auto-lock delay so they survive an
/// app restart. It is loaded synchronously at startup, before the first frame.
class AppPreferences {
  // Private: callers must use [instance]. The lint fires on the empty private
  // constructor even though Dart requires a named generative constructor here.
  // ignore: unnecessary_type_name_in_constructor
  AppPreferences._();

  /// Shared instance used by providers and the settings screen.
  static final instance = AppPreferences._();

  /// How long the app may stay in the background before the vault locks.
  Duration autoLockDelay = const Duration(minutes: 1);

  /// Whether biometric unlock is enabled by the user.
  bool biometricEnabled = false;

  /// Most recent vault searches, newest first.
  List<String> recentSearches = <String>[];

  /// Remembered generator mode (`password` or `passphrase`).
  String generatorMode = 'password';

  /// Remembered password length.
  int generatorLength = 20;

  /// Remembered passphrase word count.
  int generatorWordCount = 8;

  /// Remembered character-class switches.
  bool generatorUppercase = true;

  /// Whether generated passwords include lowercase letters.
  bool generatorLowercase = true;

  /// Whether generated passwords include digits.
  bool generatorNumbers = true;

  /// Whether generated passwords include symbols.
  bool generatorSymbols = true;

  /// Whether generated passwords drop look-alike characters.
  bool generatorExcludeAmbiguous = true;

  /// Whether passphrase words are capitalised.
  bool generatorCapitalize = true;

  /// Whether a random number is appended to passphrases.
  bool generatorIncludeNumber = false;

  /// Remembered passphrase word separator.
  String generatorSeparator = '-';

  /// Whether the autofill save prompt is offered after a successful fill.
  bool autofillAskToSave = true;

  /// Autofill matching strictness: `domain` also matches subdomains, while
  /// `exact` requires the same host or Android package.
  String autofillMatchMode = 'domain';

  /// Require exact package/host identity when matching logins for autofill.
  ///
  /// This is the offline substitute for Digital Asset Links verification:
  /// same-site and text-search hits are suppressed because they cannot be
  /// proven locally. No network request is ever made.
  bool autofillVerifiedOnly = false;

  /// Sites/apps the user chose "Never for this site" on.
  ///
  /// Canonical `host:<host>` or `package:<package>` keys only: never usernames,
  /// passwords or vault contents. Capped on load so a corrupted file cannot
  /// grow without bound. Not a secret.
  List<String> autofillNeverForSites = <String>[];

  /// How long copied secrets stay on the clipboard, in seconds. Zero means
  /// never clear them. Not a secret.
  int clipboardClearSeconds = 30;

  /// Whether screenshots and Recents previews are blocked while unlocked.
  ///
  /// Defaults to `true`. Disabling it lets the user capture in-app designs;
  /// the lock/unlock screens and the autofill/passkey entrypoints stay secure
  /// regardless. Not a secret.
  bool screenshotProtection = true;

  /// How long copied secrets stay on the clipboard, or `null` to never clear.
  Duration? get clipboardClearDelay => clipboardClearSeconds <= 0
      ? null
      : Duration(seconds: clipboardClearSeconds);

  /// Consecutive failed master-password attempts, persisted so the unlock
  /// throttle survives an app restart. Not a secret.
  int unlockFailures = 0;

  /// Epoch milliseconds before which unlock attempts are refused, or `null`.
  /// Persisted alongside [unlockFailures]; not a secret.
  int? unlockLockedUntilMs;

  /// Preferred app language: `system`, `en`, or `fr`.
  ///
  /// Not a secret. Only these three values are accepted on load; anything else
  /// falls back to the system locale.
  String localeId = 'system';

  /// Preferred app theme mode: `system`, `light`, or `dark`.
  String themeMode = 'system';

  /// Selected accent palette identifier.
  String paletteId = 'indigo';

  /// Whether dark surfaces should use pure black for OLED displays.
  bool amoledBlack = false;

  /// Whether in-app animations and motion effects are enabled.
  bool animationsEnabled = true;

  /// Whether haptic feedback is enabled.
  bool hapticsEnabled = true;

  /// Whether the user opted in to HIBP breach checks.
  ///
  /// Off by default. This is a non-secret preference: no hash, prefix, result,
  /// or password-derived value is ever stored here. See `docs/roadmap_1.7.0.md`.
  bool breachCheckEnabled = false;

  /// Selected OTA channel: `stable` or `beta`.
  String otaChannel = 'stable';

  /// Whether Keyel checks for updates when it opens and on foreground resume.
  bool otaAutoCheck = true;

  /// Epoch milliseconds of the last OTA check, used to throttle silent checks.
  int? otaLastCheckedMs;

  /// Version for which an update notification was last posted.
  String? otaLastNotifiedVersion;

  /// Version whose in-app update banner the user dismissed.
  String? otaDismissedVersion;

  /// Whether the Android notification permission prompt was already shown.
  bool otaNotificationPromptShown = false;

  /// Remember a search term, keeping at most eight unique values.
  void rememberSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    recentSearches = [
      trimmed,
      ...recentSearches.where(
        (value) => value.toLowerCase() != trimmed.toLowerCase(),
      ),
    ].take(8).toList();
    unawaited(save());
  }

  /// Drop all remembered searches.
  void clearRecentSearches() {
    recentSearches = <String>[];
    unawaited(save());
  }

  /// File backing the preferences, or `null` when not initialized.
  File? _file;

  /// Load preferences from `settings.json` beside [vaultPath].
  ///
  /// Missing or unreadable files fall back to the defaults. This must never
  /// block startup, so all failures are ignored.
  Future<void> load(String vaultPath) async {
    try {
      final file = File('${File(vaultPath).parent.path}/settings.json');
      _file = file;
      if (!file.existsSync()) return;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return;
      final seconds = decoded['autoLockSeconds'];
      if (seconds is int && seconds >= 0) {
        autoLockDelay = Duration(seconds: seconds);
      }
      biometricEnabled = decoded['biometricEnabled'] == true;
      autofillAskToSave = decoded['autofillAskToSave'] != false;
      autofillMatchMode = decoded['autofillMatchMode'] == 'exact'
          ? 'exact'
          : 'domain';
      autofillVerifiedOnly = decoded['autofillVerifiedOnly'] == true;
      final denied = decoded['autofillNeverForSites'];
      if (denied is List) {
        autofillNeverForSites = denied
            .whereType<String>()
            .map((value) => value.trim())
            .where(isValidAutofillTarget)
            .toSet()
            .take(100)
            .toList();
      }
      final clipboard = decoded['clipboardClearSeconds'];
      if (clipboard is int && clipboard >= 0) {
        clipboardClearSeconds = clipboard;
      }
      // Fail safe: only an explicit `false` relaxes the default.
      screenshotProtection = decoded['screenshotProtection'] != false;
      final failures = decoded['unlockFailures'];
      if (failures is int && failures >= 0) {
        unlockFailures = failures;
      }
      final lockedUntil = decoded['unlockLockedUntilMs'];
      if (lockedUntil is int) {
        unlockLockedUntilMs = lockedUntil;
      }
      final searches = decoded['recentSearches'];
      if (searches is List) {
        recentSearches = searches
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .take(8)
            .toList();
      }

      final localeId = decoded['localeId'];
      if (localeId == 'system' || localeId == 'en' || localeId == 'fr') {
        this.localeId = localeId as String;
      }
      final mode = decoded['themeMode'];
      if (mode == 'light' || mode == 'dark' || mode == 'system') {
        themeMode = mode as String;
      }
      final palette = decoded['paletteId'];
      if (palette is String && palette.trim().isNotEmpty) {
        paletteId = palette;
      }
      amoledBlack = decoded['amoledBlack'] == true;
      animationsEnabled = decoded['animationsEnabled'] != false;
      hapticsEnabled = decoded['hapticsEnabled'] != false;
      breachCheckEnabled = decoded['breachCheckEnabled'] == true;

      otaChannel = decoded['otaChannel'] == 'beta' ? 'beta' : 'stable';
      otaAutoCheck = decoded['otaAutoCheck'] != false;
      final lastOtaCheck = decoded['otaLastCheckedMs'];
      if (lastOtaCheck is int && lastOtaCheck > 0) {
        otaLastCheckedMs = lastOtaCheck;
      }
      final lastNotified = decoded['otaLastNotifiedVersion'];
      if (lastNotified is String && lastNotified.isNotEmpty) {
        otaLastNotifiedVersion = lastNotified;
      }
      final dismissedUpdate = decoded['otaDismissedVersion'];
      if (dismissedUpdate is String && dismissedUpdate.isNotEmpty) {
        otaDismissedVersion = dismissedUpdate;
      }
      otaNotificationPromptShown =
          decoded['otaNotificationPromptShown'] == true;

      final generator = decoded['generator'];
      if (generator is Map) {
        generatorMode = generator['mode'] == 'passphrase'
            ? 'passphrase'
            : 'password';
        if (generator['length'] is int) {
          generatorLength = (generator['length'] as int).clamp(4, 128);
        }
        if (generator['wordCount'] is int) {
          generatorWordCount = (generator['wordCount'] as int).clamp(4, 12);
        }
        generatorUppercase = generator['uppercase'] != false;
        generatorLowercase = generator['lowercase'] != false;
        generatorNumbers = generator['numbers'] != false;
        generatorSymbols = generator['symbols'] != false;
        generatorExcludeAmbiguous = generator['excludeAmbiguous'] != false;
        generatorCapitalize = generator['capitalize'] != false;
        generatorIncludeNumber = generator['includeNumber'] == true;
        if (generator['separator'] is String) {
          generatorSeparator = generator['separator'] as String;
        }
      }
    } on Object catch (_) {
      // Preferences are optional; keep the defaults on any failure.
    }
  }

  /// Persist the current preferences. Failures are intentionally ignored.
  Future<void> save() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(
        jsonEncode({
          'autoLockSeconds': autoLockDelay.inSeconds,
          'biometricEnabled': biometricEnabled,
          'autofillAskToSave': autofillAskToSave,
          'autofillMatchMode': autofillMatchMode,
          'autofillVerifiedOnly': autofillVerifiedOnly,
          'autofillNeverForSites': autofillNeverForSites,
          'clipboardClearSeconds': clipboardClearSeconds,
          'screenshotProtection': screenshotProtection,
          'unlockFailures': unlockFailures,
          'unlockLockedUntilMs': unlockLockedUntilMs,
          'localeId': localeId,
          'themeMode': themeMode,
          'paletteId': paletteId,
          'amoledBlack': amoledBlack,
          'animationsEnabled': animationsEnabled,
          'hapticsEnabled': hapticsEnabled,
          'breachCheckEnabled': breachCheckEnabled,
          'otaChannel': otaChannel,
          'otaAutoCheck': otaAutoCheck,
          'otaLastCheckedMs': otaLastCheckedMs,
          'otaLastNotifiedVersion': otaLastNotifiedVersion,
          'otaDismissedVersion': otaDismissedVersion,
          'otaNotificationPromptShown': otaNotificationPromptShown,
          'recentSearches': recentSearches,
          'generator': {
            'mode': generatorMode,
            'length': generatorLength,
            'wordCount': generatorWordCount,
            'uppercase': generatorUppercase,
            'lowercase': generatorLowercase,
            'numbers': generatorNumbers,
            'symbols': generatorSymbols,
            'excludeAmbiguous': generatorExcludeAmbiguous,
            'capitalize': generatorCapitalize,
            'includeNumber': generatorIncludeNumber,
            'separator': generatorSeparator,
          },
        }),
        flush: true,
      );
    } on Object catch (_) {
      // A read-only or missing directory must not break the UI.
    }
  }
}
