import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
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
    final textTheme = Theme.of(context).textTheme;

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
                  _ScoreCard(onOptimize: () => _notYet(context, 'Auto-fix')),
                  const SizedBox(height: KeyelSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Vulnerability summary',
                          style: textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '4 categories',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.sm + 4),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: KeyelSpacing.sm + 4,
                    mainAxisSpacing: KeyelSpacing.sm + 4,
                    childAspectRatio: 1.04,
                    children: [
                      _IssueCard(
                        background: scheme.weakContainer,
                        content: scheme.onWeakContainer,
                        accent: scheme.weak,
                        countColor: scheme.onWeakContainer,
                        icon: Icons.error_rounded,
                        count: 2,
                        title: 'Weak passwords',
                        subtitle: 'High compromise risk',
                        actionLabel: 'Fix now',
                        onAction: () => _notYet(context, 'Weak-password fixes'),
                      ),
                      _IssueCard(
                        background: scheme.fairContainer,
                        content: scheme.onFairContainer,
                        accent: scheme.fair,
                        countColor: scheme.onFairContainer,
                        icon: Icons.sync_rounded,
                        count: 4,
                        title: 'Reused passwords',
                        subtitle: 'Shared across services',
                        actionLabel: 'Review',
                        onAction: () => _notYet(context, 'Reuse review'),
                      ),
                      _IssueCard(
                        background: scheme.surfaceContainer,
                        content: scheme.onSurface,
                        accent: scheme.secondaryContainer,
                        accentContent: scheme.onSecondaryContainer,
                        countColor: scheme.onSurface,
                        icon: Icons.history_rounded,
                        count: 11,
                        title: 'Old passwords',
                        subtitle: 'More than 1 year old',
                        actionLabel: 'Update',
                        actionBackground: scheme.surfaceContainerHigh,
                        actionForeground: scheme.onSurface,
                        onAction: () => _notYet(context, 'Password rotation'),
                      ),
                      _IssueCard(
                        background: scheme.secondaryContainer,
                        content: scheme.onSurface,
                        accent: scheme.primary,
                        accentContent: scheme.onPrimary,
                        countColor: scheme.onSecondaryContainer,
                        icon: Icons.shield_rounded,
                        count: 9,
                        title: 'Missing 2FA',
                        subtitle: 'TOTP supported',
                        actionLabel: 'Add codes',
                        onAction: () => _notYet(context, '2FA setup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Vulnerability audit',
                          style: textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.manage_search_rounded,
                        size: 20,
                        color: scheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: KeyelSpacing.sm + 4),
                  Container(
                    padding: const EdgeInsets.all(KeyelSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(KeyelRadii.card),
                    ),
                    child: Column(
                      children: [
                        _InsecureSiteRow(
                          onFix: () => _notYet(context, 'Website fixes'),
                        ),
                        const SizedBox(height: KeyelSpacing.sm),
                        const _BreachCheckRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(KeyelSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(KeyelRadii.tile),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            size: 20,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: KeyelSpacing.sm + 4),
                        Expanded(
                          child: Text(
                            'Enable biometric lock for instantaneous vault '
                            'unmasking using your device secure enclave.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

class _ScoreCard extends StatelessWidget {
  const new({required this.onOptimize});

  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.lg - 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Column(
        children: [
          _ScoreGauge(
            score: 88,
            accent: scheme.strong,
            track: scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: KeyelSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KeyelSpacing.sm + 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(KeyelRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.strong,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Text(
                  'Vault health: Good',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Text(
            '4 items need your attention to reach 100%',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          KeyelPillButton(
            label: 'Optimize vault',
            icon: Icons.auto_fix_high_rounded,
            height: 52,
            onPressed: onOptimize,
          ),
        ],
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  const new({required this.score, required this.accent, required this.track});

  final int score;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 158,
            height: 158,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          CustomPaint(
            size: const Size.square(160),
            painter: _GaugePainter(
              progress: score / 100,
              accent: accent,
              track: track,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: KeyelTheme.mono(
                      context,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: KeyelSpacing.xs),
                  Text(
                    '/ 100',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 15, color: accent),
                  const SizedBox(width: KeyelSpacing.xs),
                  Text(
                    'SECURE',
                    style: textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const new({
    required this.progress,
    required this.accent,
    required this.track,
  });

  final double progress;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawArc(rect, 0, 2 * math.pi, false, trackPaint)
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        accentPaint,
      );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}

class _IssueCard extends StatelessWidget {
  const new({
    required this.background,
    required this.content,
    required this.accent,
    required this.countColor,
    required this.icon,
    required this.count,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.accentContent,
    this.actionBackground,
    this.actionForeground,
  });

  final Color background;
  final Color content;
  final Color accent;
  final Color countColor;
  final Color? accentContent;
  final IconData icon;
  final int count;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Color? actionBackground;
  final Color? actionForeground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KeyelRadii.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: accentContent ?? Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$count',
                style: KeyelTheme.mono(
                  context,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: content,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: content.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          _MiniButton(
            label: actionLabel,
            background: actionBackground ?? accent,
            foreground: actionForeground ?? Colors.white,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const new({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.pill),
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(KeyelRadii.pill),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelWidget = Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            );

            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // In a constrained card the label may ellipsize; in the
                // audit row the button is a non-flex child of a Row and gets
                // unbounded width, where Flexible would assert.
                if (constraints.hasBoundedWidth)
                  Flexible(child: labelWidget)
                else
                  labelWidget,
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: foreground),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuditSurface extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.sm + 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _InsecureSiteRow extends StatelessWidget {
  const new({required this.onFix});

  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _AuditSurface(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.no_encryption_rounded,
              size: 22,
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Insecure websites (HTTP)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: KeyelSpacing.sm),
                    KeyelBadge(
                      label: '1',
                      compact: true,
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Credentials sent in plain text',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm),
          _MiniButton(
            label: 'Fix',
            background: scheme.surfaceContainer,
            foreground: scheme.primary,
            onTap: onFix,
          ),
        ],
      ),
    );
  }
}

class _BreachCheckRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _AuditSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: scheme.strongContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 22,
              color: scheme.strong,
            ),
          ),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Offline breach check',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    KeyelBadge(
                      label: 'Pass',
                      compact: true,
                      background: scheme.strongContainer,
                      foreground: scheme.onStrongContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'No credentials found in known breach databases '
                  '(local bloom filter).',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.sync_rounded, size: 14, color: scheme.outline),
                    const SizedBox(width: KeyelSpacing.xs),
                    Expanded(
                      child: Text(
                        'Database sync: Today, 08:30 AM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
