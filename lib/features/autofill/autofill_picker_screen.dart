import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// The credentials the picker hands back to the autofill service.
///
/// This is the one place the picker holds a password: it is fetched from Rust
/// only after the user taps a specific entry, and passed straight to the
/// platform channel that builds the autofill `Dataset`.
class AutofillSelection {
  /// Creates a selection.
  const new({required this.id, required this.username, required this.password});

  /// Stable entry id.
  final String id;

  /// Username to fill, possibly empty.
  final String username;

  /// Password to fill, possibly empty for username-only logins.
  final String password;
}

/// Credential picker shown when another app or site asks Keyel to fill a form.
///
/// When [onPicked] is provided the screen reports the chosen credentials to the
/// caller (the dedicated autofill Flutter entrypoint). Otherwise it pops the
/// current route with an [AutofillSelection], which is how the in-app debug
/// route uses it.
class AutofillPickerScreen extends ConsumerStatefulWidget {
  /// Creates the picker.
  const new({
    this.package,
    this.webDomain,
    this.onPicked,
    this.onCreateNew,
    super.key,
  });

  /// Android package of the requesting app, if any.
  final String? package;

  /// Web domain of the requesting site, if any.
  final String? webDomain;

  /// Called with the chosen credentials instead of popping a route.
  final ValueChanged<AutofillSelection>? onPicked;

  /// Called when the user chooses "Create new login".
  final VoidCallback? onCreateNew;

  @override
  ConsumerState<AutofillPickerScreen> createState() =>
      _AutofillPickerScreenState();
}

class _AutofillPickerScreenState extends ConsumerState<AutofillPickerScreen> {
  final _search = TextEditingController();
  List<AutofillMatchDto> _matches = const [];
  bool _loading = true;
  String? _error;
  String? _pickingId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matches = await ref
          .read(vaultRepositoryProvider)
          .findAutofillMatches(
            package: widget.package,
            webDomain: widget.webDomain,
            query: _search.text,
          );
      if (!mounted) return;
      final strict = AppPreferences.instance.autofillMatchMode == 'exact';
      setState(() {
        _matches = strict
            ? matches
                  .where((m) => m.quality != AutofillQualityDto.sameSite)
                  .toList()
            : matches;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeVaultError(error);
      });
    }
  }

  Future<void> _pick(AutofillMatchDto match) async {
    if (_pickingId != null) return;
    setState(() => _pickingId = match.summary.id);
    final repository = ref.read(vaultRepositoryProvider);
    try {
      final detail = await repository.getEntry(match.summary.id);
      final password = await repository.revealField(
        match.summary.id,
        SecretFieldDto.loginPassword,
      );
      if (!mounted) return;
      final selection = AutofillSelection(
        id: match.summary.id,
        username: detail.login?.username ?? '',
        password: password,
      );
      final onPicked = widget.onPicked;
      if (onPicked != null) {
        onPicked(selection);
      } else {
        context.pop(selection);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _pickingId = null);
      showKeyelSnack(
        context,
        describeVaultError(error),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Whether the target is known but the top results are only text matches.
  bool get _showMismatchWarning =>
      (_matches.any((match) => match.quality == AutofillQualityDto.search)) &&
      (widget.package != null || widget.webDomain != null);

  String get _targetLabel {
    final domain = widget.webDomain;
    if (domain != null && domain.isNotEmpty) return domain;
    final package = widget.package;
    if (package != null && package.isNotEmpty) return package;
    return 'this app';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unlocked =
        ref.watch(vaultSessionProvider).status == VaultStatus.unlocked;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Fill from Keyel',
              icon: Icons.close_rounded,
              onIconTap: () => _close(null),
            ),
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
                    Icons.vpn_key_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KeyelSpacing.xs),
                  Expanded(
                    child: Text(
                      'Filling $_targetLabel',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
              child: KeyelSearchField(
                controller: _search,
                hintText: 'Search vault',
              ),
            ),
            if (_showMismatchWarning)
              _MismatchBanner(target: _targetLabel)
            else
              const SizedBox(height: KeyelSpacing.sm),
            Expanded(
              child: !unlocked
                  ? const _CenteredNote(
                      icon: Icons.lock_rounded,
                      title: 'Vault locked',
                      body: 'Unlock Keyel to fill this form.',
                    )
                  : _error != null
                  ? _CenteredNote(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load matches',
                      body: _error!,
                    )
                  : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _matches.isEmpty
                  ? const _CenteredNote(
                      icon: Icons.search_off_rounded,
                      title: 'No matching logins',
                      body: 'Create a new login for this app or site.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        top: KeyelSpacing.xs,
                        bottom: KeyelSpacing.lg,
                      ),
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final match = _matches[index];
                        return KeyelEntryTile(
                          id: match.summary.id,
                          title: match.summary.title,
                          subtitle: match.summary.subtitle,
                          icon: Icons.key_rounded,
                          favorite: match.summary.favorite,
                          hasTotp: match.summary.hasTotp,
                          onTap: () => unawaited(_pick(match)),
                        );
                      },
                    ),
            ),
            if (unlocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.xs,
                  KeyelSpacing.lg,
                  KeyelSpacing.md,
                ),
                child: KeyelPillButton(
                  label: 'Create new login',
                  icon: Icons.add_rounded,
                  tone: KeyelButtonTone.tonal,
                  height: 48,
                  onPressed: () {
                    final onCreateNew = widget.onCreateNew;
                    if (onCreateNew != null) {
                      onCreateNew();
                    } else {
                      _close(null);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _close(AutofillSelection? selection) {
    if (widget.onPicked != null) return;
    if (context.canPop()) {
      context.pop(selection);
    }
  }
}

class _MismatchBanner extends StatelessWidget {
  const new({required this.target});

  final String target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        KeyelSpacing.lg,
        KeyelSpacing.sm,
        KeyelSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Text(
              'Some results are text matches only. Check that the login '
              'really belongs to $target before filling.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  const new({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

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
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: KeyelSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KeyelSpacing.xs),
            Text(
              body,
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
