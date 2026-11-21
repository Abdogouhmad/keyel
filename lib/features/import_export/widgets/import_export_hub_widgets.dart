import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Main content for the backup & import hub.
class ImportExportHubBody extends StatelessWidget {
  /// Creates the import/export hub body.
  const new({
    required this.busy,
    required this.onExportBackup,
    required this.onRestoreBackup,
    required this.onImportCsv,
    required this.onExportCsv,
    super.key,
  });

  /// Whether an import/export operation is in progress.
  final bool busy;

  /// Starts encrypted backup export.
  final VoidCallback onExportBackup;

  /// Starts encrypted backup restore.
  final VoidCallback onRestoreBackup;

  /// Starts CSV import.
  final VoidCallback onImportCsv;

  /// Starts plain CSV export.
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pageMargin,
        KeyelSpacing.sm,
        context.pageMargin,
        KeyelSpacing.xxl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: KeyelSpacing.md),
          child: Text(
            l10n.imexHubIntro,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        KeyelSectionLabel(
          label: l10n.imexEncryptedBackupSection,
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        KeyelSectionCard(
          child: Column(
            children: [
              ImportExportActionRow(
                icon: Icons.file_download_outlined,
                title: l10n.imexExportEncryptedTitle,
                subtitle: l10n.imexExportEncryptedSubtitle,
                enabled: !busy,
                onTap: onExportBackup,
              ),
              ImportExportActionRow(
                icon: Icons.restore_rounded,
                title: l10n.imexRestoreFromBackupTitle,
                subtitle: l10n.imexRestoreFromBackupSubtitle,
                enabled: !busy,
                onTap: onRestoreBackup,
              ),
            ],
          ),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        KeyelSectionLabel(
          label: l10n.importExportTitle,
          icon: Icons.swap_vert_rounded,
        ),
        const SizedBox(height: KeyelSpacing.sm),
        KeyelSectionCard(
          child: Column(
            children: [
              ImportExportActionRow(
                icon: Icons.upload_file_rounded,
                title: l10n.imexImportFromCsvTitle,
                subtitle: l10n.imexCsvImportSubtitle,
                enabled: !busy,
                onTap: onImportCsv,
              ),
              ImportExportActionRow(
                icon: Icons.file_upload_outlined,
                title: l10n.imexExportPlainCsvTitle,
                subtitle: l10n.imexExportPlainCsvSubtitle,
                danger: true,
                enabled: !busy,
                onTap: onExportCsv,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One tappable row inside the import/export hub.
class ImportExportActionRow extends StatelessWidget {
  /// Creates an import/export action row.
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.danger = false,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Supporting description.
  final String subtitle;

  /// Tap handler.
  final VoidCallback onTap;

  /// Whether the row is interactive.
  final bool enabled;

  /// Whether the action is destructive/sensitive.
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
