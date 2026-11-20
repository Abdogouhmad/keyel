import 'package:keyel/src/rust/api/models.dart';

/// The choices a restore/import sheet can return.
class ImportRequest {
  /// Creates an import request.
  const new({required this.mode, this.password});

  /// How the imported data combines with the live vault.
  final ImportModeDto mode;

  /// Backup password, for encrypted restores. Unused for CSV imports.
  final String? password;
}
