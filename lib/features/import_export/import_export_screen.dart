import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/folders_provider.dart';
import 'package:keyel/data/health_provider.dart';
import 'package:keyel/data/vault_revision_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/import_export/widgets/import_export_hub_widgets.dart';
import 'package:keyel/features/import_export/widgets/import_export_sheets.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Backup, restore and CSV import/export hub.
class ImportExportScreen extends ConsumerStatefulWidget {
  /// Creates the import/export screen.
  const new({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _busy = false;
  final Set<String> _tempFiles = {};
  late final FileTransferService _files;

  @override
  void initState() {
    super.initState();
    // Capture the service now: `ref` is unsafe to read from `dispose`.
    _files = ref.read(fileTransferServiceProvider);
  }

  @override
  void dispose() {
    for (final path in _tempFiles) {
      unawaited(_files.deleteFile(path));
    }
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    showKeyelSnack(
      context,
      describeVaultError(error),
      icon: Icons.error_outline_rounded,
    );
  }

  /// Tell every vault view that many entries changed at once.
  void _afterVaultMutation() {
    ref
      ..invalidate(foldersProvider)
      ..invalidate(healthProvider);
    bumpVaultRevision(ref);
  }

  Future<PickedFile?> _pickFile(String dialogTitle) async {
    try {
      return await _files.pickFile(dialogTitle: dialogTitle);
    } on Object catch (error) {
      _showError(error);
      return null;
    }
  }

  String get _stamp {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  // --- Export -------------------------------------------------------------

  Future<void> _exportBackup() async {
    final l10n = l10nOf(context);
    final password = await showBackupPasswordSheet(context);
    if (password == null || !mounted) return;

    await _runExport(
      fileName: 'keyel-backup-$_stamp.keyel',
      title: l10n.imexBackupCreated,
      message: l10n.imexBackupReady,
      unencrypted: false,
      write: (path) => ref
          .read(vaultRepositoryProvider)
          .exportBackup(path: path, password: password),
    );
  }

  Future<void> _exportCsv() async {
    final l10n = l10nOf(context);
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.imexCsvExportTitle,
      body: l10n.imexCsvExportBody,
      confirmLabel: l10n.imexCsvExportConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _runExport(
      fileName: 'keyel-export-$_stamp.csv',
      title: l10n.imexCsvExported,
      message: l10n.imexCsvReady,
      unencrypted: true,
      write: (path) => ref.read(vaultRepositoryProvider).exportCsv(path),
    );
  }

  Future<void> _runExport({
    required String fileName,
    required String title,
    required String message,
    required bool unencrypted,
    required Future<void> Function(String path) write,
  }) async {
    setState(() => _busy = true);
    try {
      await _files.clearTemporaryExports();
      _tempFiles.clear();
      final path = await _files.temporaryFilePath(fileName);
      await write(path);
      _tempFiles.add(path);
      if (!mounted) return;
      setState(() => _busy = false);

      final share = await showExportSuccessSheet(
        context,
        title: title,
        message: message,
        unencrypted: unencrypted,
      );
      if (share && mounted) {
        await _files.shareFile(path, subject: title);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  // --- Import -------------------------------------------------------------

  Future<void> _importCsv() async {
    final l10n = l10nOf(context);
    final picked = await _pickFile(l10n.imexPickCsv);
    if (picked == null || !mounted) return;

    final ImportPreviewDto preview;
    try {
      preview = await ref
          .read(vaultRepositoryProvider)
          .previewImport(picked.path);
    } on Object catch (error) {
      _showError(error);
      return;
    }
    if (!mounted) return;

    final request = await showCsvPreviewSheet(
      context,
      fileName: picked.name,
      preview: preview,
    );
    if (request == null || !mounted) return;

    await _applyImport(
      title: l10n.imexImportComplete,
      action: () => ref
          .read(vaultRepositoryProvider)
          .importCsv(picked.path, request.mode),
    );
  }

  Future<void> _restoreBackup() async {
    final l10n = l10nOf(context);
    final picked = await _pickFile(l10n.imexPickBackup);
    if (picked == null || !mounted) return;

    final request = await showRestoreBackupSheet(
      context,
      fileName: picked.name,
    );
    if (request == null || !mounted) return;

    await _applyImport(
      title: l10n.imexRestoreComplete,
      action: () => ref
          .read(vaultRepositoryProvider)
          .importBackup(
            path: picked.path,
            password: request.password!,
            mode: request.mode,
          ),
    );
  }

  Future<void> _applyImport({
    required String title,
    required Future<ImportReportDto> Function() action,
  }) async {
    setState(() => _busy = true);
    try {
      final report = await action();
      if (!mounted) return;
      _afterVaultMutation();
      setState(() => _busy = false);
      await showImportReportSheet(context, title: title, report: report);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: l10n.prefBackupImportTitle,
              icon: context.backArrow,
              iconTooltip: l10n.actionBack,
              onIconTap: () => context.pop(),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            Expanded(
              child: KeyelContent(
                maxWidth: context.supportsTwoColumns
                    ? KeyelContentWidth.page
                    : KeyelContentWidth.reading,
                child: ImportExportHubBody(
                  busy: _busy,
                  onExportBackup: () => unawaited(_exportBackup()),
                  onRestoreBackup: () => unawaited(_restoreBackup()),
                  onImportCsv: () => unawaited(_importCsv()),
                  onExportCsv: () => unawaited(_exportCsv()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
