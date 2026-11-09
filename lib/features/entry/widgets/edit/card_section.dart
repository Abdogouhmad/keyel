import 'package:flutter/material.dart';

import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/ui/keyel.dart';

/// Card number, expiry and cardholder fields for card entries.
class CardSection extends StatelessWidget {
  /// Creates the card details section.
  const new({
    required this.numberController,
    required this.expiryController,
    required this.cardholderController,
    super.key,
  });

  /// Controller for the card number field.
  final TextEditingController numberController;

  /// Controller for the expiry field.
  final TextEditingController expiryController;

  /// Controller for the cardholder field.
  final TextEditingController cardholderController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return EditSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card details',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          TextField(
            controller: numberController,
            keyboardType: TextInputType.number,
            style: KeyelTheme.mono(context, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Card number',
              hintText: '0000 0000 0000 0000',
            ),
          ),
          const SizedBox(height: KeyelSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: expiryController,
                  style: KeyelTheme.mono(context),
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    hintText: 'MM/YY',
                  ),
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm + 4),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: cardholderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder',
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
