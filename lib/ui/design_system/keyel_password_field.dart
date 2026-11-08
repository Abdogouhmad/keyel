import 'package:flutter/material.dart';

import 'package:keyel/ui/theme/keyel_theme.dart';

/// A secured text field for passwords, passphrases and recovery keys.
///
/// Content is always masked on first paint and secrets are only ever
/// revealed through an explicit user action on the trailing toggle.
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
            // Reveal is an explicit, single-tap action; mask again on
            // losing the tap — secrets never stay visible by accident.
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 22,
            ),
            tooltip: _obscure ? 'Show password' : 'Hide password',
          ),
        ),
      ),
    );
  }
}
