import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/onboarding/widgets/step_header.dart';
import 'package:keyel/ui/design_system/button_type.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';

/// Second onboarding frame: choose and confirm the master password.
///
/// Owns the password controllers and validation; the screen performs the
/// vault creation itself.
class MasterPasswordStep extends StatefulWidget {
  /// Creates the master-password step.
  const new({
    required this.onBack, required this.onCreate, super.key,
    this.busy = false,
  });

  /// Returns to the welcome step.
  final VoidCallback onBack;

  /// Creates the vault with the validated master password.
  final ValueChanged<String> onCreate;

  /// Whether vault creation is in flight.
  final bool busy;

  @override
  State<MasterPasswordStep> createState() => _MasterPasswordStepState();
}

class _MasterPasswordStepState extends State<MasterPasswordStep> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  PasswordStrength get _strength => PasswordStrength.estimate(_password.text);

  bool get _masterValid =>
      _password.text.length >= 8 &&
      _password.text == _confirm.text &&
      _strength.bits >= 50;

  void _submit() {
    if (!_masterValid || widget.busy) return;
    widget.onCreate(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          title: 'Create your master password',
          subtitle:
              'This is the only key to your vault. We cannot reset it for you.',
        ),
        const SizedBox(height: KeyelSpacing.xl),
        TextField(
          controller: _password,
          obscureText: _obscure,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: scheme.primary,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Master password',
            labelStyle: TextStyle(color: scheme.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: scheme.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: scheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: KeyelSpacing.md),
        TextField(
          controller: _confirm,
          obscureText: _obscure,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: scheme.primary,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Confirm password',
            labelStyle: TextStyle(color: scheme.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.check_circle_outline_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        KeyelStrengthMeter(strength: _strength),
        const SizedBox(height: KeyelSpacing.xl),
        Row(
          children: [
            KeyelButtonM3(
              icon: Icons.arrow_back_rounded,
              type: ButtonType.iconOnly,
              onPressed: widget.busy ? null : widget.onBack,
            ),
            const SizedBox(width: KeyelSpacing.md),
            Expanded(
              child: KeyelButtonM3(
                label: widget.busy ? 'Creating vault…' : 'Continue',
                icon: widget.busy ? null : Icons.arrow_forward_rounded,
                onPressed: widget.busy || !_masterValid ? null : _submit,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
