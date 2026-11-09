import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_edit_callbacks.dart';
import 'package:keyel/features/entry/entry_edit_controller.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/edit/card_section.dart';
import 'package:keyel/features/entry/widgets/edit/edit_bar.dart';
import 'package:keyel/features/entry/widgets/edit/identity_card.dart';
import 'package:keyel/features/entry/widgets/edit/login_fields.dart';
import 'package:keyel/features/entry/widgets/edit/notes_section.dart';
import 'package:keyel/features/entry/widgets/edit/organization_section.dart';
import 'package:keyel/features/folders/folder_picker_sheet.dart';
import 'package:keyel/src/rust/api/models.dart';
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
  bool _obscurePassword = true;
  List<FolderDto> _folders = [];
  String? _folderId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFolders());
    if (widget.entryId != null) {
      unawaited(_loadExisting());
    }
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await ref.read(vaultRepositoryProvider).listFolders();
      if (!mounted) return;
      setState(() => _folders = folders);
    } on Object catch (_) {
      // The picker simply stays empty if folders cannot be loaded.
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

  void _generatePassword() {
    final generated = _controller.generatePassword();
    if (generated == null) return;
    setState(() {
      _controller.password.text = generated;
      _obscurePassword = false;
    });
  }

  Future<void> _save() =>
      _controller.save(kind: _kind, favorite: _favorite, folderId: _folderId);

  String get _kindLabel => switch (_kind) {
    VaultEntryKind.login => 'Login',
    VaultEntryKind.card => 'Card',
    VaultEntryKind.note => 'Note',
  };

  IconData get _kindIcon => switch (_kind) {
    VaultEntryKind.login => Icons.shield_rounded,
    VaultEntryKind.card => Icons.credit_card_rounded,
    VaultEntryKind.note => Icons.description_rounded,
  };

  PasswordStrength get _strength =>
      PasswordStrength.estimate(_controller.password.text);

  String get _folderName {
    final id = _folderId;
    if (id == null) return 'No folder';
    for (final folder in _folders) {
      if (folder.id == id) return folder.name;
    }
    return 'Folder';
  }

  Future<void> _chooseFolder() async {
    final selection = await showFolderPicker(
      context: context,
      folders: _folders,
      selectedId: _folderId,
    );
    if (selection == null || !mounted) return;
    setState(() => _folderId = selection.id);
    unawaited(_loadFolders());
  }

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
                  ? 'New $_kindLabel'
                  : 'Edit $_kindLabel',
              onClose: () => context.pop(),
              onSave: _save,
            ),
            Expanded(child: _buildList()),
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

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KeyelSpacing.md,
        KeyelSpacing.xs,
        KeyelSpacing.md,
        KeyelSpacing.lg,
      ),
      children: [
        KeyelSegmentedControl<VaultEntryKind>(
          selected: _kind,
          onChanged: (kind) => setState(() => _kind = kind),
          options: const [
            KeyelSegmentOption(
              value: VaultEntryKind.login,
              label: 'Login',
              icon: Icons.key_rounded,
            ),
            KeyelSegmentOption(
              value: VaultEntryKind.card,
              label: 'Card',
              icon: Icons.credit_card_rounded,
            ),
            KeyelSegmentOption(
              value: VaultEntryKind.note,
              label: 'Note',
              icon: Icons.description_rounded,
            ),
          ],
        ),
        const SizedBox(height: KeyelSpacing.lg),
        IdentityCard(
          icon: _kindIcon,
          titleController: _controller.title,
          onIconTap: () => _notify(
            'Choosing a custom avatar arrives later.',
            icon: Icons.palette_rounded,
          ),
        ),
        const SizedBox(height: KeyelSpacing.md),
        if (_kind == VaultEntryKind.login) ...[
          LoginFields(
            usernameController: _controller.username,
            onSuggestion: () =>
                setState(() => _controller.username.text = 'alex.dev@hey.com'),
            passwordController: _controller.password,
            strength: _strength,
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onChanged: (_) => setState(() {}),
            onGenerate: _generatePassword,
            websiteController: _controller.website,
            onScan: () => _notify(
              'QR scanning arrives with the TOTP engine.',
              icon: Icons.qr_code_scanner_rounded,
            ),
            onManual: () => _notify(
              'Manual TOTP setup arrives with the TOTP engine.',
              icon: Icons.keyboard_rounded,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
        ],
        if (_kind == VaultEntryKind.card) ...[
          CardSection(
            numberController: _controller.cardNumber,
            expiryController: _controller.cardExpiry,
            cardholderController: _controller.cardholder,
          ),
          const SizedBox(height: KeyelSpacing.md),
        ],
        if (_kind == VaultEntryKind.note) ...[
          NotesSection(
            controller: _controller.notes,
            minLines: 8,
            label: 'Secure note',
          ),
          const SizedBox(height: KeyelSpacing.md),
          OrganizationSection(
            favorite: _favorite,
            folder: _folderName,
            onFavoriteChanged: (value) => setState(() => _favorite = value),
            onFolderTap: () => unawaited(_chooseFolder()),
          ),
        ] else ...[
          OrganizationSection(
            favorite: _favorite,
            folder: _folderName,
            onFavoriteChanged: (value) => setState(() => _favorite = value),
            onFolderTap: () => unawaited(_chooseFolder()),
          ),
          const SizedBox(height: KeyelSpacing.md),
          NotesSection(
            controller: _controller.notes,
            minLines: 3,
            label: 'Secure notes',
          ),
        ],
        const SizedBox(height: KeyelSpacing.lg),
      ],
    );
  }
}
