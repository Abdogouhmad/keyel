import 'package:flutter/material.dart';

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

/// Centered informational state for the autofill picker.
class AutofillCenteredNote extends StatelessWidget {
  /// Creates a centered note.
  const new({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Title text.
  final String title;

  /// Supporting text.
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KeyelSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
