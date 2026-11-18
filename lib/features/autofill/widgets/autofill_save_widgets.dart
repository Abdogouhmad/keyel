import 'package:flutter/material.dart';

import 'package:keyel/ui/keyel.dart';

/// Form fields for saving a captured login.
class AutofillSaveForm extends StatelessWidget {
  /// Creates the autofill save form.
  const new({
    required this.titleController,
    required this.usernameController,
    required this.passwordController,
    required this.targetLabel,
    required this.error,
    super.key,
  });

  /// Controller for the login name.
  final TextEditingController titleController;

  /// Controller for the username.
  final TextEditingController usernameController;

  /// Controller for the password.
  final TextEditingController passwordController;

  /// Human-readable target app or site.
  final String targetLabel;

  /// Validation or save error message.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: KeyelSpacing.lg),
      children: [
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
                Icons.save_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: KeyelSpacing.xs),
              Expanded(
                child: Text(
                  'Store these credentials for $targetLabel',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
          child: TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: KeyelSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.lg),
          child: TextField(
            controller: usernameController,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: KeyelSpacing.md),
        KeyelPasswordField(
          controller: passwordController,
          label: 'Password',
          textInputAction: TextInputAction.done,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KeyelSpacing.lg,
              KeyelSpacing.md,
              KeyelSpacing.lg,
              0,
            ),
            child: Text(
              error!,
              style: textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

/// Bottom action buttons for the autofill save screen.
class AutofillSaveActions extends StatelessWidget {
  /// Creates save/cancel actions.
  const new({
    required this.saving,
    required this.onSave,
    required this.onDecline,
    super.key,
  });

  /// Whether a save is in progress.
  final bool saving;

  /// Saves the login.
  final VoidCallback onSave;

  /// Declines saving.
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KeyelSpacing.lg,
        KeyelSpacing.xs,
        KeyelSpacing.lg,
        KeyelSpacing.md,
      ),
      child: Column(
        children: [
          KeyelPillButton(
            label: 'Save login',
            icon: Icons.check_rounded,
            height: 48,
            onPressed: saving ? null : onSave,
          ),
          const SizedBox(height: KeyelSpacing.xs),
          KeyelPillButton(
            label: 'Not now',
            tone: KeyelButtonTone.neutral,
            height: 48,
            onPressed: saving ? null : onDecline,
          ),
        ],
      ),
    );
  }
}
