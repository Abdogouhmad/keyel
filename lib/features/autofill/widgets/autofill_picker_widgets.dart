import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Warning banner shown when only text-matched logins are available.
class AutofillMismatchBanner extends StatelessWidget {
  /// Creates a mismatch warning banner.
  const new({required this.target, super.key});

  /// Human-readable target app or site.
  final String target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        KeyelSpacing.lg,
        KeyelSpacing.sm,
        KeyelSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Text(
              l10n.autofillMismatchBody(target),
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

/// Centered note used for locked/error/empty picker states.
class AutofillCenteredNote extends StatelessWidget {
  /// Creates a centered note.
  const new({
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
    super.key,
  });

  /// Which state is being shown.
  final KeyelStateMessageKind kind;

  /// Leading icon.
  final IconData icon;

  /// Primary message.
  final String title;

  /// Supporting message.
  final String body;

  /// Optional retry handler; shows a Retry button when provided.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return KeyelStateMessage(
      kind: kind,
      icon: icon,
      title: title,
      message: body,
      actionLabel: onRetry == null ? null : l10nOf(context).actionRetry,
      onAction: onRetry,
    );
  }
}

/// Body of the autofill picker showing locked/error/loading/empty/list states.
class AutofillPickerBody extends StatelessWidget {
  /// Creates the picker body.
  const new({
    required this.unlocked,
    required this.loading,
    required this.matches,
    required this.onPick,
    this.error,
    this.onRetry,
    super.key,
  });

  /// Whether the vault is unlocked.
  final bool unlocked;

  /// Whether matches are loading.
  final bool loading;

  /// Current matches to display.
  final List<AutofillMatchDto> matches;

  /// Called when a match is chosen.
  final Future<void> Function(AutofillMatchDto match) onPick;

  /// Error message, if loading failed.
  final String? error;

  /// Optional retry handler for a failed load.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    if (!unlocked) {
      return AutofillCenteredNote(
        kind: KeyelStateMessageKind.empty,
        icon: Icons.lock_rounded,
        title: l10n.autofillVaultLocked,
        body: l10n.autofillUnlockToFill,
      );
    }
    if (error != null) {
      return AutofillCenteredNote(
        kind: KeyelStateMessageKind.error,
        icon: Icons.error_outline_rounded,
        title: l10n.autofillLoadError,
        body: error!,
        onRetry: onRetry,
      );
    }
    if (loading) {
      return KeyelStateMessage(
        kind: KeyelStateMessageKind.loading,
        message: l10n.autofillFindingMatches,
      );
    }
    if (matches.isEmpty) {
      return AutofillCenteredNote(
        kind: KeyelStateMessageKind.empty,
        icon: Icons.search_off_rounded,
        title: l10n.autofillNoMatches,
        body: l10n.autofillNoMatchesBody,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: KeyelSpacing.xs,
        bottom: KeyelSpacing.lg,
      ),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return KeyelEntryTile(
          id: match.summary.id,
          title: match.summary.title,
          subtitle: match.summary.subtitle,
          icon: Icons.key_rounded,
          favorite: match.summary.favorite,
          hasTotp: match.summary.hasTotp,
          onTap: () => unawaited(onPick(match)),
        );
      },
    );
  }
}
