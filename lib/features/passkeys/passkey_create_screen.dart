import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';

/// Confirmation screen for creating/saving a new passkey.
///
/// Calls the Rust ceremony API to generate keys, store the passkey in the
/// encrypted vault, and build the WebAuthn registration response. Private key
/// material never leaves Rust/session boundaries.
class PasskeyCreateScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({
    required this.requestJson,
    required this.origin,
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  /// Raw WebAuthn creation request JSON.
  final String requestJson;

  /// Requesting origin (e.g. https://rp.example or android:apk-key-hash:...).
  final String origin;

  /// Called with the WebAuthn response JSON on success.
  final ValueChanged<String> onCreated;

  /// Called when the user cancels.
  final VoidCallback onCancel;

  @override
  ConsumerState<PasskeyCreateScreen> createState() =>
      _PasskeyCreateScreenState();
}

class _PasskeyCreateScreenState extends ConsumerState<PasskeyCreateScreen> {
  bool _saving = false;
  String? _error;

  Map<String, dynamic>? get _req {
    try {
      final decoded = jsonDecode(widget.requestJson);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object catch (_) {
      return null;
    }
  }

  String get _rpId {
    final req = _req;
    if (req == null) return 'Unknown site';
    final rp = req['rp'];
    if (rp is Map) {
      final id = rp['id'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
      final name = rp['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return 'Unknown site';
  }

  String get _rpName {
    final req = _req;
    final rp = req?['rp'];
    if (rp is Map) {
      final name = rp['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return _rpId;
  }

  String get _userName {
    final req = _req;
    final user = req?['user'];
    if (user is Map) {
      final name = user['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
      final display = user['displayName'];
      if (display is String && display.trim().isNotEmpty) return display.trim();
    }
    return 'Unknown account';
  }

  String get _userDisplayName {
    final req = _req;
    final user = req?['user'];
    if (user is Map) {
      final display = user['displayName'];
      if (display is String && display.trim().isNotEmpty) return display.trim();
    }
    return _userName;
  }

  Future<void> _create() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final origin = widget.origin.trim().isEmpty
          ? 'https://$_rpId'
          : widget.origin;
      final result = await ref
          .read(vaultRepositoryProvider)
          .createPasskeyForRequest(
            requestJson: widget.requestJson,
            origin: origin,
          );
      if (!mounted) return;
      widget.onCreated(result.responseJson);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = describeVaultError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: KeyelContent(
          maxWidth: KeyelContentWidth.form,
          child: Column(
            children: [
              KeyelTopBar(
                title: 'Save passkey',
                icon: Icons.close_rounded,
                iconTooltip: 'Cancel',
                onIconTap: widget.onCancel,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(KeyelSpacing.lg),
                  children: [
                    Text(
                      'Create a passkey for this account?',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    Text(
                      'The passkey will be encrypted and stored in your local Keyel vault. Your private key never leaves this device.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    KeyelSectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _InfoRow(label: 'Site', value: _rpName),
                          const Divider(height: 1),
                          _InfoRow(label: 'Domain', value: _rpId),
                          const Divider(height: 1),
                          _InfoRow(label: 'Account', value: _userName),
                          if (_userDisplayName != _userName) ...[
                            const Divider(height: 1),
                            _InfoRow(
                              label: 'Display name',
                              value: _userDisplayName,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.origin.trim().isNotEmpty) ...[
                      const SizedBox(height: KeyelSpacing.sm),
                      Text(
                        'Origin: ${widget.origin}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: KeyelSpacing.md),
                      Text(
                        _error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.sm,
                  KeyelSpacing.lg,
                  KeyelSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: KeyelPillButton(
                        label: 'Cancel',
                        tone: KeyelButtonTone.tonal,
                        onPressed: _saving ? null : widget.onCancel,
                      ),
                    ),
                    const SizedBox(width: KeyelSpacing.sm),
                    Expanded(
                      child: KeyelPillButton(
                        label: _saving ? 'Saving…' : 'Save passkey',
                        icon: Icons.key_rounded,
                        onPressed: _saving ? null : () => unawaited(_create()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KeyelSpacing.md,
        vertical: KeyelSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
