import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/folders_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/folders/folder_picker_sheet.dart';
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
              child: folders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(KeyelSpacing.xl),
                    child: Text(describeVaultError(error)),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _FoldersEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      KeyelSpacing.md,
                      KeyelSpacing.sm,
                      KeyelSpacing.md,
                      KeyelSpacing.xxl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KeyelSpacing.sm),
                    itemBuilder: (context, index) {
                      final folder = items[index];
                      return _FolderTile(
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

class _FolderTile extends StatelessWidget {
  const new({
    required this.folder,
    required this.onRename,
    required this.onDelete,
  });

  final FolderDto folder;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return KeyelSectionCard(
      showBorder: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryFixed,
              borderRadius: BorderRadius.circular(KeyelRadii.field),
            ),
            child: Icon(Icons.folder_rounded, color: scheme.onPrimaryFixed),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          KeyelIconHull(
            icon: Icons.edit_rounded,
            tooltip: 'Rename folder',
            onPressed: onRename,
            size: 40,
            iconSize: 20,
          ),
          KeyelIconHull(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete folder',
            onPressed: onDelete,
            foreground: scheme.error,
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _FoldersEmptyState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KeyelSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              'No folders yet',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KeyelSpacing.xs),
            Text(
              'Folders keep logins, cards and notes in tidy groups. Use the '
              'button below to create the first one.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
