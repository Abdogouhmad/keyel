import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/health_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/security_dashboard/health_category.dart';
import 'package:keyel/features/security_dashboard/widgets/health_issue_sheet.dart';
import 'package:keyel/features/security_dashboard/widgets/score_card.dart';
import 'package:keyel/features/security_dashboard/widgets/security_posture_card.dart';
import 'package:keyel/features/security_dashboard/widgets/security_tip_card.dart';
import 'package:keyel/features/security_dashboard/widgets/vulnerability_audit_section.dart';
import 'package:keyel/features/security_dashboard/widgets/vulnerability_summary.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Security dashboard screen — vault health at a glance.
class SecurityScreen extends ConsumerWidget {
  /// Creates the security screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final health = ref.watch(healthProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Security Health',
              icon: Icons.shield_rounded,
              trailing: KeyelIconHull(
                icon: Icons.lock_rounded,
                tooltip: 'Lock vault',
                onPressed: () {
                  ref.read(vaultSessionProvider.notifier).lock();
                  showKeyelSnack(
                    context,
                    'Vault locked',
                    icon: Icons.lock_rounded,
                  );
                },
              ),
            ),
            Expanded(
              child: KeyelContent(
                child: health.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _HealthError(
                    message: describeVaultError(error),
                    onRetry: () => ref.invalidate(healthProvider),
                  ),
                  data: (report) => _Dashboard(
                    report: report,
                    onOpen: (category) =>
                        _openCategory(context, ref, report, category),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategory(
    BuildContext context,
    WidgetRef ref,
    HealthReportDto report,
    HealthCategory category,
  ) async {
    final id = await HealthIssueSheet.show(
      context,
      category: category,
      issues: issuesFor(report, category),
    );
    if (id == null || !context.mounted) return;
    await context.push(KeyelRoutes.entryEdit(id));
    ref.invalidate(healthProvider);
  }
}

class _Dashboard extends StatelessWidget {
  const new({required this.report, required this.onOpen});

  final HealthReportDto report;
  final ValueChanged<HealthCategory> onOpen;

  int get _issueCount => HealthCategory.values.fold<int>(
    0,
    (sum, category) => sum + countFor(report, category),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pageMargin,
        KeyelSpacing.xs,
        context.pageMargin,
        KeyelSpacing.xl,
      ),
      children: [
        // What the user can control right now, above the score that summarizes
        // the credentials themselves. Both read the same non-secret state.
        const SecurityPostureCardConnector(),
        const SizedBox(height: KeyelSpacing.lg),
        ScoreCard(
          score: report.score,
          issueCount: _issueCount,
          onOptimize: () {
            final primary = primaryCategory(report);
            if (primary != null) onOpen(primary);
          },
        ),
        const SizedBox(height: KeyelSpacing.lg),
        VulnerabilitySummarySection(report: report, onOpen: onOpen),
        const SizedBox(height: KeyelSpacing.lg),
        VulnerabilityAuditSection(
          insecureCount: report.insecureUrl.length,
          onFixSites: () => onOpen(HealthCategory.insecureUrl),
        ),
        const SizedBox(height: KeyelSpacing.md),
        const SecurityTipCard(),
        const SizedBox(height: KeyelSpacing.md),
      ],
    );
  }
}

class _HealthError extends StatelessWidget {
  const new({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KeyelSpacing.md),
            KeyelPillButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              tone: KeyelButtonTone.neutral,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
