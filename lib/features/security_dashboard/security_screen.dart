import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/security_dashboard/widgets/score_card.dart';
import 'package:keyel/features/security_dashboard/widgets/security_tip_card.dart';
import 'package:keyel/features/security_dashboard/widgets/vulnerability_audit_section.dart';
import 'package:keyel/features/security_dashboard/widgets/vulnerability_summary.dart';
import 'package:keyel/ui/keyel.dart';

/// Security dashboard screen — vault health at a glance.
class SecurityScreen extends ConsumerWidget {
  /// Creates the security screen.
  const new({super.key});

  void _notYet(BuildContext context, String feature) {
    showKeyelSnack(
      context,
      '$feature arrives with the vault analyser.',
      icon: Icons.auto_fix_high_rounded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      KeyelSpacing.md,
                      KeyelSpacing.xs,
                      KeyelSpacing.md,
                      KeyelSpacing.xl,
                    ),
                    children: [
                      ScoreCard(onOptimize: () => _notYet(context, 'Auto-fix')),
                      const SizedBox(height: KeyelSpacing.lg),
                      VulnerabilitySummarySection(
                        onFeatureTap: (feature) => _notYet(context, feature),
                      ),
                      const SizedBox(height: KeyelSpacing.lg),
                      VulnerabilityAuditSection(
                        onFixSites: () => _notYet(context, 'Website fixes'),
                      ),
                      const SizedBox(height: KeyelSpacing.md),
                      const SecurityTipCard(),
                      const SizedBox(height: KeyelSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
