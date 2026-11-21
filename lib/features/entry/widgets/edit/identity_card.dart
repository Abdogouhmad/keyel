import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Avatar and title field block at the top of the editor.
class IdentityCard extends StatelessWidget {
  /// Creates the identity card.
  const new({
    required this.icon,
    required this.titleController,
    required this.onIconTap,
    super.key,
  });

  /// Glyph shown as the entry avatar.
  final IconData icon;

  /// Controller for the entry title field.
  final TextEditingController titleController;

  /// Called when the avatar change button is tapped.
  final VoidCallback onIconTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    return KeyelSectionCard(
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PressableScale(
                  onTap: onIconTap,
                  borderRadius: BorderRadius.circular(KeyelRadii.field),
                  semanticLabel: l10n.entryChangeIcon,
                  child: KeyelAvatar(
                    icon: icon,
                    tone: KeyelAvatarTone.slate,
                    size: 64,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: PressableScale(
                    onTap: onIconTap,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                    semanticLabel: l10n.entryChangeIcon,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.entryTitleFieldLabel,
                hintText: l10n.entryTitleFieldHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
