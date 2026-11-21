import 'package:flutter/material.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// An informational tip widget explaining the benefits of passphrases.
class PassphraseTip extends StatelessWidget {
  /// Creates a passphrase tip widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(KeyelRadii.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: KeyelSpacing.sm + 4),
          Expanded(
            child: Text(
              l10nOf(context).genPassphraseTip,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
