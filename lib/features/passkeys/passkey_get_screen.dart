import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Screen for selecting and asserting a passkey during a WebAuthn get ceremony.
///
/// Lists matching passkeys for the requesting RP and performs assertion inside
/// Rust/session boundaries. Private key material never leaves Rust.
class PasskeyGetScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({
    required this.requestJson,
    required this.origin,
    required this.rpId,
    required this.onAsserted,
    required this.onCancel,
    super.key,
  });

  /// Raw WebAuthn get/assertion request JSON.
  final String requestJson;

  /// Requesting origin.
  final String origin;

  /// Relying party ID, if known.
  final String? rpId;

  /// Called with the WebAuthn assertion response JSON on success.
  final ValueChanged<String> onAsserted;

  /// Called when the user cancels.
  final VoidCallback onCancel;

  @override
  ConsumerState<PasskeyGetScreen> createState() => _PasskeyGetScreenState();
}

class _PasskeyGetScreenState extends ConsumerState<PasskeyGetScreen> {
  bool _loading = true;
  bool _asserting = false;
  String? _error;
  List<EntrySummaryDto> _matches = const [];

  String get _effectiveRpId {
    final explicit = widget.rpId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    try {
      final decoded = jsonDecode(widget.requestJson);
      if (decoded is Map) {
        final rp = decoded['rpId'];
        if (rp is String && rp.trim().isNotEmpty) return rp.trim();
      }
    } on Object catch (_) {}
    return '';
  }

  String get _origin {
    if (widget.origin.trim().isNotEmpty) return widget.origin.trim();
    final rp = _effectiveRpId;
    return rp.isEmpty ? '' : 'https://$rp';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant PasskeyGetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new ceremony can target a different relying party. Reload so matches
    // from the previous RP can never be selected for the new request.
    if (oldWidget.rpId != widget.rpId ||
        oldWidget.requestJson != widget.requestJson) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final rpId = _effectiveRpId;
    setState(() {
      _error = null;
      _matches = const [];
    });
    if (rpId.isEmpty) {
      setState(() {
        _loading = false;
        _error = currentL10n.passMissingRp;
      });
      return;
    }
    try {
      final matches = await ref
          .read(vaultRepositoryProvider)
          .listPasskeysForRp(rpId);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _loading = false;
        if (matches.isEmpty) {
          _error = currentL10n.passNoMatchesForRp(rpId);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        // Never leave stale credentials visible under a hidden load error.
        _matches = const [];
        _loading = false;
        _error = describeVaultError(e);
      });
    }
  }

  Future<void> _usePasskey(EntrySummaryDto entry) async {
    if (_asserting) return;
    setState(() {
      _asserting = true;
      _error = null;
    });
    try {
      // We need the credential id for this entry; fetch detail (secret-free).
      final detail = await ref.read(vaultRepositoryProvider).getEntry(entry.id);
      final credId = detail.passkey?.credentialId;
      final response = await ref
          .read(vaultRepositoryProvider)
          .getPasskeyAssertionResponse(
            requestJson: widget.requestJson,
            origin: _origin,
            credentialIdB64: credId,
          );
      if (!mounted) return;
      widget.onAsserted(response);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _asserting = false;
        _error = describeVaultError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final rpId = _effectiveRpId.isEmpty ? l10n.passThisSite : _effectiveRpId;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: KeyelContent(
          maxWidth: KeyelContentWidth.form,
          child: Column(
            children: [
              KeyelTopBar(
                title: l10n.passUsePasskey,
                icon: Icons.close_rounded,
                iconTooltip: l10n.actionCancel,
                onIconTap: widget.onCancel,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.sm,
                  KeyelSpacing.lg,
                  KeyelSpacing.sm,
                ),
                child: Align(
                  alignment: context.alignStart,
                  child: Text(
                    l10n.passSignInTo(rpId),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (_loading)
                Expanded(
                  child: KeyelStateMessage(
                    kind: KeyelStateMessageKind.loading,
                    message: l10n.passFindingPasskeys,
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: KeyelStateMessage(
                    kind: KeyelStateMessageKind.error,
                    message: _error!,
                    actionLabel: l10n.actionRetry,
                    onAction: () => unawaited(_load()),
                  ),
                )
              else
                Expanded(
                  child: _matches.isEmpty
                      ? KeyelStateMessage(
                          kind: KeyelStateMessageKind.empty,
                          title: l10n.passNoMatches,
                          message: l10n.passNoMatchesAvailable(rpId),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(KeyelSpacing.md),
                          itemCount: _matches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: KeyelSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = _matches[index];
                            return Material(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(
                                KeyelRadii.card,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _asserting
                                    ? null
                                    : () => unawaited(_usePasskey(item)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    KeyelSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.key_rounded,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: KeyelSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if (item.subtitle.isNotEmpty)
                                              Text(
                                                item.subtitle,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_asserting)
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Icon(
                                          context.forwardChevron,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              if (_error != null && _matches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.lg,
                  ),
                  child: Text(
                    _error!,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(KeyelSpacing.lg),
                child: KeyelPillButton(
                  label: l10n.actionCancel,
                  tone: KeyelButtonTone.tonal,
                  onPressed: _asserting ? null : widget.onCancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
