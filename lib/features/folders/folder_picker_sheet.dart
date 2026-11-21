import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/folders_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Result of the folder picker. A `null` result means the sheet was dismissed.
class FolderSelection {
  /// Creates a selection; [id] is `null` for "No folder".
  const new(this.id);

  /// Selected folder id, or `null` for an unfiled entry.
  final String? id;
}

/// Opens the folder picker and returns the user's choice.
Future<FolderSelection?> showFolderPicker({
  required BuildContext context,
  required List<FolderDto> folders,
  required String? selectedId,
}) => showKeyelAdaptiveSheet<FolderSelection>(
  context: context,
  builder: (_) => FolderPickerSheet(folders: folders, selectedId: selectedId),
);

/// Bottom-sheet / side-sheet list of folders with inline creation.
class FolderPickerSheet extends ConsumerStatefulWidget {
  /// Creates the folder picker.
  const new({required this.folders, required this.selectedId, super.key});

  /// Available folders.
  final List<FolderDto> folders;

  /// Currently selected folder id, or `null` for "No folder".
  final String? selectedId;

  @override
  ConsumerState<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<FolderPickerSheet> {
  bool _busy = false;

  Future<void> _createFolder() async {
    final name = await _promptFolderName(
      context,
      title: l10nOf(context).fldNewFolder,
    );
    if (name == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final id = await ref.read(vaultRepositoryProvider).addFolder(name);
      ref.invalidate(foldersProvider);
      if (!mounted) return;
      Navigator.of(context).pop(FolderSelection(id));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KeyelSpacing.lg,
          KeyelSpacing.md,
          KeyelSpacing.lg,
          KeyelSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.folder_rounded, color: scheme.primary),
                const SizedBox(width: KeyelSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.fldMoveToFolder,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KeyelSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _FolderOption(
                      label: l10n.fldNoFolder,
                      icon: Icons.folder_off_rounded,
                      selected: widget.selectedId == null,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(const FolderSelection(null)),
                    ),
                    for (final folder in widget.folders)
                      _FolderOption(
                        label: folder.name,
                        icon: Icons.folder_rounded,
                        selected: widget.selectedId == folder.id,
                        onTap: () =>
                            Navigator.of(context)
                                .pop(FolderSelection(folder.id)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KeyelSpacing.md),
            KeyelPillButton(
              label: _busy ? l10n.fldCreating : l10n.fldNewFolder,
              icon: _busy ? null : Icons.create_new_folder_rounded,
              tone: KeyelButtonTone.neutral,
              height: 48,
              onPressed: _busy ? null : () => unawaited(_createFolder()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ask for a folder name, returning the trimmed value or `null` on cancel.
Future<String?> _promptFolderName(
  BuildContext context, {
  required String title,
  String initial = '',
}) async {
  final l10n = l10nOf(context);
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.fldFolderNameLabel),
        onSubmitted: (value) {
          final name = value.trim();
          if (name.isNotEmpty) Navigator.of(dialogContext).pop(name);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) Navigator.of(dialogContext).pop(name);
          },
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Shared prompt used by the picker and the folders screen.
Future<String?> promptFolderName(
  BuildContext context, {
  required String title,
  String initial = '',
}) => _promptFolderName(context, title: title, initial: initial);

class _FolderOption extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.field),
      semanticLabel: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: KeyelSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: KeyelSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: KeyelSpacing.sm + 4),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 20, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
