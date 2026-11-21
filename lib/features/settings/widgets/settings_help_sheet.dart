import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// One entry in the local help sheet: a glyph, a heading and one-line copy.
@immutable
class HelpTopic {
  /// Creates a help topic.
  const new({required this.icon, required this.title, required this.body});

  /// Leading glyph.
  final IconData icon;

  /// Short heading.
  final String title;

  /// One or two sentences of accurate, local copy.
  final String body;
}

/// Shows the local, offline help sheet. There is no remote documentation and
/// therefore nothing to load — every topic is accurate for this build.
Future<void> showSettingsHelpSheet(BuildContext context) =>
    showKeyelAdaptiveSheet<void>(
      context: context,
      builder: (sheetContext) => const _HelpSheet(),
    );

class _HelpSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final topics = [
      HelpTopic(
        icon: Icons.lock_rounded,
        title: l10n.prefHelpVaultLocalTitle,
        body: l10n.prefHelpVaultLocalBody,
      ),
      HelpTopic(
        icon: Icons.lock_clock_rounded,
        title: l10n.prefHelpAutoLockTitle,
        body: l10n.prefHelpAutoLockBody,
      ),
      HelpTopic(
        icon: Icons.keyboard_rounded,
        title: l10n.prefHelpKeyboardTitle,
        body: l10n.prefHelpKeyboardBody,
      ),
      HelpTopic(
        icon: Icons.restore_rounded,
        title: l10n.prefHelpRecoveryTitle,
        body: l10n.prefHelpRecoveryBody,
      ),
    ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KeyelSpacing.lg,
                KeyelSpacing.md,
                KeyelSpacing.lg,
                KeyelSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.prefHelpSheetTitle,
                      style: textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  KeyelIconHull(
                    icon: Icons.close_rounded,
                    tooltip: l10n.actionClose,
                    size: 40,
                    iconSize: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.xs,
                  KeyelSpacing.lg,
                  KeyelSpacing.lg,
                ),
                child: Column(
                  children: [
                    for (final topic in topics)
                      Padding(
                        padding: const EdgeInsets.only(bottom: KeyelSpacing.sm),
                        child: _HelpRow(topic: topic),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const new({required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(
              topic.icon,
              color: scheme.onSecondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.body,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
