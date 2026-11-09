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
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/keyel');
  await directory.create(recursive: true);
  final canonical = '${directory.path}/vault.keyel';

  if (!File(canonical).existsSync()) {
    await _migrateLegacyVault(canonical, support);
  }

  return canonical;
}

/// Candidate locations used by earlier builds, in preference order.
Future<void> _migrateLegacyVault(String canonical, Directory support) async {
  final candidates = <String>['${support.path}/vault.keyel'];

  try {
    final documents = await getApplicationDocumentsDirectory();
    candidates.addAll([
      '${documents.path}/keyel/vault.keyel',
      '${documents.path}/vault.keyel',
    ]);
  } on Object catch (_) {
    // Documents directory may not be available; support dir is enough.
  }

  for (final candidate in candidates) {
    if (candidate == canonical) continue;
    final file = File(candidate);
    if (!file.existsSync()) continue;

    try {
      file.copySync(canonical);
      final backup = File('$candidate.bak');
      if (backup.existsSync()) backup.copySync('$canonical.bak');
      return;
    } on Object catch (_) {
      // Try the next candidate; a failed migration must never block startup.
    }
  }
}
