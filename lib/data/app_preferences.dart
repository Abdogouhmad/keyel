import 'dart:convert';
import 'dart:io';

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
        jsonEncode({'autoLockSeconds': autoLockDelay.inSeconds}),
        flush: true,
      );
    } on Object catch (_) {
      // A read-only or missing directory must not break the UI.
    }
  }
}
