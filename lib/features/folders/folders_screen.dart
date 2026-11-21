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
import 'package:keyel/ui/l10n/l10n.dart';

/// Create, rename and delete folders used to organise vault entries.
class FoldersScreen extends ConsumerWidget {
  /// Creates the folders screen.
  const new({super.key});

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final name = await promptFolderName(
      context,
      title: l10nOf(context).fldNewFolder,
    );
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
      title: l10nOf(context).fldRenameFolder,
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
    final l10n = l10nOf(context);
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.fldDeleteConfirmTitle(folder.name),
      body: l10n.fldDeleteConfirmBody,
      confirmLabel: l10n.fldDeleteFolder,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(vaultRepositoryProvider).deleteFolder(folder.id);
      ref.invalidate(foldersProvider);
      if (!context.mounted) return;
      showKeyelSnack(
        context,
        l10n.fldDeleted,
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
    final l10n = l10nOf(context);
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: l10n.foldersTitle,
              icon: Icons.arrow_back_rounded,
              iconTooltip: l10n.actionBack,
              onIconTap: () => context.pop(),
              trailing: KeyelIconHull(
                icon: Icons.create_new_folder_rounded,
                tooltip: l10n.fldNewFolder,
                onPressed: () => unawaited(_addFolder(context, ref)),
              ),
            ),
            Expanded(
              child: KeyelContent(
                child: folders.when(
                  loading: () => KeyelStateMessage(
                    kind: KeyelStateMessageKind.loading,
                    message: l10n.fldLoading,
                  ),
                  error: (error, _) => KeyelStateMessage(
                    kind: KeyelStateMessageKind.error,
                    message: describeVaultError(error),
                    actionLabel: l10n.actionRetry,
                    onAction: () => ref.invalidate(foldersProvider),
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
        label: Text(l10n.fldNewFolder),
      ),
    );
  }
}
