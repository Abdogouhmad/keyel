import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/onboarding/widgets/step_header.dart';
import 'package:keyel/ui/design_system/button_type.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Second onboarding frame: choose and confirm the master password.
///
/// Owns the password controllers and validation; the screen performs the
/// vault creation itself.
class MasterPasswordStep extends StatefulWidget {
  /// Creates the master-password step.
  const new({
    required this.onBack,
    required this.onCreate,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.onBiometricChanged,
    this.busy = false,
    super.key,
  });

  /// Returns to the welcome step.
  final VoidCallback onBack;

  /// Creates the vault with the validated master password.
  final ValueChanged<String> onCreate;

  /// Whether the device has an enrolled biometric the user can opt into.
  final bool biometricAvailable;

  /// Whether the user turned the optional biometric switch on.
  final bool biometricEnabled;

  /// Called when the user flips the biometric switch.
  final ValueChanged<bool>? onBiometricChanged;

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
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingStepHeader(
          title: l10n.vaultCreateMasterPasswordTitle,
          subtitle: l10n.vaultCreateMasterPasswordSubtitle,
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
            labelText: l10n.vaultMasterPasswordLabel,
            labelStyle: TextStyle(color: scheme.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: scheme.onSurfaceVariant,
            ),
            suffixIcon: IconButton(
              tooltip: _obscure
                  ? l10n.vaultShowPassword
                  : l10n.vaultHidePassword,
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
            labelText: l10n.vaultConfirmPassword,
            labelStyle: TextStyle(color: scheme.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.check_circle_outline_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: KeyelSpacing.lg),
        KeyelStrengthMeter(strength: _strength),
        if (widget.biometricAvailable) ...[
          const SizedBox(height: KeyelSpacing.md),
          _BiometricToggle(
            value: widget.biometricEnabled,
            onChanged: widget.onBiometricChanged,
          ),
        ],
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
                label: widget.busy
                    ? l10n.vaultCreatingVault
                    : l10n.actionContinue,
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

/// Optional biometric opt-in shown while the vault is created.
///
/// The switch is only rendered when the device has an enrolled biometric, so
/// the choice is genuinely optional and never blocks vault creation.
class _BiometricToggle extends StatelessWidget {
  const new({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KeyelSpacing.md,
        vertical: KeyelSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.fingerprint_rounded, color: scheme.primary),
          const SizedBox(width: KeyelSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.vaultUnlockWithBiometrics,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.vaultBiometricOptionalHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
