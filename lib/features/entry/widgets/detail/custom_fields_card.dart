import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Renders user-defined custom fields on the entry detail screen.
class CustomFieldsCard extends StatelessWidget {
  /// Creates the custom fields card.
  const new({
    required this.fields,
    required this.revealedValues,
    required this.onToggleReveal,
    required this.onCopyField,
    required this.onOpenUrl,
    super.key,
  });

  /// Custom fields in display order.
  final List<CustomFieldDetailDto> fields;

  /// Revealed hidden values keyed by custom-field id.
  final Map<String, String> revealedValues;

  /// Reveals or hides a hidden custom field.
  final void Function(String fieldId) onToggleReveal;

  /// Copies a custom-field value (handles hidden reveal as needed).
  final void Function(CustomFieldDetailDto field) onCopyField;

  /// Opens a URL value in the default external app.
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return KeyelSectionCard(
      title: 'Custom fields',
      icon: Icons.tune_rounded,
      showBorder: true,
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            _CustomFieldRow(
              field: fields[i],
              revealedValue: revealedValues[fields[i].id],
              onToggleReveal: () => onToggleReveal(fields[i].id),
              onCopy: () => onCopyField(fields[i]),
              onOpenUrl: onOpenUrl,
            ),
            if (i != fields.length - 1)
              const SizedBox(height: KeyelSpacing.sm + 4),
          ],
        ],
      ),
    );
  }
}

class _CustomFieldRow extends StatelessWidget {
  const new({
    required this.field,
    required this.revealedValue,
    required this.onToggleReveal,
    required this.onCopy,
    required this.onOpenUrl,
  });

  final CustomFieldDetailDto field;
  final String? revealedValue;
  final VoidCallback onToggleReveal;
  final VoidCallback onCopy;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = field.label.trim().isEmpty ? 'Field' : field.label.trim();

    switch (field.kind) {
      case CustomFieldKindDto.hidden:
        final revealed = revealedValue != null;
        return KeyelFieldSurface(
          label: label,
          trailing: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(KeyelRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyelIconHull(
                  icon: revealed
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  tooltip: revealed ? 'Hide value' : 'Reveal value',
                  onPressed: field.hasHiddenValue ? onToggleReveal : null,
                  size: 44,
                  iconSize: 20,
                ),
                KeyelIconHull(
                  icon: Icons.content_copy_rounded,
                  tooltip: 'Copy value',
                  onPressed: field.hasHiddenValue ? onCopy : null,
                  foreground: scheme.primary,
                  size: 44,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          child: Text(
            revealed ? revealedValue! : _masked(field.hasHiddenValue),
            style: revealed
                ? KeyelTheme.mono(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )
                : textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
          ),
        );
      case CustomFieldKindDto.url:
        final value = field.value.trim();
        return KeyelFieldSurface(
          label: label,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyelIconHull(
                icon: Icons.open_in_new_rounded,
                tooltip: 'Open URL',
                onPressed: value.isEmpty ? null : () => onOpenUrl(value),
                background: scheme.surfaceContainerHighest,
              ),
              const SizedBox(width: KeyelSpacing.xs),
              KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy URL',
                onPressed: value.isEmpty ? null : onCopy,
                background: scheme.surfaceContainerHighest,
              ),
            ],
          ),
          child: SelectableText(
            value.isEmpty ? '—' : value,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case CustomFieldKindDto.text:
        final value = field.value;
        return KeyelFieldSurface(
          label: label,
          trailing: KeyelIconHull(
            icon: Icons.content_copy_rounded,
            tooltip: 'Copy value',
            onPressed: value.isEmpty ? null : onCopy,
            background: scheme.surfaceContainerHighest,
          ),
          child: SelectableText(
            value.isEmpty ? '—' : value,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  String _masked(bool hasValue) => hasValue ? '••••••••' : '—';
}
