import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Prompts for the master password and verifies it against the vault.
Future<String?> confirmMasterPassword(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final l10n = l10nOf(dialogContext);
        var verifying = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.prefConfirmMasterTitle),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              enabled: !verifying,
              decoration: InputDecoration(
                labelText: l10n.prefMasterPasswordLabel,
                errorText: errorText,
              ),
              onSubmitted: (value) {
                if (!verifying && value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: verifying
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: verifying
                    ? null
                    : () async {
                        if (controller.text.isEmpty) {
                          setState(() => errorText = l10n.prefPasswordRequired);
                          return;
                        }
                        setState(() {
                          verifying = true;
                          errorText = null;
                        });
                        try {
                          final valid = await ref
                              .read(vaultRepositoryProvider)
                              .verifyMaster(controller.text);
                          if (!valid) {
                            setState(() {
                              verifying = false;
                              errorText = l10n.prefIncorrectPassword;
                            });
                            return;
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(controller.text);
                          }
                        } on Object {
                          setState(() {
                            verifying = false;
                            errorText = l10n.prefVerificationFailed;
                          });
                        }
                      },
                child: verifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.actionContinue),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

String _autoLockLabel(Duration delay) {
  final l10n = currentL10n;
  if (delay == Duration.zero) return l10n.prefAutoLockImmediately;
  if (delay.inSeconds < 60) {
    return l10n.prefAutoLockAfterSeconds(delay.inSeconds);
  }
  final minutes = delay.inMinutes;
  return l10n.prefAutoLockAfterMinutes(minutes);
}

/// Shows the auto-lock delay picker.
Future<void> showAutoLockDialog(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(vaultSessionProvider.notifier);
  final current = notifier.autoLockDelay;

  const options = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  final selected = await showDialog<Duration>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10nOf(dialogContext).prefAutoLockDialogTitle),
      children: [
        for (final option in options)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(option),
            child: Row(
              children: [
                Icon(
                  option == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Text(_autoLockLabel(option)),
              ],
            ),
          ),
      ],
    ),
  );

  if (selected == null) return;
  notifier.setAutoLockDelay(selected);
}

String _clipboardLabel(int seconds) {
  final l10n = currentL10n;
  if (seconds <= 0) return l10n.prefClipboardNever;
  if (seconds < 60) return l10n.prefClipboardSeconds(seconds);
  final minutes = seconds ~/ 60;
  return l10n.prefClipboardMinutes(minutes);
}

/// Shows the clipboard clear timeout picker.
Future<void> showClipboardDialog(BuildContext context) async {
  final prefs = AppPreferences.instance;
  final current = prefs.clipboardClearSeconds;
  const options = [15, 30, 60, 0];

  final selected = await showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10nOf(dialogContext).prefClipboardDialogTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, KeyelSpacing.sm),
          child: Text(l10nOf(dialogContext).prefClipboardDialogBody),
        ),
        for (final option in options)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(option),
            child: Row(
              children: [
                Icon(
                  option == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Text(_clipboardLabel(option)),
              ],
            ),
          ),
      ],
    ),
  );

  if (selected == null) return;
  prefs.clipboardClearSeconds = selected;
  await prefs.save();
}

/// Shows the change-master-password dialog.
Future<void> showChangeMasterDialog(BuildContext context, WidgetRef ref) async {
  final oldController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final l10n = l10nOf(dialogCtx);
        return AlertDialog(
          title: Text(l10n.prefChangeMasterTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.prefCurrentMasterPassword,
                ),
              ),
              const SizedBox(height: KeyelSpacing.sm),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.prefNewMasterPassword,
                ),
              ),
              const SizedBox(height: KeyelSpacing.sm),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.prefConfirmNewMasterPassword,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () async {
                if (newController.text != confirmController.text) {
                  showKeyelSnack(dialogCtx, l10n.prefNewPasswordsMismatch);
                  return;
                }
                if (newController.text.isEmpty) {
                  showKeyelSnack(dialogCtx, l10n.prefNewPasswordEmpty);
                  return;
                }
                try {
                  await ref
                      .read(vaultSessionProvider.notifier)
                      .changeMaster(
                        oldMaster: oldController.text,
                        newMaster: newController.text,
                      );
                  if (!context.mounted || !dialogCtx.mounted) return;
                  Navigator.of(dialogCtx).pop();
                  showKeyelSnack(context, l10n.prefMasterChangedSuccess);
                } on Object catch (error) {
                  if (dialogCtx.mounted) {
                    showKeyelSnack(dialogCtx, describeVaultError(error));
                  }
                }
              },
              child: Text(l10n.prefChangePasswordAction),
            ),
          ],
        );
      },
    );
  } finally {
    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
  }
}

/// Confirms and performs a factory reset (deletes vault and resets state).
Future<bool> confirmFactoryReset(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l10n = l10nOf(ctx);
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.prefFactoryResetTitle),
          ],
        ),
        content: Text(l10n.prefFactoryResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.prefFactoryResetConfirm),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}

/// Formatters reused by the settings UI.
String autoLockLabel(Duration delay) => _autoLockLabel(delay);

/// Formatters reused by the settings UI.
String clipboardLabel(int seconds) => _clipboardLabel(seconds);
