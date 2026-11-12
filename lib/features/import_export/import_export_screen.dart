import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/file_transfer_service.dart';
import 'package:keyel/data/folders_provider.dart';
import 'package:keyel/data/health_provider.dart';
import 'package:keyel/data/vault_revision_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/import_export/widgets/import_export_sheets.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

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
    final password = await showBackupPasswordSheet(context);
    if (password == null || !mounted) return;

    await _runExport(
      fileName: 'keyel-backup-$_stamp.keyel',
      title: 'Backup created',
      message: 'Your encrypted backup is ready to share.',
      unencrypted: false,
      write: (path) => ref
          .read(vaultRepositoryProvider)
          .exportBackup(path: path, password: password),
    );
  }

  Future<void> _exportCsv() async {
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: 'Export unencrypted CSV?',
      body:
          'Every password in your vault will be written to a plain text file '
          'that anyone can read. Only do this if you know what you are doing.',
      confirmLabel: 'Export unencrypted',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _runExport(
      fileName: 'keyel-export-$_stamp.csv',
      title: 'CSV exported',
      message: 'Your unencrypted export is ready to share.',
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
    final picked = await _pickFile('Choose a CSV export to import');
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
      title: 'Import complete',
      action: () => ref
          .read(vaultRepositoryProvider)
          .importCsv(picked.path, request.mode),
    );
  }

  Future<void> _restoreBackup() async {
    final picked = await _pickFile('Choose a backup file to restore');
    if (picked == null || !mounted) return;

    final request = await showRestoreBackupSheet(
      context,
      fileName: picked.name,
    );
    if (request == null || !mounted) return;

    await _applyImport(
      title: 'Restore complete',
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Backup & import',
              icon: Icons.arrow_back_rounded,
              onIconTap: () => context.pop(),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.sm,
                  KeyelSpacing.lg,
                  KeyelSpacing.xxl,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: KeyelSpacing.md),
                    child: Text(
                      'Move your vault in and out safely. Encrypted backups use '
                      'their own password; CSV exports are plain text.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const KeyelSectionLabel(
                    label: 'Encrypted backup',
                    icon: Icons.shield_rounded,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  KeyelSectionCard(
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.file_download_outlined,
                          title: 'Export encrypted backup',
                          subtitle: 'Save an encrypted copy of your vault',
                          enabled: !_busy,
                          onTap: () => unawaited(_exportBackup()),
                        ),
                        _ActionRow(
                          icon: Icons.restore_rounded,
                          title: 'Restore from backup',
                          subtitle: 'Merge or replace your vault from a backup',
                          enabled: !_busy,
                          onTap: () => unawaited(_restoreBackup()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.lg),
                  const KeyelSectionLabel(
                    label: 'Import & export',
                    icon: Icons.swap_vert_rounded,
                  ),
                  const SizedBox(height: KeyelSpacing.sm),
                  KeyelSectionCard(
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.upload_file_rounded,
                          title: 'Import from CSV',
                          subtitle: 'Bitwarden or Chrome password exports',
                          enabled: !_busy,
                          onTap: () => unawaited(_importCsv()),
                        ),
                        _ActionRow(
                          icon: Icons.file_upload_outlined,
                          title: 'Export as plain CSV',
                          subtitle: 'Unencrypted — for moving to another app',
                          danger: true,
                          enabled: !_busy,
                          onTap: () => unawaited(_exportCsv()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable row inside a settings-style card.
class _ActionRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = danger ? scheme.error : scheme.primary;
    final opacity = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KeyelSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(KeyelRadii.field),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: KeyelSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
