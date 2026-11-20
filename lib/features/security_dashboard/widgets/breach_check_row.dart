import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/breach_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/security_dashboard/widgets/audit_surface.dart';
import 'package:keyel/ui/keyel.dart';

/// Audit row for the opt-in HIBP breach check.
///
/// The row only shows state produced by Rust (entry titles and breach counts).
/// Switching it on requires an explicit disclosure; nothing is sent until the
/// user taps "Check now".
class BreachCheckRow extends ConsumerWidget {
  /// Creates the breach check row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = ref.watch(breachOptInProvider);
    final check = ref.watch(breachCheckProvider);
    final unlocked =
        ref.watch(vaultSessionProvider).status == VaultStatus.unlocked;
    // Rust clears pending digests on lock; mirror that in the UI and cancel any
    // in-flight fetch so a late response cannot repopulate the result.
    ref.listen(vaultSessionProvider, (previous, next) {
      if (next.status != VaultStatus.unlocked) {
        ref.read(breachCheckProvider.notifier).cancel();
      }
    });

    return AuditSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.gpp_good_rounded,
                  size: 22,
                  color: scheme.strong,
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: KeyelSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Breach check',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        KeyelBadge(
                          label: _badge(enabled, check),
                          compact: true,
                          background: scheme.strongContainer,
                          foreground: scheme.onStrongContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled
                          ? 'Only the first 5 characters of a SHA-1 hash are '
                                'sent over HTTPS when you tap Check now. '
                                'Passwords and vault data never leave this device.'
                          : 'Optional: check saved passwords against known '
                                'breaches. Nothing is sent unless you turn this '
                                'on and tap Check now.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm),
          if (!enabled)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Enable breach check',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Enable breach check',
                  child: Switch.adaptive(
                    value: false,
                    onChanged: (value) {
                      if (value) unawaited(_confirmEnable(context, ref));
                    },
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: KeyelSpacing.xs,
              runSpacing: KeyelSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed:
                      !unlocked || check.status == BreachCheckStatus.running
                      ? null
                      : () => unawaited(
                          ref.read(breachCheckProvider.notifier).run(),
                        ),
                  icon: check.status == BreachCheckStatus.running
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSecondaryContainer,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                    check.status == BreachCheckStatus.running
                        ? 'Checking…'
                        : 'Check now',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(
                    ref.read(breachOptInProvider.notifier).set(enabled: false),
                  ),
                  icon: const Icon(Icons.toggle_off_outlined),
                  label: const Text('Turn off'),
                ),
              ],
            ),
          if (enabled && !unlocked)
            Padding(
              padding: const EdgeInsets.only(top: KeyelSpacing.xs),
              child: Text(
                'Unlock the vault to check.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (enabled) _Result(check: check),
        ],
      ),
    );
  }

  String _badge(bool enabled, BreachCheckState check) {
    if (!enabled) return 'Off';
    return switch (check.status) {
      BreachCheckStatus.running => 'Checking',
      BreachCheckStatus.failed => 'Error',
      BreachCheckStatus.done when check.report?.matches.isEmpty ?? false =>
        'Clear',
      BreachCheckStatus.done when check.report != null =>
        '${check.report!.matches.length} found',
      _ => 'Ready',
    };
  }

  Future<void> _confirmEnable(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send hash prefixes to HIBP?'),
        content: const Text(
          'Keyel computes a SHA-1 hash of each saved password on this device '
          'and sends only the first 5 characters to Have I Been Pwned over '
          'HTTPS. Your passwords, usernames and vault are never sent. Checks '
          'run only when you tap Check now, and you can turn this off anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await ref.read(breachOptInProvider.notifier).set(enabled: true);
    }
  }
}

class _Result extends ConsumerWidget {
  const new({required this.check});

  final BreachCheckState check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (check.status == BreachCheckStatus.failed) {
      return Padding(
        padding: const EdgeInsets.only(top: KeyelSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              check.error ?? 'Breach check failed.',
              style: textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
            TextButton(
              onPressed: () =>
                  unawaited(ref.read(breachCheckProvider.notifier).run()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (check.status != BreachCheckStatus.done || check.report == null) {
      return const SizedBox.shrink();
    }

    final report = check.report!;
    final matches = report.matches;
    return Padding(
      padding: const EdgeInsets.only(top: KeyelSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            matches.isEmpty
                ? 'No exposed passwords found.'
                : '${matches.length} saved password'
                      '${matches.length == 1 ? '' : 's'} found in breaches:',
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
          for (final match in matches.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${match.entryTitle} · ${match.count} exposures',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (matches.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${matches.length - 3} more',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Checked ${report.checkedCount} '
            '${report.checkedCount == 1 ? 'password' : 'passwords'} across '
            '${report.queriedPrefixes} '
            '${report.queriedPrefixes == 1 ? 'prefix' : 'prefixes'}.',
            style: textTheme.labelSmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
