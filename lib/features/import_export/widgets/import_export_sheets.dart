import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// The choices a restore/import sheet can return.
class ImportRequest {
  /// Creates an import request.
  const new({required this.mode, this.password});

  /// How the imported data combines with the live vault.
  final ImportModeDto mode;

  /// Backup password, for encrypted restores. Unused for CSV imports.
  final String? password;
}

/// Minimum length accepted for a backup password.
const _minBackupPasswordLength = 8;

/// Ask the user to choose a password for an encrypted backup.
///
/// Returns the password, or `null` if the sheet was dismissed.
Future<String?> showBackupPasswordSheet(BuildContext context) =>
    showKeyelAdaptiveSheet<String>(
      context: context,
      builder: (_) => const _BackupPasswordSheet(),
    );

/// Ask for the backup password and a merge/replace mode before restoring.
Future<ImportRequest?> showRestoreBackupSheet(
  BuildContext context, {
  required String fileName,
}) => showKeyelAdaptiveSheet<ImportRequest>(
  context: context,
  builder: (_) => _RestoreBackupSheet(fileName: fileName),
);

/// Show what a CSV file contains and ask how to apply it.
Future<ImportRequest?> showCsvPreviewSheet(
  BuildContext context, {
  required String fileName,
  required ImportPreviewDto preview,
}) => showKeyelAdaptiveSheet<ImportRequest>(
  context: context,
  builder: (_) => _CsvPreviewSheet(fileName: fileName, preview: preview),
);

/// Show the outcome of an import or restore.
Future<void> showImportReportSheet(
  BuildContext context, {
  required String title,
  required ImportReportDto report,
}) => showKeyelAdaptiveSheet<void>(
  context: context,
  builder: (_) => _ImportReportSheet(title: title, report: report),
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
    builder: (_) => _ExportSuccessSheet(
      title: title,
      message: message,
      unencrypted: unencrypted,
    ),
  );
  return shared ?? false;
}

// ---------------------------------------------------------------------------
// Export: choose a backup password
// ---------------------------------------------------------------------------

class _BackupPasswordSheet extends StatefulWidget {
  const new();

  @override
  State<_BackupPasswordSheet> createState() => _BackupPasswordSheetState();
}

class _BackupPasswordSheetState extends State<_BackupPasswordSheet> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _valid =>
      _password.text.length >= _minBackupPasswordLength &&
      _password.text == _confirm.text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strength = PasswordStrength.estimate(_password.text);
    final mismatch =
        _confirm.text.isNotEmpty && _confirm.text != _password.text;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.lg,
          KeyelSpacing.md,
          KeyelSpacing.lg,
          KeyelSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHeader(
              icon: Icons.lock_rounded,
              title: 'Encrypt backup',
              subtitle:
                  'Choose a password for this backup file. It can be different '
                  'from your master password and is never stored.',
            ),
            const SizedBox(height: KeyelSpacing.lg),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Backup password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KeyelSpacing.md),
            KeyelStrengthMeter(strength: strength),
            const SizedBox(height: KeyelSpacing.md),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                errorText: mismatch ? 'Passwords do not match' : null,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: 'Export backup',
              icon: Icons.file_download_outlined,
              onPressed: _valid ? _submit : null,
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              'The backup is a full, encrypted copy of your vault. Keep it '
              'somewhere safe.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(_password.text);
  }
}

// ---------------------------------------------------------------------------
// Restore: password + mode
// ---------------------------------------------------------------------------

class _RestoreBackupSheet extends StatefulWidget {
  const new({required this.fileName});

  final String fileName;

  @override
  State<_RestoreBackupSheet> createState() => _RestoreBackupSheetState();
}

class _RestoreBackupSheetState extends State<_RestoreBackupSheet> {
  final _password = TextEditingController();
  ImportModeDto _mode = ImportModeDto.merge;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.lg,
          KeyelSpacing.md,
          KeyelSpacing.lg,
          KeyelSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.restore_rounded,
              title: 'Restore backup',
              subtitle: widget.fileName,
            ),
            const SizedBox(height: KeyelSpacing.lg),
            TextFormField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Backup password'),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            _ModeSelector(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              _mode == ImportModeDto.merge
                  ? 'Entries already in your vault are kept.'
                  : 'Everything currently in your vault is replaced.',
              style: textTheme.bodySmall?.copyWith(
                color: _mode == ImportModeDto.replace
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: 'Restore',
              icon: Icons.restore_rounded,
              onPressed: _password.text.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_password.text.isEmpty) return;
    Navigator.of(context)
        .pop(ImportRequest(mode: _mode, password: _password.text));
  }
}

// ---------------------------------------------------------------------------
// CSV import: preview + mode
// ---------------------------------------------------------------------------

class _CsvPreviewSheet extends StatefulWidget {
  const new({required this.fileName, required this.preview});

  final String fileName;
  final ImportPreviewDto preview;

  @override
  State<_CsvPreviewSheet> createState() => _CsvPreviewSheetState();
}

class _CsvPreviewSheetState extends State<_CsvPreviewSheet> {
  ImportModeDto _mode = ImportModeDto.merge;

