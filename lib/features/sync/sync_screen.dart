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
import 'package:keyel/ui/l10n/l10n.dart';

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
    final l10n = l10nOf(context);
    final folder = await ref.read(syncFolderServiceProvider).pickFolder();
    if (folder == null || folder.isEmpty) {
      if (mounted) {
        showKeyelSnack(
          context,
          l10n.synChooseFolderFirst,
          icon: Icons.folder_off_outlined,
        );
      }
      return null;
    }
    return folder;
  }

  Future<void> _enable() async {
    final l10n = l10nOf(context);
    final folder = await _pickFolder();
    if (folder == null) return;
    await _run(() async {
      final code = await ref.read(vaultRepositoryProvider).syncEnable(folder);
      await _load();
      if (!mounted) return;
      final saved = await _showPairingCode(code);
      if (saved == true && mounted) {
        showKeyelSnack(context, l10n.synEnabledShareCode);
      }
    });
  }

  Future<void> _join() async {
    final l10n = l10nOf(context);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showKeyelSnack(
        context,
        l10n.synEnterCodeFirst,
        icon: Icons.key_off_outlined,
      );
      return;
    }
    final folder = await _pickFolder();
    if (folder == null || !mounted) return;
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.synJoinTitle,
      body: l10n.synJoinBody,
      confirmLabel: l10n.synJoinGroup,
    );
    if (!confirmed) return;
    await _run(() async {
      await ref.read(vaultRepositoryProvider).syncJoin(code, folder);
      _codeController.clear();
      await _load();
      if (mounted) showKeyelSnack(context, l10n.synJoined);
    });
  }

  Future<void> _syncNow() async {
    final l10n = l10nOf(context);
    final folder = _status?.folderHint;
    if (folder == null || folder.isEmpty) {
      showKeyelSnack(
        context,
        l10n.synNoFolder,
        icon: Icons.folder_off_outlined,
      );
      return;
    }
    await _run(() async {
      final report = await ref.read(vaultRepositoryProvider).syncNow(folder);
      await _load();
      if (!mounted) return;
      final conflicts = report.conflictsCreated == 0
          ? ''
          : l10n.synConflictCopies(report.conflictsCreated);
      showKeyelSnack(
        context,
        l10n.synComplete(report.entriesAdded, report.entriesUpdated, conflicts),
      );
    });
  }

  Future<void> _disable() async {
    final l10n = l10nOf(context);
    final confirmed = await KeyelConfirmDialog.show(
      context,
      title: l10n.synDisableTitle,
      body: l10n.synDisableBody,
      confirmLabel: l10n.synDisableConfirm,
      destructive: true,
    );
    if (!confirmed) return;
    await _run(() async {
      await ref.read(vaultRepositoryProvider).syncDisable();
      await _load();
      if (mounted) showKeyelSnack(context, l10n.synDisabled);
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
          title: Text(l10nOf(context).synSaveCodeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10nOf(context).synSaveCodeBody),
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
                          l10nOf(context).synCodeCopied(
                            SensitiveClipboard.instance.clearHint,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(l10nOf(context).actionCopy),
                  ),
                ],
              ),
              CheckboxListTile(
                value: saved,
                onChanged: (value) => setState(() => saved = value ?? false),
                title: Text(l10nOf(context).synCodeStoredCheckbox),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: saved ? () => Navigator.of(context).pop(true) : null,
              child: Text(l10nOf(context).actionDone),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSyncLabel(SyncStatusDto status) {
    if (status.lastSyncAt == BigInt.zero) return currentL10n.synNever;
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
    final l10n = l10nOf(context);
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
                  title: l10n.syncTitle,
                  icon: context.backArrow,
                  iconTooltip: l10n.actionBack,
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
                        l10n.synHeadline,
                        style: textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.synSubtitle,
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
                    KeyelSectionLabel(
                      label: l10n.synStatusLabel,
                      icon: Icons.sync_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          icon: enabled
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          title: enabled
                              ? l10n.synEnabledStatus
                              : l10n.synOffStatus,
                          subtitle: _loading
                              ? l10n.synLoadingStatus
                              : enabled
                              ? l10n.synLastSync(_lastSyncLabel(status!))
                              : l10n.synLocalOnlyStatus,
                        ),
                        if (enabled && status != null) ...[
                          SettingsRow(
                            icon: Icons.folder_open_outlined,
                            title: l10n.synFolderLabel,
                            subtitle: status.folderHint.isEmpty
                                ? l10n.synNotSet
                                : status.folderHint,
                          ),
                          SettingsRow(
                            icon: Icons.devices_outlined,
                            title: l10n.synThisDevice,
                            subtitle: status.deviceId ?? l10n.synUnknown,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: KeyelSpacing.lg),
                    KeyelSectionLabel(
                      label: enabled
                          ? l10n.synActionsLabel
                          : l10n.synGetStartedLabel,
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: KeyelSpacing.sm),
                    SettingsCard(
                      children: [
                        if (!enabled) ...[
                          SettingsRow(
                            icon: Icons.add_link_rounded,
                            title: l10n.synCreateGroupTitle,
                            subtitle: l10n.synCreateGroupSubtitle,
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
                                Text(
                                  l10n.synOrJoin,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                KeyelPasswordField(
                                  controller: _codeController,
                                  label: l10n.synPairingCodeLabel,
                                  hint: 'KYSYNC1-…',
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: context.alignEnd,
                                  child: FilledButton(
                                    onPressed: _busy ? null : _join,
                                    child: Text(l10n.synJoinGroup),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SettingsRow(
                            icon: Icons.sync_rounded,
                            title: l10n.synSyncNowTitle,
                            subtitle: l10n.synSyncNowSubtitle,
                            onTap: _busy ? null : _syncNow,
                          ),
                          SettingsRow(
                            icon: Icons.key_outlined,
                            title: l10n.synShowCodeTitle,
                            subtitle: l10n.synShowCodeSubtitle,
                            onTap: _busy ? null : _showCodeAgain,
                          ),
                          SettingsRow(
                            icon: Icons.link_off_outlined,
                            title: l10n.synDisableConfirm,
                            subtitle: l10n.synDisableSubtitle,
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
                        l10n.synFooterNote,
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
