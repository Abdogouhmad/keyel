import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A file the user picked from the system file picker.
class PickedFile {
  /// Creates a picked file.
  const new({required this.path, required this.name});

  /// Absolute local path. Rust reads the bytes from here.
  final String path;

  /// Display name, for the UI.
  final String name;
}

/// Platform file picking, sharing and temp-file cleanup.
///
/// An interface so widget tests can substitute a fake that never touches the
/// real file system or the share sheet.
abstract class FileTransferService {
  /// Open the system file picker and return the chosen file, or `null`.
  Future<PickedFile?> pickFile({String? dialogTitle});

  /// Resolve a path inside the app's temporary export directory.
  ///
  /// The file is not created; callers hand the path to Rust, which writes it.
  Future<String> temporaryFilePath(String fileName);

  /// Delete every file left in the temporary export directory.
  ///
  /// Called at the start of each export so a stale plaintext export from a
  /// previous session never lingers on disk.
  Future<void> clearTemporaryExports();

  /// Hand a local file to the platform share sheet.
  Future<void> shareFile(String path, {String? subject});

  /// Best-effort delete of a temporary file.
  Future<void> deleteFile(String path);
}

/// Real implementation backed by `file_picker`, `share_plus` and
/// `path_provider`.
class PlatformFileTransferService implements FileTransferService {
  /// Creates the platform service.
  const new();

  @override
  Future<PickedFile?> pickFile({String? dialogTitle}) async {
    final picked = await FilePicker.pickFile(dialogTitle: dialogTitle);
    final path = picked?.path;
    if (picked == null || path == null) return null;
    return PickedFile(path: path, name: picked.name);
  }

  @override
  Future<String> temporaryFilePath(String fileName) async {
    final folder = await _exportDirectory();
    return '${folder.path}/$fileName';
  }

  @override
  Future<void> clearTemporaryExports() async {
    final folder = await _exportDirectory();
    for (final entity in folder.listSync()) {
      try {
        entity.deleteSync(recursive: true);
      } on FileSystemException {
        // A file we cannot remove is not worth failing the export over.
      }
    }
  }

  Future<Directory> _exportDirectory() async {
    final directory = await getTemporaryDirectory();
    final folder = Directory('${directory.path}/keyel-export');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  @override
  Future<void> shareFile(String path, {String? subject}) => SharePlus.instance
      .share(ShareParams(files: [XFile(path)], subject: subject));

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// The app-wide file transfer service.
final fileTransferServiceProvider = Provider<FileTransferService>(
  (ref) => const PlatformFileTransferService(),
);
