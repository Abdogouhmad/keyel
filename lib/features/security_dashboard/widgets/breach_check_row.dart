import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/breach_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/security_dashboard/widgets/audit_surface.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
    final l10n = l10nOf(context);
    final enabled = ref.watch(breachOptInProvider);
    final check = ref.watch(breachCheckProvider);
    final unlocked =
        ref.watch(vaultSessionProvider.select((state) => state.status)) ==
        VaultStatus.unlocked;
    // Rust clears pending digests on lock; mirror that in the UI and cancel any
    // in-flight fetch so a late response cannot repopulate the result.
    ref.listen(vaultSessionProvider.select((state) => state.status), (
      _,
      status,
    ) {
      if (status != VaultStatus.unlocked) {
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
                          l10n.secBreachCheck,
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        KeyelBadge(
                          label: _badge(context, enabled, check),
                          compact: true,
                          background: scheme.strongContainer,
                          foreground: scheme.onStrongContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled
                          ? l10n.secBreachEnabledNotice
                          : l10n.secBreachDisabledNotice,
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
                    l10n.secEnableBreachCheck,
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Semantics(
                  label: l10n.secEnableBreachCheck,
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
                        ? l10n.secChecking
                        : l10n.secCheckNow,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => unawaited(
                    ref.read(breachOptInProvider.notifier).set(enabled: false),
                  ),
                  icon: const Icon(Icons.toggle_off_outlined),
                  label: Text(l10n.secTurnOff),
                ),
              ],
            ),
          if (enabled && !unlocked)
            Padding(
              padding: const EdgeInsets.only(top: KeyelSpacing.xs),
              child: Text(
                l10n.secUnlockToCheck,
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

  String _badge(BuildContext context, bool enabled, BreachCheckState check) {
    final l10n = l10nOf(context);
    if (!enabled) return l10n.secOff;
    return switch (check.status) {
      BreachCheckStatus.running => l10n.secBadgeChecking,
      BreachCheckStatus.failed => l10n.secError,
      BreachCheckStatus.done when check.report?.matches.isEmpty ?? false =>
        l10n.actionClear,
      BreachCheckStatus.done when check.report != null => l10n.secFoundCount(
        check.report!.matches.length,
      ),
      _ => l10n.secReady,
    };
  }

  Future<void> _confirmEnable(BuildContext context, WidgetRef ref) async {
    final l10n = l10nOf(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.secSendHashDialogTitle),
        content: Text(l10n.secSendHashDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.secTurnOn),
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
    final l10n = l10nOf(context);

    if (check.status == BreachCheckStatus.failed) {
      return Padding(
        padding: const EdgeInsets.only(top: KeyelSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              check.error ?? l10n.secBreachCheckFailed,
              style: textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
            TextButton(
              onPressed: () =>
                  unawaited(ref.read(breachCheckProvider.notifier).run()),
              child: Text(l10n.actionRetry),
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
                ? l10n.secNoExposedPasswords
                : l10n.secSavedPasswordsFound(matches.length),
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
          for (final match in matches.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.secExposures(
                  match.entryTitle,
                  l10n.secExposureCount(match.count),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (matches.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.secMoreMatches(matches.length - 3),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            l10n.secCheckedSummary(
              l10n.secPasswordCount(report.checkedCount),
              l10n.secPrefixCount(report.queriedPrefixes),
            ),
            style: textTheme.labelSmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
