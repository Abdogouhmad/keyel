import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/settings/widgets/settings_widgets.dart';
import 'package:keyel/features/sync/sync_folder_service.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Opt-in, manual, end-to-end encrypted sync across devices.
///
/// The UI only sees non-secret status/report DTOs and the pairing code the
/// user explicitly asked to display. Keys and plaintext never cross the bridge.
class SyncScreen extends ConsumerStatefulWidget {
  /// Creates the sync settings screen.
  const new({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _codeController = TextEditingController();
  SyncStatusDto? _status;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _codeController.dispose();
    SensitiveClipboard.instance.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await ref.read(vaultRepositoryProvider).syncStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(error);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    showKeyelSnack(
      context,
      describeVaultError(error),
      icon: Icons.error_outline_rounded,
    );
  }

  Future<String?> _pickFolder() async {
    final folder = await ref.read(syncFolderServiceProvider).pickFolder();
    if (folder == null || folder.isEmpty) {
      if (mounted) {
        showKeyelSnack(
          context,
          'Choose a sync folder first.',
          icon: Icons.folder_off_outlined,
        );
      }
      return null;
    }
    return folder;
  }

  Future<void> _enable() async {
    final folder = await _pickFolder();
    if (folder == null) return;
    await _run(() async {
      final code = await ref.read(vaultRepositoryProvider).syncEnable(folder);
      await _load();
      if (!mounted) return;
      final saved = await _showPairingCode(code);
      if (saved == true && mounted) {
        showKeyelSnack(
          context,
          'Sync enabled. Share the code with your other device only once.',
        );
      }
    });
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showKeyelSnack(
        context,
        'Enter the pairing code first.',
        icon: Icons.key_off_outlined,
      );
      return;
    }
    final folder = await _pickFolder();
    if (folder == null || !mounted) return;
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: 'Join this sync group?',
      body:
          'Remote vault data will be merged with this vault on the next '
          'manual sync. Conflicting items become separate copies; nothing is '
          'silently overwritten or deleted.',
      confirmLabel: 'Join group',
    );
    if (!confirmed) return;
    await _run(() async {
      await ref.read(vaultRepositoryProvider).syncJoin(code, folder);
      _codeController.clear();
      await _load();
      if (mounted) showKeyelSnack(context, 'Joined the sync group.');
    });
  }

  Future<void> _syncNow() async {
    final folder = _status?.folderHint;
    if (folder == null || folder.isEmpty) {
      showKeyelSnack(
        context,
        'Sync has no folder set. Disable and enable it again.',
        icon: Icons.folder_off_outlined,
      );
      return;
    }
    await _run(() async {
      final report = await ref.read(vaultRepositoryProvider).syncNow(folder);
      await _load();
      if (!mounted) return;
      final conflicts = switch (report.conflictsCreated) {
        0 => '',
        1 => ', 1 conflict copy',
        final count => ', $count conflict copies',
      };
      showKeyelSnack(
        context,
        'Sync complete: ${report.entriesAdded} added, '
        '${report.entriesUpdated} updated$conflicts.',
      );
    });
  }

  Future<void> _disable() async {
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: 'Disable sync?',
      body:
          'Local sync stops. Remote files are left untouched and can be '
          'restored by joining again with the pairing code.',
      confirmLabel: 'Disable sync',
      destructive: true,
    );
    if (!confirmed) return;
    await _run(() async {
      await ref.read(vaultRepositoryProvider).syncDisable();
      await _load();
      if (mounted) showKeyelSnack(context, 'Sync disabled on this device.');
    });
  }

  Future<void> _showCodeAgain() async {
    await _run(() async {
      final code = await ref.read(vaultRepositoryProvider).syncPairingCode();
      if (!mounted) return;
      await _showPairingCode(code);
    });
  }

  Future<bool?> _showPairingCode(String code) {
    var saved = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Save this pairing code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This code is a bearer secret: anyone who has it can read the '
                'synced vault. Store it offline and enter it on your other '
                'device once. It will not be shown again after this dialog.',
              ),
              const SizedBox(height: 16),
              SelectableText(
                code,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: KeyelTheme.monoFamily),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await SensitiveClipboard.instance.copy(code);
                      if (context.mounted) {
                        showKeyelSnack(
                          context,
                          'Pairing code copied${SensitiveClipboard.instance.clearHint}',
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              CheckboxListTile(
                value: saved,
                onChanged: (value) => setState(() => saved = value ?? false),
                title: const Text('I stored this code somewhere safe'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: saved ? () => Navigator.of(context).pop(true) : null,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSyncLabel(SyncStatusDto status) {
    if (status.lastSyncAt == BigInt.zero) return 'Never';
    final date = DateTime.fromMillisecondsSinceEpoch(
      status.lastSyncAt.toInt() * 1000,
      isUtc: true,
    ).toLocal();
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = _status;
    final enabled = status?.enabled ?? false;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: KeyelContent(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: KeyelTopBar(
                  title: 'Sync',
                  icon: Icons.arrow_back_rounded,
                  onIconTap: () => context.pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KeyelSpacing.lg,
                  KeyelSpacing.xs,
                  KeyelSpacing.lg,
                  KeyelSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync across your devices',
                        style: textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optional, manual and end-to-end encrypted. Keyel '
                        'never runs a sync server: your own sync tool moves '
                        'the encrypted files between devices.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.md,
                ),
                sliver: SliverList.list(
                  children: [
                    const KeyelSectionLabel(
                      label: 'Status',
                      icon: Icons.sync_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: enabled
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          title: enabled ? 'Sync enabled' : 'Sync is off',
                          subtitle: _loading
                              ? 'Reading sync state…'
                              : enabled
                              ? 'Last sync: ${_lastSyncLabel(status!)}'
                              : 'Your vault stays on this device only.',
                        ),
                        if (enabled && status != null) ...[
                          SettingsRow(
                            icon: Icons.folder_open_outlined,
                            title: 'Folder',
                            subtitle: status.folderHint.isEmpty
                                ? 'Not set'
                                : status.folderHint,
                          ),
                          SettingsRow(
                            icon: Icons.devices_outlined,
                            title: 'This device',
                            subtitle: status.deviceId ?? 'Unknown',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    KeyelSectionLabel(
                      label: enabled ? 'Actions' : 'Get started',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        if (!enabled) ...[
                          SettingsRow(
                            icon: Icons.add_link_rounded,
                            title: 'Create a sync group',
                            subtitle: 'Pick a folder and get a one-time pairing code.',
                            onTap: _busy ? null : _enable,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              KeyelSpacing.lg,
                              KeyelSpacing.sm,
                              KeyelSpacing.lg,
                              KeyelSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Or join an existing group',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                KeyelPasswordField(
                                  controller: _codeController,
                                  label: 'Pairing code',
                                  hint: 'KYSYNC1-…',
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: _busy ? null : _join,
                                    child: const Text('Join group'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SettingsRow(
                            icon: Icons.sync_rounded,
                            title: 'Sync now',
                            subtitle: 'Pull remote changes, merge and push this device.',
                            onTap: _busy ? null : _syncNow,
                          ),
                          SettingsRow(
                            icon: Icons.key_outlined,
                            title: 'Show pairing code',
                            subtitle:
                                'Pair another device with this sync group.',
                            onTap: _busy ? null : _showCodeAgain,
                          ),
                          SettingsRow(
                            icon: Icons.link_off_outlined,
                            title: 'Disable sync',
                            subtitle: 'Stop syncing on this device; keep remote files.',
                            onTap: _busy ? null : _disable,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KeyelSpacing.sm,
                      ),
                      child: Text(
                        'Sync is foreground-only and requires an unlocked '
                        'vault. Data is encrypted with a random key that never '
                        'leaves Keyel; losing the pairing code means starting '
                        'a new sync group. Keep an encrypted backup as well.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: KeyelSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
