import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:keyel/src/rust/api/models.dart' show CustomFieldDraft;
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
  _EditSnapshot? _baseline;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // New entries start from the empty controllers; existing ones replace
    // this baseline once their secrets have been loaded.
    _baseline = _capture();
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
        if (mounted) {
          // A successful save is not an "unsaved change": skip the guard so
          // the just-persisted entry is not reported as dirty on the way out.
          _saved = true;
          context.pop();
        }
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
      _baseline = _capture();
    });
  }

  Future<void> _save() =>
      _controller.save(kind: _kind, favorite: _favorite, folderId: _folderId);

  _EditSnapshot _capture() => _EditSnapshot(
    _controller,
    kind: _kind,
    favorite: _favorite,
    folderId: _folderId,
  );

  bool _isDirty() {
    if (_saved) return false;
    final baseline = _baseline;
    return baseline == null ||
        !baseline.matches(
          _controller,
          kind: _kind,
          favorite: _favorite,
          folderId: _folderId,
        );
  }

  Future<void> _confirmDiscard() async {
    final l10n = l10nOf(context);
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.entryDiscardTitle,
      body: l10n.entryDiscardBody,
      confirmLabel: l10n.entryDiscardConfirm,
      destructive: true,
    );
    if (confirmed && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = l10nOf(context);

    // canPop stays false so the decision is made at pop time: text controllers
    // mutate without rebuilding this widget, so a build-time canPop would go
    // stale the moment the user types.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !mounted) return;
        if (!_isDirty()) {
          Navigator.of(context).pop();
          return;
        }
        unawaited(_confirmDiscard());
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              EditBar(
                title: widget.entryId == null
                    ? l10n.entryNewTitle(editKindLabel(_kind))
                    : l10n.entryEditTitle(editKindLabel(_kind)),
                onClose: () => Navigator.of(context).maybePop(),
                onSave: _save,
              ),
              Expanded(
                child: EditFormLayout(
                  controller: _controller,
                  kind: _kind,
                  onKindChanged: (kind) => setState(() => _kind = kind),
                  favorite: _favorite,
                  onFavoriteChanged: (value) =>
                      setState(() => _favorite = value),
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
              label: l10n.entrySaveEntry,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ),
        ),
      ),
    );
  }
}

/// Values captured at load time so "unsaved changes" can be detected without
/// sprinkling dirty flags through every field callback. Strings and drafts are
/// immutable, so holding references here cannot mutate the baseline.
class _EditSnapshot {
  new(
    EntryEditController controller, {
    required this.kind,
    required this.favorite,
    required this.folderId,
  }) : title = controller.title.text,
       username = controller.username.text,
       password = controller.password.text,
       totpSecret = controller.totpSecret.text,
       website = controller.website.text,
       notes = controller.notes.text,
       cardNumber = controller.cardNumber.text,
       cardExpiry = controller.cardExpiry.text,
       cardholder = controller.cardholder.text,
       iconKey = controller.iconKey,
       customFields = List<CustomFieldDraft>.of(controller.customFields);

  final VaultEntryKind kind;
  final bool favorite;
  final String? folderId;
  final String title;
  final String username;
  final String password;
  final String totpSecret;
  final String website;
  final String notes;
  final String cardNumber;
  final String cardExpiry;
  final String cardholder;
  final String? iconKey;
  final List<CustomFieldDraft> customFields;

  bool matches(
    EntryEditController controller, {
    required VaultEntryKind kind,
    required bool favorite,
    required String? folderId,
  }) =>
      this.kind == kind &&
      this.favorite == favorite &&
      this.folderId == folderId &&
      title == controller.title.text &&
      username == controller.username.text &&
      password == controller.password.text &&
      totpSecret == controller.totpSecret.text &&
      website == controller.website.text &&
      notes == controller.notes.text &&
      cardNumber == controller.cardNumber.text &&
      cardExpiry == controller.cardExpiry.text &&
      cardholder == controller.cardholder.text &&
      iconKey == controller.iconKey &&
      listEquals(customFields, controller.customFields);
}
