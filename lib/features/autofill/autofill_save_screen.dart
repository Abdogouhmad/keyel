import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Confirmation screen shown when another app or site submits credentials that
/// Keyel does not know about.
///
/// The captured username and password arrive pre-filled; nothing is written to
/// the vault until the user taps **Save login**. The password never leaves this
/// screen except into Rust's encrypted store.
class AutofillSaveScreen extends ConsumerStatefulWidget {
  /// Creates the save screen.
  const new({
    this.package,
    this.webDomain,
    this.username = '',
    this.password = '',
    this.onSaved,
    this.onDecline,
    super.key,
  });

  /// Android package of the requesting app, if any.
  final String? package;

  /// Web domain of the requesting site, if any.
  final String? webDomain;

  /// Username captured from the login form.
  final String username;

  /// Password captured from the login form.
  final String password;

  /// Called after the login is stored.
  final VoidCallback? onSaved;

  /// Called when the user declines to save.
  final VoidCallback? onDecline;

  @override
  ConsumerState<AutofillSaveScreen> createState() => _AutofillSaveScreenState();
}

class _AutofillSaveScreenState extends ConsumerState<AutofillSaveScreen> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _defaultTitle());
    _username = TextEditingController(text: widget.username);
    _password = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _targetLabel {
    final domain = widget.webDomain;
    if (domain != null && domain.isNotEmpty) return domain;
    final package = widget.package;
    if (package != null && package.isNotEmpty) return package;
    return 'this app';
  }

  String _defaultTitle() {
    final domain = widget.webDomain;
    if (domain != null && domain.isNotEmpty) {
      return domain.replaceFirst(RegExp(r'^www\.'), '');
    }
    final package = widget.package;
    if (package != null && package.isNotEmpty) return package;
    return 'New login';
  }

  /// The stored URL used to match this login on future fills.
  String get _url {
    final domain = widget.webDomain;
    if (domain != null && domain.isNotEmpty) {
      return domain.contains('://') ? domain : 'https://$domain';
    }
    final package = widget.package;
    if (package != null && package.isNotEmpty) return 'androidapp://$package';
    return '';
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give this login a name first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(vaultRepositoryProvider)
          .upsertEntry(
            EntryDraft(
              kind: EntryKindDto.login,
              title: title,
              tags: const [],
              favorite: false,
              username: _username.text,
              password: _password.text,
              url: _url,
              totpAlgorithm: TotpAlgorithmDto.sha1,
              totpDigits: 6,
              totpPeriod: 30,
              cardholder: '',
              cardExpiry: '',
            ),
          );
      if (!mounted) return;
      final onSaved = widget.onSaved;
      if (onSaved != null) {
        onSaved();
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = describeVaultError(error);
      });
    }
  }

  void _decline() {
    final onDecline = widget.onDecline;
    if (onDecline != null) onDecline();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Save login?',
              icon: Icons.close_rounded,
              onIconTap: _decline,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: KeyelSpacing.lg),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KeyelSpacing.lg,
                      KeyelSpacing.xs,
                      KeyelSpacing.lg,
                      KeyelSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.save_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: KeyelSpacing.xs),
                        Expanded(
                          child: Text(
                            'Store these credentials for $_targetLabel',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeyelSpacing.lg,
                    ),
                    child: TextField(
                      controller: _title,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeyelSpacing.lg,
                    ),
                    child: TextField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.md),
                  KeyelPasswordField(
                    controller: _password,
                    label: 'Password',
                    textInputAction: TextInputAction.done,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        KeyelSpacing.lg,
                        KeyelSpacing.md,
                        KeyelSpacing.lg,
                        0,
                      ),
                      child: Text(
                        _error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KeyelSpacing.lg,
                KeyelSpacing.xs,
                KeyelSpacing.lg,
                KeyelSpacing.md,
              ),
              child: Column(
                children: [
                  KeyelPillButton(
                    label: 'Save login',
                    icon: Icons.check_rounded,
                    height: 48,
                    onPressed: _saving ? null : () => unawaited(_save()),
                  ),
                  const SizedBox(height: KeyelSpacing.xs),
                  KeyelPillButton(
                    label: 'Not now',
                    tone: KeyelButtonTone.neutral,
                    height: 48,
                    onPressed: _saving ? null : _decline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
