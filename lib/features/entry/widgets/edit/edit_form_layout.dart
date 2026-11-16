import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/entry_edit_controller.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/features/entry/widgets/edit/card_section.dart';
import 'package:keyel/features/entry/widgets/edit/edit_kind.dart';
import 'package:keyel/features/entry/widgets/edit/identity_card.dart';
import 'package:keyel/features/entry/widgets/edit/login_fields.dart';
import 'package:keyel/features/entry/widgets/edit/notes_section.dart';
import 'package:keyel/features/entry/widgets/edit/organization_section.dart';
import 'package:keyel/features/entry/widgets/edit/password_section.dart';
import 'package:keyel/features/entry/widgets/edit/totp_section.dart';
import 'package:keyel/features/entry/widgets/edit/totp_setup_dialog.dart';
import 'package:keyel/features/entry/widgets/edit/username_section.dart';
import 'package:keyel/features/entry/widgets/edit/website_section.dart';
import 'package:keyel/features/folders/folder_picker_sheet.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Editor form body: every section between the edit bar and the save button.
///
/// Sections stack in a single column on compact and medium windows and split
/// into two side-by-side columns on expanded and large windows, following
/// the same [WindowSizeClass] breakpoint as the list-detail layout.
class EditFormLayout extends ConsumerStatefulWidget {
  /// Creates the editor form body.
  const new({
    required this.controller,
    required this.kind,
    required this.onKindChanged,
    required this.favorite,
    required this.onFavoriteChanged,
    required this.folderId,
    required this.onFolderChanged,
    super.key,
  });

  /// Owns the text controllers behind the editor fields.
  final EntryEditController controller;

  /// Kind of entry being edited; drives the visible sections.
  final VaultEntryKind kind;

  /// Called when the entry kind selector changes.
  final ValueChanged<VaultEntryKind> onKindChanged;

  /// Whether the entry is pinned to favorites.
  final bool favorite;

  /// Called when the favorites switch changes.
  final ValueChanged<bool> onFavoriteChanged;

  /// Id of the folder the entry is filed under, or `null` for none.
  final String? folderId;

  /// Called when a different folder is picked for the entry.
  final ValueChanged<String?> onFolderChanged;

  @override
  ConsumerState<EditFormLayout> createState() => _EditFormLayoutState();
}

