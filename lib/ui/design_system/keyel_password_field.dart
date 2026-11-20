import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/ui/theme/keyel_theme.dart';

/// A secured text field for passwords, passphrases and recovery keys.
///
/// Content is always masked on first paint. A reveal is an explicit,
/// single-tap action and re-masks itself after [revealDuration] so a secret can
/// never stay on screen by accident when the user walks away.
class KeyelPasswordField extends StatefulWidget {
  /// Creates a password field.
  const new({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.autofillHints = const [],
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.keyboardType,
    this.horizontalPadding = KeyelSpacing.lg,
    super.key,
  });

  /// How long a revealed value stays visible before re-masking.
  static const revealDuration = Duration(seconds: 15);

  /// Text controller owned by the caller.
  final TextEditingController controller;

  /// Field label.
  final String label;

  /// Placeholder inside the field.
  final String? hint;

  /// Optional validator.
  final String? Function(String?)? validator;

  /// Platform autofill hints (empty for `newPassword`-style secrets).
  final List<String> autofillHints;

  /// Action for the software keyboard.
  final TextInputAction textInputAction;

  /// Invoked when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Keyboard type override (for example passphrase word completion).
  final TextInputType? keyboardType;

  /// Horizontal padding, matching sibling inputs.
  final double horizontalPadding;

  @override
  State<KeyelPasswordField> createState() => _KeyelPasswordFieldState();
}

class _KeyelPasswordFieldState extends State<KeyelPasswordField> {
  bool _obscure = true;
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  void _toggleReveal() {
    setState(() {
      _obscure = !_obscure;
      _revealTimer?.cancel();
      _revealTimer = null;
      if (!_obscure) {
        _revealTimer = Timer(KeyelPasswordField.revealDuration, () {
          if (!mounted) return;
          setState(() {
            _obscure = true;
            _revealTimer = null;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        style: textTheme.bodyLarge,
        autofillHints: widget.autofillHints,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KeyelRadii.field),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            onPressed: _toggleReveal,
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 22,
            ),
            tooltip: _obscure ? 'Show password' : 'Hide password',
          ),
        ),
      ),
    );
  }
}
