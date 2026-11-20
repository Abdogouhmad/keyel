import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/features/onboarding/widgets/step_header.dart';
import 'package:keyel/ui/design_system/keyel_button.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Third onboarding frame: store the one-time recovery key.
///
/// The key can be copied to the clipboard, or exported as a plain-text file
/// through the platform share sheet (which offers save-to-files as well as
/// sharing destinations).
class RecoveryKeyStep extends StatefulWidget {
  /// Creates the recovery-key step.
  const new({required this.recoveryKey, required this.onContinue, super.key});

  /// The one-time recovery key shown to the user.
  final String recoveryKey;

  /// Advances to the finish step.
  final VoidCallback onContinue;

  @override
  State<RecoveryKeyStep> createState() => _RecoveryKeyStepState();
}

class _RecoveryKeyStepState extends State<RecoveryKeyStep> {
  bool _copied = false;
  bool _savedRecovery = false;

  void _copyKey() {
    unawaited(SensitiveClipboard.instance.copy(widget.recoveryKey));
    setState(() => _copied = true);
    showKeyelSnack(
      context,
      'Recovery key copied to clipboard'
      '${SensitiveClipboard.instance.clearHint}',
      icon: Icons.content_copy_rounded,
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  /// Writes the recovery key to a temporary plain-text file and hands it to
  /// the platform share sheet, which offers saving and sharing targets.
  Future<void> _shareKeyFile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/keyel-recovery-key.txt');
      await file.writeAsString(_recoveryFileText(widget.recoveryKey));
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on Object catch (error) {
      if (!mounted) return;
      showKeyelSnack(
        context,
        'Could not export the recovery key ($error).',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Plain-text document handed to the share sheet.
  String _recoveryFileText(String key) {
    return 'Keyel vault recovery key\n'
        '==========================\n'
        '\n'
        'This file contains the recovery key for your Keyel vault.\n'
        '\n'
        'WARNING: anyone who has this key can unlock your vault. Keep it\n'
        'offline and private, and treat it like the master password itself.\n'
        '\n'
        'If you forget your master password, this key is the only way back\n'
        'into your vault. Keyel has no accounts and no cloud backup.\n'
        '\n'
        'Your recovery key:\n'
        '\n'
        '$key\n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = widget.recoveryKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          title: 'Save your recovery key',
          subtitle:
              'If you forget the master password, this key is the only way '
              'back into your vault. It is shown once.',
        ),
        const SizedBox(height: KeyelSpacing.xl),

        // Recovery Key Display Box with Gradient Border
        AnimatedContainer(
          duration: KeyelMotion.resolve(context, KeyelMotion.medium),
          padding: const EdgeInsets.all(
            1.5,
          ), // This padding becomes the border width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KeyelRadii.card),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _copied
                  ? [
                      Colors.greenAccent.withValues(alpha: 0.8),
                      Colors.green.withValues(alpha: 0.5),
                    ]
                  : [
                      scheme.primary.withValues(alpha: 0.6),
                      scheme.primary.withValues(alpha: 0.1),
                      scheme.outlineVariant.withValues(alpha: 0.5),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (_copied ? Colors.green : scheme.primary).withValues(
                  alpha: 0.08,
                ),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(KeyelSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KeyelRadii.card - 1.5),
              color: scheme.surfaceContainer,
            ),
            child: Column(
              children: [
                SelectableText(
                  key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: KeyelTheme.monoFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    height: 1.6,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: KeyelSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: KeyelSpacing.sm,
                  runSpacing: KeyelSpacing.xs,
                  children: [
                    TextButton.icon(
                      onPressed: _copyKey,
                      icon: Icon(
                        _copied
                            ? Icons.check_rounded
                            : Icons.content_copy_rounded,
                        size: 18,
                        color: _copied ? Colors.greenAccent : scheme.primary,
                      ),
                      label: Text(
                        _copied ? 'Copied!' : 'Copy key',
                        style: TextStyle(
                          color: _copied ? Colors.greenAccent : scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => unawaited(_shareKeyFile()),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save file'),
                    ),
                    TextButton.icon(
                      onPressed: () => unawaited(_shareKeyFile()),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: KeyelSpacing.lg),

        // Custom Checkbox Tile
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _savedRecovery = !_savedRecovery),
            borderRadius: BorderRadius.circular(KeyelRadii.field),
            splashColor: scheme.primary.withValues(alpha: 0.1),
            highlightColor: scheme.primary.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: KeyelMotion.resolve(
                context,
                const Duration(milliseconds: 200),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: KeyelSpacing.md,
                vertical: KeyelSpacing.md,
              ),
              decoration: BoxDecoration(
                color: _savedRecovery
                    ? scheme.primaryContainer.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(KeyelRadii.field),
                border: Border.all(
                  color: _savedRecovery
                      ? scheme.primary.withValues(alpha: 0.5)
                      : scheme.outlineVariant,
                  width: _savedRecovery ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _savedRecovery,
                      onChanged: (value) =>
                          setState(() => _savedRecovery = value ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(
                        color: scheme.onSurfaceVariant,
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: KeyelSpacing.md),
                  Expanded(
                    child: Text(
                      'I stored this key somewhere safe',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: KeyelSpacing.xl),
        KeyelButtonM3(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          isFullWidth: true,
          onPressed: _savedRecovery ? widget.onContinue : null,
        ),
      ],
    );
  }
}
