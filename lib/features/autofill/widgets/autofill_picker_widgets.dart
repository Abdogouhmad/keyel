import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

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
              'Some results are text matches only. Check that the login '
              'really belongs to $target before filling.',
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
      actionLabel: onRetry == null ? null : 'Retry',
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
    if (!unlocked) {
      return const AutofillCenteredNote(
        kind: KeyelStateMessageKind.empty,
        icon: Icons.lock_rounded,
        title: 'Vault locked',
        body: 'Unlock Keyel to fill this form.',
      );
    }
    if (error != null) {
      return AutofillCenteredNote(
        kind: KeyelStateMessageKind.error,
        icon: Icons.error_outline_rounded,
        title: 'Could not load matches',
        body: error!,
        onRetry: onRetry,
      );
    }
    if (loading) {
      return const KeyelStateMessage(
        kind: KeyelStateMessageKind.loading,
        message: 'Finding matching logins…',
      );
    }
    if (matches.isEmpty) {
      return const AutofillCenteredNote(
        kind: KeyelStateMessageKind.empty,
        icon: Icons.search_off_rounded,
        title: 'No matching logins',
        body: 'Create a new login for this app or site.',
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
