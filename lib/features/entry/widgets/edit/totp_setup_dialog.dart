import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/src/rust/api/totp.dart' as totp_api;
import 'package:keyel/ui/keyel.dart';

/// Dialog that validates a typed TOTP secret or `otpauth://` URI.
///
/// Returns the parsed [TotpConfigDto] (with the normalised secret) when the
/// user confirms, or `null` when they cancel. Validation runs in Rust so the
/// same rules apply to scanned and typed secrets.
class TotpSetupDialog extends StatefulWidget {
  /// Creates the TOTP setup dialog.
  const new({this.initialValue = '', super.key});

  /// Existing secret or URI to prefill.
  final String initialValue;

  /// Shows the dialog and resolves to the parsed config, or `null`.
  static Future<TotpConfigDto?> show(
    BuildContext context, {
    String initialValue = '',
  }) {
    return showDialog<TotpConfigDto>(
      context: context,
      builder: (_) => TotpSetupDialog(initialValue: initialValue),
    );
  }

  @override
  State<TotpSetupDialog> createState() => _TotpSetupDialogState();
}

class _TotpSetupDialogState extends State<TotpSetupDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter the setup key from your provider.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final config = await totp_api.parseOtpauth(uri: value);
      if (!mounted) return;
      Navigator.of(context).pop(config);
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'That key or link is not a valid TOTP secret.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      title: Text(
        'Set up two-factor',
        style: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste the setup key (base32) or the otpauth:// link from your '
            'provider.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Setup key or link',
              hintText: 'JBSWY3DPEHPK3PXP',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
