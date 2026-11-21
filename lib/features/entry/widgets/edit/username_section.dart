import 'package:flutter/material.dart';

import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Username field with an example suggestion chip for login entries.
class UsernameSection extends StatelessWidget {
  /// Creates the username section.
  const new({required this.controller, required this.onSuggestion, super.key});

  /// Controller for the username field.
  final TextEditingController controller;

  /// Called when the suggestion chip is tapped.
  final VoidCallback onSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);

    return EditSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.entryUsernameOrEmail,
              hintText: 'username@domain.com',
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          Row(
            children: [
              Text(
                l10n.entrySuggestion,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              PressableScale(
                onTap: onSuggestion,
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
                semanticLabel: l10n.entryUseSuggestedEmail,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 14,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: KeyelSpacing.xs),
                      Text(
                        'alex.dev@hey.com',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