class _EditFormLayoutState extends ConsumerState<EditFormLayout> {
  bool _obscurePassword = true;
  List<FolderDto> _folders = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadFolders());
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

  String get _folderName {
    final id = widget.folderId;
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
      selectedId: widget.folderId,
    );
    if (selection == null || !mounted) return;
    widget.onFolderChanged(selection.id);
    unawaited(_loadFolders());
  }

  PasswordStrength get _strength =>
      PasswordStrength.estimate(widget.controller.password.text);

  void _generatePassword() {
    final generated = widget.controller.generatePassword();
    if (generated == null) return;
    setState(() {
      widget.controller.password.text = generated;
      _obscurePassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final twoColumns = WindowSizeClass.of(context).supportsListDetail;

    return KeyelContent(
      maxWidth: twoColumns ? KeyelContentWidth.page : KeyelContentWidth.form,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.pageMargin,
          KeyelSpacing.xs,
          context.pageMargin,
          KeyelSpacing.lg,
        ),
        children: [
          KeyelSegmentedControl<VaultEntryKind>(
            selected: widget.kind,
            onChanged: widget.onKindChanged,
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
            icon: editKindIcon(widget.kind),
            titleController: widget.controller.title,
            onIconTap: () => showKeyelSnack(
              context,
              'Choosing a custom avatar arrives later.',
              icon: Icons.palette_rounded,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          if (twoColumns) _buildColumns() else ..._stackedSections(),
          const SizedBox(height: KeyelSpacing.lg),
        ],
      ),
    );
  }

  /// Two side-by-side columns used on expanded windows.
  Widget _buildColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: _primarySections())),
        const SizedBox(width: KeyelSpacing.md),
        Expanded(child: Column(children: _secondarySections())),
      ],
    );
  }

  /// Sections carrying the entry's core content; the left column.
  List<Widget> _primarySections() => switch (widget.kind) {
    VaultEntryKind.login => [
      _usernameSection(),
      const SizedBox(height: KeyelSpacing.md),
      _passwordSection(),
      const SizedBox(height: KeyelSpacing.md),
      TotpSection(
        onScan: _scanQr,
        onManual: _enterTotpManually,
        configured: _totpConfigured,
      ),
    ],
    VaultEntryKind.card => [_cardSection()],
    VaultEntryKind.note => [_noteContentSection()],
  };

  /// Sections organizing and annotating the entry; the right column.
  List<Widget> _secondarySections() => switch (widget.kind) {
    VaultEntryKind.login => [
      _websiteSection(),
      const SizedBox(height: KeyelSpacing.md),
      _organizationSection(),
      const SizedBox(height: KeyelSpacing.md),
      _notesSection(),
    ],
    VaultEntryKind.card => [
      _organizationSection(),
      const SizedBox(height: KeyelSpacing.md),
      _notesSection(),
    ],
    VaultEntryKind.note => [_organizationSection()],
  };

  /// All sections stacked in a single column on narrow windows.
  List<Widget> _stackedSections() => switch (widget.kind) {
    VaultEntryKind.login => [
      LoginFields(
        usernameController: widget.controller.username,
        onSuggestion: _suggestUsername,
        passwordController: widget.controller.password,
        strength: _strength,
        obscure: _obscurePassword,
        onToggleObscure: _toggleObscure,
        onChanged: (_) => setState(() {}),
        onGenerate: _generatePassword,
        websiteController: widget.controller.website,
        onScan: _scanQr,
        onManual: _enterTotpManually,
        totpConfigured: _totpConfigured,
      ),
      const SizedBox(height: KeyelSpacing.md),
      _organizationSection(),
      const SizedBox(height: KeyelSpacing.md),
      _notesSection(),
    ],
    VaultEntryKind.card => [
      _cardSection(),
      const SizedBox(height: KeyelSpacing.md),
      _organizationSection(),
      const SizedBox(height: KeyelSpacing.md),
      _notesSection(),
    ],
    VaultEntryKind.note => [
      _noteContentSection(),
      const SizedBox(height: KeyelSpacing.md),
      _organizationSection(),
    ],
  };

  Widget _usernameSection() => UsernameSection(
    controller: widget.controller.username,
    onSuggestion: _suggestUsername,
  );

  Widget _passwordSection() => PasswordSection(
    controller: widget.controller.password,
    strength: _strength,
    obscure: _obscurePassword,
    onToggleObscure: _toggleObscure,
    onChanged: (_) => setState(() {}),
    onGenerate: _generatePassword,
  );

  Widget _websiteSection() =>
      WebsiteSection(controller: widget.controller.website);

  Widget _cardSection() => CardSection(
    numberController: widget.controller.cardNumber,
    expiryController: widget.controller.cardExpiry,
    cardholderController: widget.controller.cardholder,
  );

  Widget _notesSection() => NotesSection(
    controller: widget.controller.notes,
    minLines: 3,
    label: 'Secure notes',
  );

  Widget _noteContentSection() => NotesSection(
    controller: widget.controller.notes,
    minLines: 8,
    label: 'Secure note',
  );

  Widget _organizationSection() => OrganizationSection(
    favorite: widget.favorite,
    folder: _folderName,
    onFavoriteChanged: widget.onFavoriteChanged,
    onFolderTap: () => unawaited(_chooseFolder()),
  );

  void _suggestUsername() {
    setState(() => widget.controller.username.text = 'alex.dev@hey.com');
  }

  void _toggleObscure() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  bool get _totpConfigured =>
      widget.controller.totpSecret.text.trim().isNotEmpty;

  void _scanQr() => showKeyelSnack(
    context,
    'Camera scanning arrives in a later update. Enter the key manually for now.',
    icon: Icons.qr_code_scanner_rounded,
  );

  Future<void> _enterTotpManually() async {
    final config = await TotpSetupDialog.show(
      context,
      initialValue: widget.controller.totpSecret.text,
    );
    if (config == null || !mounted) return;
    setState(() => widget.controller.setTotpConfig(config));
    showKeyelSnack(
      context,
      'Two-factor key ready. Save the entry to store it.',
      icon: Icons.verified_user_rounded,
    );
  }
}
