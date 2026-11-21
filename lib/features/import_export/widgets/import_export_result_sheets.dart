import 'package:flutter/material.dart';

import 'package:keyel/features/import_export/widgets/import_export_sheet_parts.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Import report
// ---------------------------------------------------------------------------

/// Shows the outcome of an import or restore.
class ImportReportSheet extends StatelessWidget {
  /// Creates the report sheet.
  const new({required this.title, required this.report, super.key});

  /// Heading (e.g. "Import complete").
  final String title;

  /// Counts and skipped rows reported by Rust.
  final ImportReportDto report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

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
              icon: Icons.check_circle_rounded,
              title: title,
              subtitle: l10n.imexReportSubtitle,
            ),
            const SizedBox(height: KeyelSpacing.lg),
            KeyelSectionCard(
              showBorder: true,
              child: Column(
                children: [
                  CountRow(
                    icon: Icons.add_circle_outline_rounded,
                    label: l10n.imexAddedLabel,
                    count: report.added,
                  ),
                  CountRow(
                    icon: Icons.skip_next_rounded,
                    label: l10n.imexAlreadyPresentLabel,
                    count: report.skipped,
                  ),
                  if (report.foldersAdded > 0)
                    CountRow(
                      icon: Icons.folder_rounded,
                      label: l10n.imexFoldersCreatedLabel,
                      count: report.foldersAdded,
                    ),
                  if (report.failed > 0)
                    CountRow(
                      icon: Icons.error_outline_rounded,
                      label: l10n.imexFailedRowsLabel,
                      count: report.failed,
                      danger: true,
                    ),
                ],
              ),
            ),
            if (report.failures.isNotEmpty) ...[
              const SizedBox(height: KeyelSpacing.sm),
              FailureList(failures: report.failures),
            ],
            const SizedBox(height: KeyelSpacing.lg),
            KeyelPillButton(
              label: l10n.actionDone,
              tone: KeyelButtonTone.neutral,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              l10n.imexVaultSaved,
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

/// Success sheet after an export, with a Share action.
class ExportSuccessSheet extends StatelessWidget {
  /// Creates the export-success sheet.
  const new({
    required this.title,
    required this.message,
    required this.unencrypted,
    super.key,
  });

  /// Heading.
  final String title;

  /// Where the file was written.
  final String message;

  /// Whether the exported file is unencrypted (shows a warning when true).
  final bool unencrypted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

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
                        l10n.imexUnencryptedWarning,
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
              label: l10n.actionShare,
              icon: Icons.ios_share_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            KeyelPillButton(
              label: l10n.actionClose,
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
