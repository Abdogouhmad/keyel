import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/folders_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/folders/folder_picker_sheet.dart';
import 'package:keyel/features/folders/widgets/folders_widgets.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Create, rename and delete folders used to organise vault entries.
class FoldersScreen extends ConsumerWidget {
  /// Creates the folders screen.
  const new({super.key});

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final name = await promptFolderName(context, title: 'New folder');
    if (name == null) return;
    try {
      await ref.read(vaultRepositoryProvider).addFolder(name);
      ref.invalidate(foldersProvider);
    } on Object catch (error) {
      if (!context.mounted) return;
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _renameFolder(
    BuildContext context,
    WidgetRef ref,
    FolderDto folder,
  ) async {
    final name = await promptFolderName(
      context,
      title: 'Rename folder',
      initial: folder.name,
    );
    if (name == null || name == folder.name) return;
    try {
      await ref.read(vaultRepositoryProvider).renameFolder(folder.id, name);
      ref.invalidate(foldersProvider);
    } on Object catch (error) {
      if (!context.mounted) return;
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _deleteFolder(
    BuildContext context,
    WidgetRef ref,
    FolderDto folder,
  ) async {
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: 'Delete "${folder.name}"?',
      body: 'Entries in this folder are kept and move to "No folder".',
      confirmLabel: 'Delete folder',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(vaultRepositoryProvider).deleteFolder(folder.id);
      ref.invalidate(foldersProvider);
      if (!context.mounted) return;
      showKeyelSnack(
        context,
        'Folder deleted',
        icon: Icons.delete_outline_rounded,
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Folders',
              icon: Icons.arrow_back_rounded,
              onIconTap: () => context.pop(),
              trailing: KeyelIconHull(
                icon: Icons.create_new_folder_rounded,
                tooltip: 'New folder',
                onPressed: () => unawaited(_addFolder(context, ref)),
              ),
            ),
            Expanded(
              child: KeyelContent(
                child: folders.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(KeyelSpacing.xl),
                      child: Text(describeVaultError(error)),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const FoldersEmptyState();
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        context.pageMargin,
                        KeyelSpacing.sm,
                        context.pageMargin,
                        KeyelSpacing.xxl,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: KeyelSpacing.sm),
                      itemBuilder: (context, index) {
                        final folder = items[index];
                        return FolderTile(
                          folder: folder,
                          onRename: () =>
                              unawaited(_renameFolder(context, ref, folder)),
                          onDelete: () =>
                              unawaited(_deleteFolder(context, ref, folder)),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_addFolder(context, ref)),
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('New folder'),
      ),
    );
  }
}
