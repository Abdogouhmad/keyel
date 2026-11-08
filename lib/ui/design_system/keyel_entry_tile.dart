import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/keyel_avatar.dart';
import 'package:keyel/ui/design_system/pressable_scale.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// A credential row in a vault list: shape avatar, title and subtitle
/// with a favourite star and a TOTP hint (design spec 8.x).
class KeyelEntryTile extends StatelessWidget {
  /// Creates an entry tile.
  const new({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.favorite = false,
    this.hasTotp = false,
    this.onLongPress,
    this.margin = const EdgeInsets.symmetric(
      horizontal: KeyelSpacing.lg,
      vertical: KeyelSpacing.xs,
    ),
    super.key,
  });

  /// Stable entry id driving the avatar shape.
  final String id;

  /// Entry title.
  final String title;

  /// Secondary line — username, URL or brand. Never a password.
  final String subtitle;

  /// Service glyph inside the avatar.
  final IconData icon;

  /// Open the entry.
  final VoidCallback onTap;

  /// Whether the entry is a favourite.
  final bool favorite;

  /// Whether a TOTP code is configured (renders the porthole badge).
  final bool hasTotp;

  /// Long-press, used for selection mode.
  final VoidCallback? onLongPress;

  /// Outer margins, loosened inside slivers or sheets.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(KeyelRadii.card),
      semanticLabel: '$title, $subtitle',
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(KeyelSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KeyelRadii.card),
        ),
        child: Row(
          children: [
            KeyelStableAvatar(id: id, icon: icon),
            const SizedBox(width: KeyelSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hasTotp) ...[
              const SizedBox(width: KeyelSpacing.sm),
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
            if (favorite) ...[
              const SizedBox(width: KeyelSpacing.sm),
              Icon(
                Icons.star_rounded,
                size: 20,
                color: scheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
