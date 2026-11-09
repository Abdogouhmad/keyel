import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Card number, cardholder and expiry block for card entries.
class CardDetails extends StatelessWidget {
  /// Creates the card details block.
  const new({
    required this.entry,
    required this.detail,
    required this.revealedNumber,
    required this.revealedCvv,
    required this.onToggleReveal,
    required this.onCopy,
    super.key,
  });

  /// Entry being displayed.
  final VaultEntry entry;

  /// Detail record of the entry.
  final EntryDetailDto detail;

  /// Plaintext card number when revealed, otherwise `null`.
  final String? revealedNumber;

  /// Plaintext security code when revealed, otherwise `null`.
  final String? revealedCvv;

  /// Called to reveal or hide the card number.
  final VoidCallback onToggleReveal;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final card = detail.card;
    final isRevealed = revealedNumber != null;
    final displayNum = isRevealed ? revealedNumber! : '•••• •••• •••• ••••';

    return KeyelSectionCard(
      title: 'Card details',
      icon: Icons.credit_card_rounded,
      showBorder: true,
      child: Column(
        children: [
          KeyelFieldSurface(
            label: 'Card number',
            trailing: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyelIconHull(
                    icon: isRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    tooltip: isRevealed ? 'Hide number' : 'Reveal number',
                    onPressed: onToggleReveal,
                    size: 44,
                    iconSize: 20,
                  ),
                  KeyelIconHull(
                    icon: Icons.content_copy_rounded,
                    tooltip: 'Copy card number',
                    onPressed: () => onCopy(
                      revealedNumber ?? '',
                      'Card number copied to clipboard',
                    ),
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            child: Text(
              displayNum,
              style: KeyelTheme.mono(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
          if ((card?.cardholder ?? '').isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            KeyelFieldSurface(
              label: 'Cardholder name',
              trailing: KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy cardholder',
                onPressed: () =>
                    onCopy(card!.cardholder, 'Cardholder name copied'),
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                card!.cardholder,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if ((card?.expiry ?? '').isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            Row(
              children: [
                Expanded(
                  child: KeyelFieldSurface(
                    label: 'Expires',
                    child: Text(
                      card!.expiry,
                      style: KeyelTheme.mono(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Expanded(
                  child: KeyelFieldSurface(
                    label: 'Security code (CVV)',
                    child: Text(
                      revealedCvv ?? '•••',
                      style: KeyelTheme.mono(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
