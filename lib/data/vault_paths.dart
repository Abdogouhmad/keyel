import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolve the app-private vault path.
///
/// The vault lives in the application support directory, which Android keeps
/// private to the app and excludes from cloud backup where the OS allows it.
/// Call this once at startup, before any bridge session function.
Future<String> defaultVaultPath() async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/keyel');
  await directory.create(recursive: true);
  return '${directory.path}/vault.keyel';
}
