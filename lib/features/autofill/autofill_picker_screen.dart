import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/autofill_target.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/autofill/widgets/autofill_picker_widgets.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

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
    this.onNeverForSite,
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

  /// Called when the user chooses "Never for this site". The callback persists
  /// the denial and cancels the autofill request.
  final VoidCallback? onNeverForSite;

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
            requireVerified: AppPreferences.instance.autofillVerifiedOnly,
          );
      if (!mounted) return;
      final prefs = AppPreferences.instance;
      // `exact` match mode and verified-only both mean the same thing to the
      // user: only suggest a login whose host or package actually matches.
      // Text-search hits are never an identity proof, so an exact-mode picker
      // must drop them too instead of silently widening the match.
      final strict =
          prefs.autofillMatchMode == 'exact' || prefs.autofillVerifiedOnly;
      setState(() {
        _matches = matches.where((match) {
          if (strict) return match.quality == AutofillQualityDto.exact;
          return true;
        }).toList();
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
    return l10nOf(context).autofillTargetThisApp;
  }

  String? get _denyKey => canonicalAutofillTarget(
    package: widget.package,
    webDomain: widget.webDomain,
  );

  bool get _isDenied {
    final key = _denyKey;
    return key != null &&
        AppPreferences.instance.autofillNeverForSites.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final unlocked =
        ref.watch(vaultSessionProvider.select((state) => state.status)) ==
        VaultStatus.unlocked;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: KeyelContent(
          child: Column(
            children: [
              KeyelTopBar(
                title: l10n.autofillFillTitle,
                icon: Icons.close_rounded,
                iconTooltip: l10n.actionCancel,
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
                        l10n.autofillFilling(_targetLabel),
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
                child: KeyelSearchField(
                  controller: _search,
                  hintText: l10n.autofillSearchVault,
                ),
              ),
              if (_isDenied)
                Expanded(
                  child: AutofillCenteredNote(
                    kind: KeyelStateMessageKind.empty,
                    icon: Icons.block_rounded,
                    title: l10n.autofillDisabledTitle,
                    body: l10n.autofillDisabledBody,
                  ),
                )
              else ...[
                if (_showMismatchWarning)
                  AutofillMismatchBanner(target: _targetLabel)
                else
                  const SizedBox(height: KeyelSpacing.sm),
                Expanded(
                  child: AutofillPickerBody(
                    unlocked: unlocked,
                    loading: _loading,
                    error: _error,
                    matches: _matches,
                    onPick: _pick,
                    onRetry: () => unawaited(_load()),
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
                    child: Column(
                      children: [
                        KeyelPillButton(
                          label: l10n.autofillCreateNewLogin,
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
                        if (_denyKey != null)
                          TextButton(
                            onPressed: () {
                              final onNever = widget.onNeverForSite;
                              if (onNever != null) onNever();
                            },
                            child: Text(l10n.autofillNeverForSite),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
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
