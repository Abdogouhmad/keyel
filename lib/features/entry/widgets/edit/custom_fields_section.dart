import 'package:flutter/material.dart';

import 'package:keyel/features/entry/entry_edit_controller.dart';
import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Editor section for user-defined custom fields.
class CustomFieldsSection extends StatelessWidget {
  /// Creates the custom-fields editor section.
  const new({required this.controller, super.key});

  /// Entry editor controller owning the custom-fields state.
  final EntryEditController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final fields = controller.customFields;

    return EditSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.xs),
              Text(
                l10n.entryCustomFields,
                style: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
              ),
              const Spacer(),
              _AddFieldButton(onAdd: controller.addCustomField),
            ],
          ),
          if (fields.isEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm),
            Text(
              l10n.entryCustomFieldsHint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: KeyelSpacing.sm),
            for (var i = 0; i < fields.length; i++) ...[
              _CustomFieldEditorRow(
                key: ValueKey('${fields[i].id ?? 'new'}-$i'),
                index: i,
                field: fields[i],
                controller: controller,
              ),
              if (i != fields.length - 1)
                const SizedBox(height: KeyelSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  const new({required this.onAdd});
  final void Function(CustomFieldKindDto kind) onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return PopupMenuButton<CustomFieldKindDto>(
      tooltip: l10n.entryAddCustomField,
      onSelected: onAdd,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: CustomFieldKindDto.text,
          child: Text(l10n.entryFieldTypeText),
        ),
        PopupMenuItem(
          value: CustomFieldKindDto.hidden,
          child: Text(l10n.entryFieldTypeHidden),
        ),
        PopupMenuItem(
          value: CustomFieldKindDto.url,
          child: Text(l10n.entryFieldTypeUrl),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.sm,
          vertical: KeyelSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(KeyelRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.actionAdd,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFieldEditorRow extends StatefulWidget {
  const new({
    required this.index,
    required this.field,
    required this.controller,
    super.key,
  });

  final int index;
  final CustomFieldDraft field;
  final EntryEditController controller;

  @override
  State<_CustomFieldEditorRow> createState() => _CustomFieldEditorRowState();
}

class _CustomFieldEditorRowState extends State<_CustomFieldEditorRow> {
  late final TextEditingController _label;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.field.label);
    _value = TextEditingController(text: widget.field.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _CustomFieldEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.label != widget.field.label &&
        _label.text != widget.field.label) {
      _label.text = widget.field.label;
    }
    final nextValue = widget.field.value ?? '';
    if (oldWidget.field.value != widget.field.value &&
        _value.text != nextValue) {
      _value.text = nextValue;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  void _commit({String? label, String? value, CustomFieldKindDto? kind}) {
    final nextKind = kind ?? widget.field.kind;
    var nextValue =
        value ??
        (nextKind == CustomFieldKindDto.hidden
            ? widget.field.value
            : _value.text);
    if (nextKind != CustomFieldKindDto.hidden) {
      nextValue = value ?? _value.text;
    } else {
      // Hidden: keep existing preserved value (null) unless user explicitly typed something.
      if (value != null) {
        nextValue = value.isEmpty ? null : value;
      } else if (kind == CustomFieldKindDto.hidden &&
          widget.field.kind != CustomFieldKindDto.hidden) {
        nextValue = null;
      }
    }
    widget.controller.updateCustomField(
      widget.index,
      CustomFieldDraft(
        id: widget.field.id,
        label: label ?? _label.text,
        kind: nextKind,
        value: nextValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);
    final isHidden = widget.field.kind == CustomFieldKindDto.hidden;
    final preserved =
        isHidden && widget.field.value == null && widget.field.id != null;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _label,
                  decoration: InputDecoration(
                    labelText: l10n.entryFieldLabel,
                    isDense: true,
                  ),
                  onChanged: (v) => _commit(label: v),
                ),
              ),
              const SizedBox(width: KeyelSpacing.xs),
              PopupMenuButton<String>(
                tooltip: l10n.entryFieldActions,
                onSelected: (action) {
                  switch (action) {
                    case 'text':
                      _commit(
                        kind: CustomFieldKindDto.text,
                        value: widget.field.value ?? _value.text,
                      );
                    case 'hidden':
                      _commit(kind: CustomFieldKindDto.hidden);
                    case 'url':
                      _commit(
                        kind: CustomFieldKindDto.url,
                        value: widget.field.value ?? _value.text,
                      );
                    case 'up':
                      widget.controller.reorderCustomField(
                        widget.index,
                        widget.index - 1,
                      );
                    case 'down':
                      widget.controller.reorderCustomField(
                        widget.index,
                        widget.index + 2,
                      );
                    case 'remove':
                      widget.controller.removeCustomField(widget.index);
                  }
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    checked: widget.field.kind == CustomFieldKindDto.text,
                    value: 'text',
                    child: Text(l10n.entryFieldTypeTextShort),
                  ),
                  CheckedPopupMenuItem(
                    checked: widget.field.kind == CustomFieldKindDto.hidden,
                    value: 'hidden',
                    child: Text(l10n.entryFieldTypeHiddenShort),
                  ),
                  CheckedPopupMenuItem(
                    checked: widget.field.kind == CustomFieldKindDto.url,
                    value: 'url',
                    child: Text(l10n.entryFieldTypeUrlShort),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'up', child: Text(l10n.entryMoveUp)),
                  PopupMenuItem(value: 'down', child: Text(l10n.entryMoveDown)),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(l10n.actionRemove),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.xs),
          TextField(
            controller: _value,
            obscureText: isHidden,
            enableSuggestions: !isHidden,
            autocorrect: !isHidden,
            keyboardType: widget.field.kind == CustomFieldKindDto.url
                ? TextInputType.url
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: switch (widget.field.kind) {
                CustomFieldKindDto.hidden => l10n.entryValueSecret,
                CustomFieldKindDto.url => l10n.entryFieldTypeUrlShort,
                CustomFieldKindDto.text => l10n.entryValue,
              },
              hintText: preserved ? l10n.entrySavedSecurelyHint : null,
              isDense: true,
            ),
            onChanged: (v) => _commit(value: v),
          ),
          if (preserved)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.entryHiddenValueKept,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
