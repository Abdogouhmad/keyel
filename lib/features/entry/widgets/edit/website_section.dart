import 'package:flutter/material.dart';

import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Website matcher field for login entries.
class WebsiteSection extends StatelessWidget {
  /// Creates the website section.
  const new({required this.controller, super.key});

  /// Controller for the website field.
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return EditSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10nOf(context).entryWebVaultMatcher,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: KeyelSpacing.sm + 2),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              prefixText: 'https://',
              hintText: 'domain.com',
            ),
          ),
        ],
      ),
    );
  }
}
