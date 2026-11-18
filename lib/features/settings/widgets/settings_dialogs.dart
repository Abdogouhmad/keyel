import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/ui/keyel.dart';

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
        var verifying = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Confirm master password'),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              enabled: !verifying,
              decoration: InputDecoration(
                labelText: 'Master password',
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
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: verifying
                    ? null
                    : () async {
                        if (controller.text.isEmpty) {
                          setState(() => errorText = 'Password required');
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
                              errorText = 'Incorrect password';
                            });
                            return;
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(controller.text);
                          }
                        } on Object {
                          setState(() {
                            verifying = false;
                            errorText = 'Verification failed';
                          });
                        }
                      },
                child: verifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
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
  if (delay == Duration.zero) return 'Immediately';
  if (delay.inSeconds < 60) return 'After ${delay.inSeconds} seconds';
  final minutes = delay.inMinutes;
  return 'After $minutes ${minutes == 1 ? "minute" : "minutes"}';
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
      title: const Text('Auto-lock after'),
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
  if (seconds <= 0) return 'Never';
  if (seconds < 60) return '$seconds seconds';
  final minutes = seconds ~/ 60;
  return '$minutes ${minutes == 1 ? "minute" : "minutes"}';
}

/// Shows the clipboard clear timeout picker.
Future<void> showClipboardDialog(BuildContext context) async {
  final prefs = AppPreferences.instance;
  final current = prefs.clipboardClearSeconds;
  const options = [15, 30, 60, 0];

  final selected = await showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Clear clipboard after'),
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Change Master Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Master Password',
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Master Password',
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Master Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                showKeyelSnack(dialogCtx, 'New passwords do not match.');
                return;
              }
              if (newController.text.isEmpty) {
                showKeyelSnack(dialogCtx, 'New password cannot be empty.');
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
                showKeyelSnack(context, 'Master password changed successfully');
              } on Object catch (error) {
                if (dialogCtx.mounted) {
                  showKeyelSnack(dialogCtx, describeVaultError(error));
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
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
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Factory Reset?'),
        ],
      ),
      content: const Text(
        'This will permanently delete your vault file and all stored '
        'credentials. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete Everything'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

/// Formatters reused by the settings UI.
String autoLockLabel(Duration delay) => _autoLockLabel(delay);

/// Formatters reused by the settings UI.
String clipboardLabel(int seconds) => _clipboardLabel(seconds);
