import 'package:flutter/material.dart';

import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/features/entry/widgets/edit/password_section.dart';
import 'package:keyel/features/entry/widgets/edit/totp_section.dart';
import 'package:keyel/features/entry/widgets/edit/username_section.dart';
import 'package:keyel/features/entry/widgets/edit/website_section.dart';
import 'package:keyel/ui/keyel.dart';

/// Stacked login fields: username, password, website and TOTP sections.
class LoginFields extends StatelessWidget {
  /// Creates the stacked login fields.
  const new({
    required this.usernameController,
    required this.onSuggestion,
    required this.passwordController,
    required this.strength,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    required this.onGenerate,
    required this.websiteController,
    required this.onScan,
    required this.onManual,
    super.key,
  });

  /// Controller for the username field.
  final TextEditingController usernameController;

  /// Called when the username suggestion chip is tapped.
  final VoidCallback onSuggestion;

  /// Controller for the password field.
  final TextEditingController passwordController;

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

  /// Controller for the website field.
  final TextEditingController websiteController;

  /// Called when the scan QR code button is tapped.
  final VoidCallback onScan;

  /// Called when the manual TOTP entry button is tapped.
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UsernameSection(
          controller: usernameController,
          onSuggestion: onSuggestion,
        ),
        const SizedBox(height: KeyelSpacing.md),
        PasswordSection(
          controller: passwordController,
          strength: strength,
          obscure: obscure,
          onToggleObscure: onToggleObscure,
          onChanged: onChanged,
          onGenerate: onGenerate,
        ),
        const SizedBox(height: KeyelSpacing.md),
        WebsiteSection(controller: websiteController),
        const SizedBox(height: KeyelSpacing.md),
        TotpSection(onScan: onScan, onManual: onManual),
      ],
    );
  }
}
