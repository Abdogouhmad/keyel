import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/ui_settings_provider.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/vault/widgets/new_entry_fab.dart';
import 'package:keyel/features/vault/widgets/vault_detail_placeholder.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// The main vault content, wide or narrow, depending on window size.
///
/// On a wide effective layout the list pane can be dragged to a comfortable
/// width. The ratio is persisted in [UiSettings] and mirrored in RTL so the
/// list always stays at the reading start.
class VaultLayout extends ConsumerStatefulWidget {
  /// Creates the vault layout.
  const new({
    required this.listPane,
    required this.entryId,
    required this.onDeleted,
    required this.onEdited,
    required this.onNewItem,
    required this.onCloseDetail,
    super.key,
  });

  /// The scrollable list pane placed at the reading start or as the only pane.
  final Widget listPane;

  /// Identifier of the entry shown in the wide detail pane, if any.
  final String? entryId;

  /// Called when the selected entry was deleted.
  final VoidCallback onDeleted;

  /// Called when the selected entry was edited.
  final VoidCallback onEdited;

  /// Called when the user wants to create a new entry.
  final VoidCallback onNewItem;

  /// Called when the embedded detail pane should clear its route selection.
  final VoidCallback onCloseDetail;

  @override
  ConsumerState<VaultLayout> createState() => _VaultLayoutState();
}

class _VaultLayoutState extends ConsumerState<VaultLayout> {
  late double _ratio = ref.read(
    uiSettingsProvider.select((settings) => settings.vaultPaneRatio),
  );
  double? _dragStartWidth;
  double? _dragStartRatio;

  /// List pane width clamped to 28–50 % of the effective content with a 320 dp
  /// floor. At the minimum two-pane width (840 dp) that leaves 420 dp for the
  /// detail pane; below that the layout collapses to one column.
  double _listPaneWidth(BuildContext context) {
    final width = effectiveWidthOf(context);
    final max = math.max<double>(320, width * 0.5);
    final min = math.min<double>(320, max);
    return (width * _ratio).clamp(min, max);
  }

  void _startDrag(DragStartDetails details) {
    _dragStartRatio = _ratio;
    _dragStartWidth = effectiveWidthOf(context);
  }

  void _updateDrag(DragUpdateDetails details) {
    final startWidth = _dragStartWidth;
    final startRatio = _dragStartRatio;
    if (startWidth == null || startRatio == null || startWidth <= 0) return;
    // Dragging towards the reading end widens the list in both directions.
    final delta = details.delta.dx * (context.isRtl ? -1 : 1);
    final max = math.max<double>(320, startWidth * 0.5);
    final min = math.min<double>(320, max);
    final width = (startWidth * startRatio + delta).clamp(min, max);
    setState(() => _ratio = width / startWidth);
  }

  void _endDrag(DragEndDetails details) {
    _dragStartRatio = null;
    _dragStartWidth = null;
    ref.read(uiSettingsProvider.notifier).setVaultPaneRatio(_ratio);
  }

  /// Keyboard support for the resize handle: arrow keys move the divider by
  /// 2 % of the content width, so the split is reachable without a pointer.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final rtl = context.isRtl;
    final forward = event.logicalKey == LogicalKeyboardKey.arrowRight;
    final backward = event.logicalKey == LogicalKeyboardKey.arrowLeft;
    if (!forward && !backward) return KeyEventResult.ignored;
    final widen = rtl ? backward : forward;
    final max = math.max<double>(320, effectiveWidthOf(context) * 0.5);
    final min = math.min<double>(320, max);
    final next = (effectiveWidthOf(context) * (_ratio + (widen ? 0.02 : -0.02)))
        .clamp(min, max);
    setState(() => _ratio = next / effectiveWidthOf(context));
    ref.read(uiSettingsProvider.notifier).setVaultPaneRatio(_ratio);
    return KeyEventResult.handled;
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
              SizedBox(width: _listPaneWidth(context), child: widget.listPane),
              _ResizeHandle(
                key: const Key('vault-pane-resize-handle'),
                onStart: _startDrag,
                onUpdate: _updateDrag,
                onEnd: _endDrag,
                onKey: _onKey,
              ),
              Expanded(child: _buildDetail(context)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(bottom: false, child: widget.listPane),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final entryId = widget.entryId;
    if (entryId != null) {
      return EntryDetailScreen(
        key: ValueKey(entryId),
        entryId: entryId,
        isEmbedded: true,
        onDeleted: widget.onDeleted,
        onEdited: widget.onEdited,
        onBack: widget.onCloseDetail,
      );
    }
    return const VaultDetailPlaceholder();
  }

  Widget _buildFab(BuildContext context) =>
      NewEntryFab(onTap: widget.onNewItem);
}

/// A thin visible divider with a generous, accessible drag target.
class _ResizeHandle extends StatelessWidget {
  const new({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onKey,
    super.key,
  });

  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final FocusOnKeyEventCallback onKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    return Semantics(
      label: l10n.paneResizeLabel,
      child: Focus(
        onKeyEvent: onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: onStart,
          onHorizontalDragUpdate: onUpdate,
          onHorizontalDragEnd: onEnd,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: SizedBox(
              width: KeyelSpacing.sm,
              child: Center(
                child: Container(
                  width: 2,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
