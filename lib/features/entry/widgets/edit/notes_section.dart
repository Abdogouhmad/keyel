import 'package:flutter/material.dart';

import 'package:keyel/features/entry/widgets/edit/section.dart';

/// Multi-line secure notes field.
class NotesSection extends StatelessWidget {
  /// Creates the notes section.
  const new({
    required this.controller,
    required this.minLines,
    required this.label,
    super.key,
  });

  /// Controller for the notes field.
  final TextEditingController controller;

  /// Minimum visible lines of the notes field.
  final int minLines;

  /// Label shown on the notes field.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return EditSection(
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          hintText: 'Recovery questions, PIN codes, backup seeds...',
          suffixIcon: Icon(
            Icons.lock_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
