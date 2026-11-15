import 'dart:io';

import 'package:keyel/core/app_info.dart';
import 'package:keyel/data/app_preferences.dart';

/// Builds the redacted diagnostics text attached to a bug report.
///
/// Contains only build, device and non-secret preference facts. It must never
/// include vault contents, entry titles, recent searches, master passwords,
/// recovery keys or key material (roadmap 0.12 item 3; see
/// `docs/threat-model.md`).
String buildDebugBundle({
  required String appVersion,
  required String platform,
  required Map<String, Object?> settings,
  DateTime? generatedAt,
}) {
  final now = (generatedAt ?? DateTime.now()).toUtc();
  final buffer = StringBuffer()
    ..writeln('Keyel diagnostics')
    ..writeln('Generated (UTC): ${now.toIso8601String()}')
    ..writeln('App version: $appVersion')
    ..writeln('Platform: $platform')
    ..writeln()
    ..writeln('Non-secret settings:');
  // Sorted so two reports are easy to diff.
  final keys = settings.keys.toList()..sort();
  for (final key in keys) {
    buffer.writeln('  $key: ${settings[key]}');
  }
  buffer
    ..writeln()
    ..writeln('No vault data, passwords or key material is included.');
  return buffer.toString();
}

/// Collects the live platform and preference facts for [buildDebugBundle].
///
/// Reads [AppPreferences] but only its non-secret fields: never
/// `recentSearches`.
String collectDebugBundle({AppPreferences? preferences}) {
  final prefs = preferences ?? AppPreferences.instance;
  return buildDebugBundle(
    appVersion: AppInfo.version,
    platform: _platformDescription(),
    settings: {
      'autoLockSeconds': prefs.autoLockDelay.inSeconds,
      'clipboardClearSeconds': prefs.clipboardClearSeconds,
      'biometricEnabled': prefs.biometricEnabled,
      'autofillAskToSave': prefs.autofillAskToSave,
      'autofillMatchMode': prefs.autofillMatchMode,
      'unlockFailures': prefs.unlockFailures,
    },
  );
}

String _platformDescription() {
  final os = Platform.operatingSystem;
  final version = Platform.operatingSystemVersion.replaceAll('\n', ' ');
  return '$os $version';
}