  String get _formatLabel => switch (widget.preview.format) {
    ImportFormatDto.bitwarden => 'Bitwarden',
    ImportFormatDto.chrome => 'Chrome',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preview = widget.preview;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.lg,
          KeyelSpacing.md,
          KeyelSpacing.lg,
          KeyelSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.upload_file_rounded,
              title: 'Import $_formatLabel CSV',
              subtitle: widget.fileName,
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelSectionCard(
              showBorder: true,
              child: Column(
                children: [
                  _CountRow(
                    icon: Icons.key_rounded,
                    label: 'Logins',
                    count: preview.logins,
                  ),
                  _CountRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Cards',
                    count: preview.cards,
                  ),
                  _CountRow(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Secure notes',
                    count: preview.notes,
                  ),
                  if (preview.failures.isNotEmpty)
                    _CountRow(
                      icon: Icons.error_outline_rounded,
                      label: 'Skipped rows',
                      count: preview.failures.length,
                      danger: true,
                    ),
                ],
              ),
            ),
            if (preview.failures.isNotEmpty) ...[
              const SizedBox(height: KeyelSpacing.sm),
              _FailureList(failures: preview.failures),
            ],
            const SizedBox(height: KeyelSpacing.lg),
            _ModeSelector(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              _mode == ImportModeDto.merge
                  ? 'Entries that look the same as ones you already have are '
                        'skipped.'
                  : 'Everything currently in your vault is replaced.',
              style: textTheme.bodySmall?.copyWith(
                color: _mode == ImportModeDto.replace
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label:
                  'Import ${preview.total} '
                  '${preview.total == 1 ? "entry" : "entries"}',
              icon: Icons.file_download_done_rounded,
              onPressed: preview.total == 0
                  ? null
                  : () => Navigator.of(context).pop(ImportRequest(mode: _mode)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Import report
// ---------------------------------------------------------------------------

class _ImportReportSheet extends StatelessWidget {
  const new({required this.title, required this.report});

  final String title;
  final ImportReportDto report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.lg,
          KeyelSpacing.md,
          KeyelSpacing.lg,
          KeyelSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.check_circle_rounded,
              title: title,
              subtitle: 'Here is what changed in your vault.',
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelSectionCard(
              showBorder: true,
              child: Column(
                children: [
                  _CountRow(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Added',
                    count: report.added,
                  ),
                  _CountRow(
                    icon: Icons.skip_next_rounded,
                    label: 'Already present',
                    count: report.skipped,
                  ),
                  if (report.foldersAdded > 0)
                    _CountRow(
                      icon: Icons.folder_rounded,
                      label: 'Folders created',
                      count: report.foldersAdded,
                    ),
                  if (report.failed > 0)
                    _CountRow(
                      icon: Icons.error_outline_rounded,
                      label: 'Failed rows',
                      count: report.failed,
                      danger: true,
                    ),
                ],
              ),
            ),
            if (report.failures.isNotEmpty) ...[
              const SizedBox(height: KeyelSpacing.sm),
              _FailureList(failures: report.failures),
            ],
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: 'Done',
              tone: KeyelButtonTone.neutral,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              'Your vault has been saved.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export success
// ---------------------------------------------------------------------------

class _ExportSuccessSheet extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.unencrypted,
  });

  final String title;
  final String message;
  final bool unencrypted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.lg,
          KeyelSpacing.md,
          KeyelSpacing.lg,
          KeyelSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.check_circle_rounded,
              title: title,
              subtitle: message,
            ),
            if (unencrypted) ...[
              const SizedBox(height: KeyelSpacing.md),
              Container(
                padding: const EdgeInsets.all(KeyelSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(KeyelRadii.field),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: KeyelSpacing.sm),
                    Expanded(
                      child: Text(
                        'This file is not encrypted. Delete it as soon as you '
                        'are done.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: 'Share',
              icon: Icons.ios_share_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            KeyelPillButton(
              label: 'Close',
              tone: KeyelButtonTone.neutral,
              height: 48,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

class _SheetHeader extends StatelessWidget {
  const new({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(KeyelRadii.field),
          ),
          child: Icon(icon, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: KeyelSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const new({required this.mode, required this.onChanged});

  final ImportModeDto mode;
  final ValueChanged<ImportModeDto> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeOption(
          icon: Icons.merge_rounded,
          title: 'Merge',
          subtitle: 'Add what is missing, keep the rest',
          selected: mode == ImportModeDto.merge,
          onTap: () => onChanged(ImportModeDto.merge),
        ),
        const SizedBox(height: KeyelSpacing.xs),
        _ModeOption(
          icon: Icons.swap_horiz_rounded,
          title: 'Replace',
          subtitle: 'Delete the current vault and use only this file',
          selected: mode == ImportModeDto.replace,
          onTap: () => onChanged(ImportModeDto.replace),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.field),
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: KeyelSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 20, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.count,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = danger ? scheme.error : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: danger ? scheme.error : scheme.primary),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: color),
            ),
          ),
          Text(
            '$count',
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureList extends StatelessWidget {
  const new({required this.failures});

  final List<ImportFailureDto> failures;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rows that could not be imported',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KeyelSpacing.xs),
          for (final failure in failures.take(20))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Row ${failure.row}: ${failure.reason}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          if (failures.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '…and ${failures.length - 20} more',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
