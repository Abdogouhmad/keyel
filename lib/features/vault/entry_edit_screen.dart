import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/vault/vault_entry.dart';
import 'package:keyel/src/rust/api/generator.dart';
import 'package:keyel/ui/keyel.dart';

/// Create or edit a vault entry.
class EntryEditScreen extends StatefulWidget {
  /// Creates the editor. Omit [entryId] to create a new entry.
  const new({this.entryId, super.key});

  /// Existing entry id, or `null` for a new entry.
  final String? entryId;

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardholderController = TextEditingController();

  VaultEntry? _existing;
  VaultEntryKind _kind = VaultEntryKind.login;
  bool _favorite = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.entryId == null
        ? null
        : vaultEntryById(widget.entryId!);
    _existing = existing;
    _kind = existing?.kind ?? VaultEntryKind.login;
    _favorite = existing?.favorite ?? false;
    _titleController.text = existing?.title ?? '';
    _usernameController.text = existing?.username ?? '';
    _passwordController.text = existing?.password ?? '';
    _websiteController.text = existing?.website ?? '';
    _notesController.text = existing?.notes ?? '';
    _cardNumberController.text = existing?.cardNumber ?? '';
    _cardExpiryController.text = existing?.cardExpiry ?? '';
    _cardholderController.text = existing?.cardholder ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

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
      PasswordStrength.estimate(_passwordController.text);

