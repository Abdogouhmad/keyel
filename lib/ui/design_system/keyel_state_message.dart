import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/keyel_buttons.dart';
import 'package:keyel/ui/design_system/keyel_surfaces.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// The tone of a [KeyelStateMessage].
enum KeyelStateMessageKind {
  /// A task is still running; a progress indicator is shown.
  loading,

  /// There is nothing to show yet.
  empty,

  /// A load or action failed; an optional retry is offered.
  error,
}

/// One shared loading / empty / error state for everyday screens.
///
/// Uses only existing Keyel tokens and widgets, so it follows the active
/// palette, AMOLED and high-contrast themes automatically. It scrolls when the
/// available height is too small, which keeps it usable at 200 % text scale,
/// and has no custom animation, so it trivially respects reduced motion.
class KeyelStateMessage extends StatelessWidget {
  /// Creates a state message.
  const new({
    required this.kind,
    required this.message,
    this.title,
    this.icon,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
    super.key,
  });

  /// Which state is being shown.
  final KeyelStateMessageKind kind;

  /// Human-readable explanation of the state.
  final String message;

  /// Optional short heading shown above [message].
  final String? title;

  /// Optional glyph; defaults to a kind-appropriate icon.
  final IconData? icon;

  /// Label for the optional action button (usually "Retry").
  final String? actionLabel;

  /// Glyph for the optional action button.
  final IconData actionIcon;

  /// Handler for the optional action button. When null, no button is shown.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final glyph =
        icon ??
        switch (kind) {
          KeyelStateMessageKind.loading => Icons.hourglass_empty_rounded,
          KeyelStateMessageKind.empty => Icons.inbox_rounded,
          KeyelStateMessageKind.error => Icons.error_outline_rounded,
        };
    final glyphColor = kind == KeyelStateMessageKind.error
        ? scheme.error
        : scheme.primary;

    final action = onAction == null || actionLabel == null
        ? null
        : KeyelPillButton(
            label: actionLabel!,
            icon: actionIcon,
            tone: KeyelButtonTone.tonal,
            height: 44,
            expand: false,
            onPressed: onAction,
          );

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: KeyelSectionCard(
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.lg,
          vertical: KeyelSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(KeyelRadii.tile),
              ),
              child: Icon(glyph, size: 28, color: glyphColor),
            ),
            const SizedBox(height: KeyelSpacing.md),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: KeyelSpacing.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (kind == KeyelStateMessageKind.loading) ...[
              const SizedBox(height: KeyelSpacing.md),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: KeyelSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(KeyelSpacing.lg),
              child: card,
            ),
          ),
        ),
      ),
    );
  }
}
