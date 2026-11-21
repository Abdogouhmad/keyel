import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Password field with reveal, generate and strength meter controls.
class PasswordSection extends StatelessWidget {
  /// Creates the password section.
  const new({
    required this.controller,
    required this.strength,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    required this.onGenerate,
    super.key,
  });

  /// Controller for the password field.
  final TextEditingController controller;

  /// Strength estimate of the current password.
  final PasswordStrength strength;

  /// Whether the password text is hidden.
  final bool obscure;

  /// Called to toggle password visibility.
  final VoidCallback onToggleObscure;

  /// Called on each password text change.
  final ValueChanged<String> onChanged;

  /// Called to generate a fresh password.
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return EditSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: KeyelSpacing.xs + 2),
              Expanded(
                child: Text(
                  l10n.entryMasterCredentials,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              PressableScale(
                onTap: () => showKeyelSnack(
                  context,
                  l10n.entryPasswordHistorySoon,
                  icon: Icons.history_rounded,
                ),
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.entryHistory,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: KeyelTheme.mono(context, fontSize: 16, letterSpacing: 0.6),
            decoration: InputDecoration(
              labelText: l10n.fieldPassword,
              hintText: l10n.entryEnterPassword,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 88,
                minHeight: 48,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyelIconHull(
                    icon: obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    tooltip: obscure
                        ? l10n.entryRevealPassword
                        : l10n.entryHidePassword,
                    onPressed: onToggleObscure,
                    size: 44,
                    iconSize: 20,
                  ),
                  KeyelIconHull(
                    icon: Icons.shuffle_rounded,
                    tooltip: l10n.entryGeneratePasswordTooltip,
                    onPressed: onGenerate,
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelStrengthMeter(strength: strength, showHint: false),
          const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelPillButton(
            label: l10n.entryGenerateSecurePassword,
            icon: Icons.auto_awesome_rounded,
            tone: KeyelButtonTone.tonal,
            height: 48,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }
}