  void _generatePassword() {
    try {
      final generated = generatePassword(
        length: 20,
        lowercase: true,
        uppercase: true,
        digits: true,
        symbols: true,
        excludeAmbiguous: true,
      );
      setState(() {
        _passwordController.text = generated;
        _obscurePassword = false;
      });
    } on Object catch (_) {
      if (!mounted) return;
      showKeyelSnack(
        context,
        'Could not generate a password right now.',
        icon: Icons.error_rounded,
      );
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      showKeyelSnack(
        context,
        'Give this entry a title first.',
        icon: Icons.error_rounded,
      );
      return;
    }

    showKeyelSnack(
      context,
      _existing == null ? 'Entry created in the demo vault.' : 'Entry updated.',
    );
    context.pop();
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
            _EditBar(
              title: _existing == null ? 'New $_kindLabel' : 'Edit $_kindLabel',
              onClose: () => context.pop(),
              onSave: _save,
            ),
            Expanded(
              child: ListView(
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
                  _IdentityCard(
                    icon: _kindIcon,
                    titleController: _titleController,
                    onIconTap: () => showKeyelSnack(
                      context,
                      'Choosing a custom avatar arrives later.',
                      icon: Icons.palette_rounded,
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.md),
                  if (_kind == VaultEntryKind.login) ...[
                    _UsernameSection(
                      controller: _usernameController,
                      onSuggestion: () => setState(
                        () => _usernameController.text = 'alex.dev@hey.com',
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.md),
                    _PasswordSection(
                      controller: _passwordController,
                      strength: _strength,
                      obscure: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onChanged: (_) => setState(() {}),
                      onGenerate: _generatePassword,
                    ),
                    const SizedBox(height: KeyelSpacing.md),
                    _Section(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Web Vault Matcher',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: KeyelSpacing.sm + 2),
                          TextField(
                            controller: _websiteController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              prefixText: 'https://',
                              hintText: 'domain.com',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.md),
                    _TotpSection(
                      onScan: () => showKeyelSnack(
                        context,
                        'QR scanning arrives with the TOTP engine.',
                        icon: Icons.qr_code_scanner_rounded,
                      ),
                      onManual: () => showKeyelSnack(
                        context,
                        'Manual TOTP setup arrives with the TOTP engine.',
                        icon: Icons.keyboard_rounded,
                      ),
                    ),
                  ],
                  if (_kind == VaultEntryKind.card) ...[
                    _Section(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card details',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(height: KeyelSpacing.sm + 2),
                          TextField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            style: KeyelTheme.mono(context, fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: 'Card number',
                              hintText: '0000 0000 0000 0000',
                            ),
                          ),
                          const SizedBox(height: KeyelSpacing.sm + 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cardExpiryController,
                                  style: KeyelTheme.mono(context),
                                  decoration: const InputDecoration(
                                    labelText: 'Expiry',
                                    hintText: 'MM/YY',
                                  ),
                                ),
                              ),
                              const SizedBox(width: KeyelSpacing.sm + 4),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _cardholderController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Cardholder',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.md),
                  ],
                  if (_kind == VaultEntryKind.note)
                    _NotesSection(
                      controller: _notesController,
                      minLines: 8,
                      label: 'Secure note',
                    ),
                  if (_kind != VaultEntryKind.note) ...[
                    _OrganizationSection(
                      favorite: _favorite,
                      folder: _existing?.folder ?? 'Personal',
                      onFavoriteChanged: (value) =>
                          setState(() => _favorite = value),
                      onFolderTap: () => showKeyelSnack(
                        context,
                        'Folder management arrives with storage.',
                        icon: Icons.folder_rounded,
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.md),
                    _NotesSection(
                      controller: _notesController,
                      minLines: 3,
                      label: 'Secure notes',
                    ),
                  ],
                  if (_kind == VaultEntryKind.note) ...[
                    const SizedBox(height: KeyelSpacing.md),
                    _OrganizationSection(
                      favorite: _favorite,
                      folder: _existing?.folder ?? 'Personal',
                      onFavoriteChanged: (value) =>
                          setState(() => _favorite = value),
                      onFolderTap: () => showKeyelSnack(
                        context,
                        'Folder management arrives with storage.',
                        icon: Icons.folder_rounded,
                      ),
                    ),
                  ],
                  const SizedBox(height: KeyelSpacing.lg),
                ],
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

class _EditBar extends StatelessWidget {
  const new({required this.title, required this.onClose, required this.onSave});

  final String title;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
        child: Row(
          children: [
            KeyelIconHull(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onPressed: onClose,
              foreground: scheme.onSurface,
            ),
            const SizedBox(width: KeyelSpacing.xs),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: KeyelSpacing.sm),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            KeyelPillButton(
              label: 'Save',
              height: 40,
              expand: false,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.titleController,
    required this.onIconTap,
  });

  final IconData icon;
  final TextEditingController titleController;
  final VoidCallback onIconTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return KeyelSectionCard(
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                KeyelAvatar(icon: icon, tone: KeyelAvatarTone.slate, size: 64),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: PressableScale(
                    onTap: onIconTap,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                    semanticLabel: 'Change icon',
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Service or app name',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: child,
    );
  }
}

class _UsernameSection extends StatelessWidget {
  const new({required this.controller, required this.onSuggestion});

  final TextEditingController controller;
  final VoidCallback onSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Username or email',
              hintText: 'username@domain.com',
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          Row(
            children: [
              Text(
                'Suggestion:',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              PressableScale(
                onTap: onSuggestion,
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
                semanticLabel: 'Use suggested email',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 14,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: KeyelSpacing.xs),
                      Text(
                        'alex.dev@hey.com',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const new({
    required this.controller,
    required this.strength,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final PasswordStrength strength;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.xs + 2),
              Expanded(
                child: Text(
                  'Master credentials',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              PressableScale(
                onTap: () => showKeyelSnack(
                  context,
                  'Password history arrives with encrypted storage.',
                  icon: Icons.history_rounded,
                ),
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'History',
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: KeyelTheme.mono(context, fontSize: 16, letterSpacing: 0.6),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter secure password',
              suffixIconConstraints: const BoxConstraints(
                minWidth: 88,
                minHeight: 48,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyelIconHull(
                    icon: obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    tooltip: obscure ? 'Reveal password' : 'Hide password',
                    onPressed: onToggleObscure,
                    size: 44,
                    iconSize: 20,
                  ),
                  KeyelIconHull(
                    icon: Icons.shuffle_rounded,
                    tooltip: 'Generate password',
                    onPressed: onGenerate,
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelStrengthMeter(strength: strength, showHint: false),
          const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelPillButton(
            label: 'Generate secure password',
            icon: Icons.auto_awesome_rounded,
            tone: KeyelButtonTone.tonal,
            height: 48,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }
}

class _TotpSection extends StatelessWidget {
  const new({required this.onScan, required this.onManual});

  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phonelink_lock_rounded,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Expanded(
                child: Text(
                  'Two-factor authentication',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              KeyelBadge(
                label: 'TOTP',
                background: scheme.surfaceContainerHigh,
                foreground: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Text(
            'Generate integrated 30-second rotating security codes directly '
            'inside Keyel.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Row(
            children: [
              Expanded(
                child: KeyelPillButton(
                  label: 'Scan QR Code',
                  icon: Icons.qr_code_scanner_rounded,
                  tone: KeyelButtonTone.neutral,
                  height: 48,
                  onPressed: onScan,
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Expanded(
                child: KeyelPillButton(
                  label: 'Enter Manually',
                  icon: Icons.keyboard_rounded,
                  tone: KeyelButtonTone.neutral,
                  height: 48,
                  onPressed: onManual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrganizationSection extends StatelessWidget {
  const new({
    required this.favorite,
    required this.folder,
    required this.onFavoriteChanged,
    required this.onFolderTap,
  });

  final bool favorite;
  final String folder;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onFolderTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Section(
      child: Column(
        children: [
          PressableScale(
            onTap: onFolderTap,
            borderRadius: BorderRadius.circular(KeyelRadii.field),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 24,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KeyelSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Folder',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          folder,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const KeyelRule(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 24, color: scheme.primary),
                const SizedBox(width: KeyelSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to favorites',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'Pin this entry to quick access',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: favorite, onChanged: onFavoriteChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const new({
    required this.controller,
    required this.minLines,
    required this.label,
  });

  final TextEditingController controller;
  final int minLines;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Section(
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          hintText: 'Recovery questions, PIN codes, backup seeds...',
          suffixIcon: Icon(
            Icons.lock_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
