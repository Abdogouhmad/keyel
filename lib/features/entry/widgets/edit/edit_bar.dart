import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Top bar of the entry editor with close and save actions.
class EditBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.title,
    required this.onClose,
    required this.onSave,
    super.key,
  });

  /// Title shown next to the close button.
  final String title;

  /// Called when the close button is tapped.
  final VoidCallback onClose;

  /// Called when the save button is tapped.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
        child: Row(
          children: [
            KeyelIconHull(
              icon: Icons.close_rounded,
              tooltip: l10nOf(context).actionClose,
              onPressed: onClose,
              foreground: scheme.onSurface,
            ),
            const SizedBox(width: KeyelSpacing.xs),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: KeyelSpacing.sm),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            KeyelPillButton(
              label: l10nOf(context).actionSave,
              height: 40,
              expand: false,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}
