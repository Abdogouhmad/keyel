import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_edit_callbacks.dart';
import 'package:keyel/features/entry/entry_edit_controller.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/edit/edit_bar.dart';
import 'package:keyel/features/entry/widgets/edit/edit_form_layout.dart';
import 'package:keyel/features/entry/widgets/edit/edit_kind.dart';
import 'package:keyel/ui/keyel.dart';

/// Create or edit a vault entry.
class EntryEditScreen extends ConsumerStatefulWidget {
  /// Creates the editor. Omit [entryId] to create a new entry.
  const new({this.entryId, super.key});

  /// Existing entry id, or `null` for a new entry.
  final String? entryId;

  @override
  ConsumerState<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends ConsumerState<EntryEditScreen> {
  late final EntryEditController _controller = _createController();
  VaultEntryKind _kind = VaultEntryKind.login;
  bool _favorite = false;
  String? _folderId;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      unawaited(_loadExisting());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  EntryEditController _createController() => EntryEditController(
    entryId: widget.entryId,
    repository: ref.read(vaultRepositoryProvider),
    callbacks: EntryEditCallbacks(
      rebuild: _rebuild,
      notify: _notify,
      notifyError: _notifyError,
      close: () {
        if (mounted) context.pop();
      },
    ),
  );

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _notify(String message, {IconData? icon}) {
    if (mounted) {
      showKeyelSnack(
        context,
        message,
        icon: icon ?? Icons.info_outline_rounded,
      );
    }
  }

  void _notifyError(Object error) {
    if (mounted) {
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _loadExisting() async {
    final loaded = await _controller.load();
    if (loaded == null || !mounted) return;
    setState(() {
      _kind = loaded.kind;
      _favorite = loaded.favorite;
      _folderId = loaded.folderId;
    });
  }

  Future<void> _save() =>
      _controller.save(kind: _kind, favorite: _favorite, folderId: _folderId);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            EditBar(
              title: widget.entryId == null
                  ? 'New ${editKindLabel(_kind)}'
                  : 'Edit ${editKindLabel(_kind)}',
              onClose: () => context.pop(),
              onSave: _save,
            ),
            Expanded(
              child: EditFormLayout(
                controller: _controller,
                kind: _kind,
                onKindChanged: (kind) => setState(() => _kind = kind),
                favorite: _favorite,
                onFavoriteChanged: (value) => setState(() => _favorite = value),
                folderId: _folderId,
                onFolderChanged: (id) => setState(() => _folderId = id),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: scheme.surface,
          padding: const EdgeInsets.fromLTRB(
            KeyelSpacing.md,
            KeyelSpacing.sm,
            KeyelSpacing.md,
            KeyelSpacing.md,
          ),
          child: KeyelPillButton(
            label: 'Save entry',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
