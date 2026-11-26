import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolve the app-private vault path.
///
/// The vault lives in the application support directory, which Android keeps
/// private to the app and excludes from cloud backup where the OS allows it.
/// Call this once at startup, before any bridge session function.
///
/// Older builds may have stored the vault directly in the support/documents
/// directory. If that is the case, copy the newest legacy file into the
/// canonical location once so an app update never hides an existing vault.
Future<String> defaultVaultPath() async {
  late final Directory support;
  late final Directory directory;
  try {
    support = await getApplicationSupportDirectory();
    directory = Directory('${support.path}/keyel');
    await directory.create(recursive: true);
  } on Object catch (_) {
    // A missing application-support directory must not leave the Rust bridge
    // uninitialized: that would make every vault call fail with
    // "not initialized" and strand a first run on the create form. Fall back
    // to a hidden user-owned directory instead.
    support = await _fallbackSupportDirectory();
    directory = Directory('${support.path}/keyel');
    await directory.create(recursive: true);
  }
  final canonical = '${directory.path}/vault.keyel';

  if (!File(canonical).existsSync()) {
    await _migrateLegacyVault(canonical, support);
  }

  return canonical;
}

/// Last-resort location when the platform cannot resolve application support.
/// Uses the user's home profile; the vault file itself is always created
/// owner-only by the Rust store, so other local users cannot read it.
Future<Directory> _fallbackSupportDirectory() async {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null || home.isEmpty) {
    throw const FileSystemException(
      'No application support directory and no home directory are available',
    );
  }
  return Directory(home);
}

/// Candidate locations used by earlier builds, in preference order.
Future<void> _migrateLegacyVault(String canonical, Directory support) async {
  final candidates = <File>[File('${support.path}/vault.keyel')];

  try {
    final documents = await getApplicationDocumentsDirectory();
    candidates.addAll([
      File('${documents.path}/keyel/vault.keyel'),
      File('${documents.path}/vault.keyel'),
    ]);
  } on Object catch (_) {
    // Documents directory may not be available; support dir is enough.
  }

  // The contract is "newest legacy vault wins". Picking the first candidate
  // could resurrect an old vault while hiding a newer one.
  File? newest;
  for (final candidate in candidates) {
    if (candidate.path == canonical || !candidate.existsSync()) continue;
    if (newest == null ||
        candidate.lastModifiedSync().compareTo(newest.lastModifiedSync()) > 0) {
      newest = candidate;
    }
  }
  if (newest == null) return;

  // Copy to a temp file first. A direct copy that is interrupted leaves a
  // partial file at the canonical path; the existence check on the next launch
  // would then skip migration forever and the vault could never be opened.
  final temp = File('$canonical.migrate.tmp');
  try {
    newest.copySync(temp.path);
    temp.renameSync(canonical);
  } on Object catch (_) {
    try {
      if (temp.existsSync()) temp.deleteSync();
    } on Object catch (_) {
      // Best effort; a failed migration must never block startup.
    }
    return;
  }

  // Keep the sibling backup and preferences: dropping settings.json would
  // silently reset locale, theme and fail-closed autofill policy on upgrade.
  try {
    final backup = File('${newest.path}.bak');
    if (backup.existsSync()) backup.copySync('$canonical.bak');
  } on Object catch (_) {
    // The main vault is already migrated; a missing backup is not fatal.
  }
  try {
    final settings = File('${newest.parent.path}/settings.json');
    final target = File('${File(canonical).parent.path}/settings.json');
    if (settings.existsSync() && !target.existsSync()) {
      settings.copySync(target.path);
    }
  } on Object catch (_) {
    // Preferences are optional and fall back to fail-closed defaults.
  }
}
