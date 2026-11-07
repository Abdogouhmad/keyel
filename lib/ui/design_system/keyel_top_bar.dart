import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/keyel_buttons.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// The shared Keyel top app bar: a tonal icon hull, a page title and an
/// optional trailing action.
class KeyelTopBar extends StatelessWidget {
  /// Creates a top app bar.
  const new({
    required this.title,
    required this.icon,
    this.trailing,
    this.onIconTap,
    super.key,
  });

  /// Page title.
  final String title;

  /// Leading glyph shown inside a circular tonal hull.
  final IconData icon;

  /// Optional action aligned to the end.
  final Widget? trailing;

  /// Handler for the leading hull.
  final VoidCallback? onIconTap;

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
              icon: icon,
              tooltip: title,
              onPressed: onIconTap,
              background: scheme.secondaryContainer,
              foreground: scheme.primary,
              size: 40,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
