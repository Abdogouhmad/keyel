import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves the user-chosen folder that holds encrypted sync blobs.
///
/// Kept behind an interface so widget tests never touch the real picker.
abstract class SyncFolderService {
  /// Ask the user for a folder, returning `null` when they cancel.
  Future<String?> pickFolder();

  /// A private app folder, used when no system directory picker is available.
  Future<String> appSyncFolder();
}

/// Real implementation using `file_picker` and `path_provider`.
class PlatformSyncFolderService implements SyncFolderService {
  /// Creates the platform service.
  const new();

  @override
  Future<String?> pickFolder() =>
      FilePicker.getDirectoryPath(dialogTitle: currentL10n.synChooseFolder);

  @override
  Future<String> appSyncFolder() async {
    final directory = await getApplicationSupportDirectory();
    return '${directory.path}/keyel-sync';
  }
}

/// The app-wide sync folder service.
final syncFolderServiceProvider = Provider<SyncFolderService>(
  (ref) => const PlatformSyncFolderService(),
);
