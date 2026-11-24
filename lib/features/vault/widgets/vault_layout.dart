import 'package:flutter/material.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/vault/widgets/new_entry_fab.dart';
import 'package:keyel/features/vault/widgets/vault_detail_placeholder.dart';
import 'package:keyel/ui/keyel.dart';

/// The main vault content, wide or narrow, depending on window size.
class VaultLayout extends StatelessWidget {
  /// Creates the vault layout.
  const new({
    required this.listPane,
    required this.entryId,
    required this.onDeleted,
    required this.onEdited,
    required this.onNewItem,
    super.key,
  });

  /// The scrollable list pane placed on the left or as the only pane.
  final Widget listPane;

  /// Identifier of the entry shown in the wide detail pane, if any.
  final String? entryId;

  /// Called when the selected entry was deleted.
  final VoidCallback onDeleted;

  /// Called when the selected entry was edited.
  final VoidCallback onEdited;

  /// Called when the user wants to create a new entry.
  final VoidCallback onNewItem;

  /// Width of the master list pane in the two-pane layout.
  ///
  /// Derived from the effective content width, not the raw window: at 1200 dp
  /// with a 280 dp drawer the content area is only ~850 dp, so a window-based
  /// 408 dp list would leave too little room for the detail pane. The pane
  /// stays between 320 and 420 dp and keeps at least a third of the content.
  double _listPaneWidth(BuildContext context) {
    final width = effectiveWidthOf(context);
    return (width * 0.34).clamp(320.0, (width * 0.42).clamp(320.0, 420.0));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (WindowSizeClass.ofEffective(context).supportsListDetail) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              SizedBox(width: _listPaneWidth(context), child: listPane),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(child: _buildDetail(context)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(bottom: false, child: listPane),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildDetail(BuildContext context) {
    if (entryId != null) {
      return EntryDetailScreen(
        key: ValueKey(entryId),
        entryId: entryId!,
        isEmbedded: true,
        onDeleted: onDeleted,
        onEdited: onEdited,
      );
    }
    return const VaultDetailPlaceholder();
  }

  Widget _buildFab(BuildContext context) {
    return NewEntryFab(onTap: onNewItem);
  }
}
