import 'package:flutter/material.dart';

import 'package:keyel/features/import_export/widgets/import_export_form_sheets.dart';
import 'package:keyel/features/import_export/widgets/import_export_request.dart';
import 'package:keyel/features/import_export/widgets/import_export_result_sheets.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

export 'package:keyel/features/import_export/widgets/import_export_request.dart';

/// Ask the user to choose a password for an encrypted backup.
///
/// Returns the password, or `null` if the sheet was dismissed.
Future<String?> showBackupPasswordSheet(BuildContext context) =>
    showKeyelAdaptiveSheet<String>(
      context: context,
      builder: (_) => const BackupPasswordSheet(),
    );

/// Ask for the backup password and a merge/replace mode before restoring.
Future<ImportRequest?> showRestoreBackupSheet(
  BuildContext context, {
  required String fileName,
}) => showKeyelAdaptiveSheet<ImportRequest>(
  context: context,
  builder: (_) => RestoreBackupSheet(fileName: fileName),
);

/// Show what a CSV file contains and ask how to apply it.
Future<ImportRequest?> showCsvPreviewSheet(
  BuildContext context, {
  required String fileName,
  required ImportPreviewDto preview,
}) => showKeyelAdaptiveSheet<ImportRequest>(
  context: context,
  builder: (_) => CsvPreviewSheet(fileName: fileName, preview: preview),
);

/// Show the outcome of an import or restore.
Future<void> showImportReportSheet(
  BuildContext context, {
  required String title,
  required ImportReportDto report,
}) => showKeyelAdaptiveSheet<void>(
  context: context,
  builder: (_) => ImportReportSheet(title: title, report: report),
);

/// Show a success sheet after an export, with a Share action.
///
/// Resolves to `true` when the user tapped Share.
Future<bool> showExportSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  required bool unencrypted,
}) async {
  final shared = await showKeyelAdaptiveSheet<bool>(
    context: context,
    builder: (_) => ExportSuccessSheet(
      title: title,
      message: message,
      unencrypted: unencrypted,
    ),
  );
  return shared ?? false;
}
