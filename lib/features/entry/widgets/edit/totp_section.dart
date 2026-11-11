import 'package:flutter/material.dart';

import 'package:keyel/features/entry/widgets/edit/section.dart';
import 'package:keyel/ui/keyel.dart';

/// TOTP onboarding block with scan and manual-entry actions.
class TotpSection extends StatelessWidget {
  /// Creates the TOTP section.
  const new({
    required this.onScan,
    required this.onManual,
    this.configured = false,
    super.key,
  });

  /// Called when the scan QR code button is tapped.
  final VoidCallback onScan;

  /// Called when the manual entry button is tapped.
  final VoidCallback onManual;

  /// Whether the entry already has a TOTP secret.
  final bool configured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return EditSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phonelink_lock_rounded,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Expanded(
                child: Text(
                  'Two-factor authentication',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              KeyelBadge(
                label: configured ? 'Configured' : 'TOTP',
                background: configured
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHigh,
                foreground: configured
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: KeyelSpacing.sm),
          Text(
            configured
                ? 'A rotating code is stored for this entry. Enter a new key '
                      'to replace it.'
                : 'Generate integrated 30-second rotating security codes '
                      'directly inside Keyel.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KeyelSpacing.md),
          Row(
            children: [
              Expanded(
                child: KeyelPillButton(
                  label: 'Scan QR Code',
                  icon: Icons.qr_code_scanner_rounded,
                  tone: KeyelButtonTone.neutral,
                  height: 48,
                  onPressed: onScan,
                ),
              ),
              const SizedBox(width: KeyelSpacing.sm),
              Expanded(
                child: KeyelPillButton(
                  label: configured ? 'Replace Key' : 'Enter Manually',
                  icon: Icons.keyboard_rounded,
                  tone: KeyelButtonTone.neutral,
                  height: 48,
                  onPressed: onManual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
