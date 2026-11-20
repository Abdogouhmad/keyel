import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/import_export/widgets/import_export_request.dart';
import 'package:keyel/features/import_export/widgets/import_export_sheet_parts.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Minimum length accepted for a backup password.
const _minBackupPasswordLength = 8;

// ---------------------------------------------------------------------------
// Export: choose a backup password
// ---------------------------------------------------------------------------

/// Prompts for a new password used to encrypt an exported backup.
class BackupPasswordSheet extends StatefulWidget {
  /// Creates the backup-password sheet.
  const new({super.key});

  @override
  State<BackupPasswordSheet> createState() => _BackupPasswordSheetState();
}

class _BackupPasswordSheetState extends State<BackupPasswordSheet> {
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
            const SheetHeader(
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

/// Asks for the backup password and merge/replace mode before restoring.
class RestoreBackupSheet extends StatefulWidget {
  /// Creates the restore sheet for [fileName].
  const new({required this.fileName, super.key});

  /// Name of the backup file being restored.
  final String fileName;

  @override
  State<RestoreBackupSheet> createState() => _RestoreBackupSheetState();
}

class _RestoreBackupSheetState extends State<RestoreBackupSheet> {
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
            SheetHeader(
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
            ModeSelector(
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

/// Shows what a CSV file contains and asks how to apply it.
class CsvPreviewSheet extends StatefulWidget {
  /// Creates the preview sheet for [fileName] and [preview].
  const new({required this.fileName, required this.preview, super.key});

  /// Name of the CSV file being imported.
  final String fileName;

  /// Parsed preview produced by Rust (counts and skipped rows only).
  final ImportPreviewDto preview;

  @override
  State<CsvPreviewSheet> createState() => _CsvPreviewSheetState();
}

class _CsvPreviewSheetState extends State<CsvPreviewSheet> {
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
            SheetHeader(
              icon: Icons.upload_file_rounded,
              title: 'Import $_formatLabel CSV',
              subtitle: widget.fileName,
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelSectionCard(
              showBorder: true,
              child: Column(
                children: [
                  CountRow(
                    icon: Icons.key_rounded,
                    label: 'Logins',
                    count: preview.logins,
                  ),
                  CountRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Cards',
                    count: preview.cards,
                  ),
                  CountRow(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Secure notes',
                    count: preview.notes,
                  ),
                  if (preview.failures.isNotEmpty)
                    CountRow(
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
              FailureList(failures: preview.failures),
            ],
            const SizedBox(height: KeyelSpacing.lg),
            ModeSelector(
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
