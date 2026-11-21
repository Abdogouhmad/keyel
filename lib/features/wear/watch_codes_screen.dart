import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/wear/watch_totp_service.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Settings surface for the opt-in Wear OS TOTP companion.
///
/// Sending a seed requires an unlocked vault: [WatchTotpService.pushEntry]
/// reveals the field through the normal repository gate. The screen itself
/// never sees a secret value.
class WatchCodesScreen extends ConsumerStatefulWidget {
  /// Creates the watch-codes screen.
  const new({super.key});

  @override
  ConsumerState<WatchCodesScreen> createState() => _WatchCodesScreenState();
}

class _WatchCodesScreenState extends ConsumerState<WatchCodesScreen> {
  late final WatchTotpService _service;
  List<EntrySummaryDto> _entries = const [];
  bool _available = false;
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _service = WatchTotpService(repository: ref.read(vaultRepositoryProvider));
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final available = await _service.bridge.available;
    final entries = await ref.read(vaultRepositoryProvider).listEntries();
    if (!mounted) return;
    setState(() {
      _available = available;
      _entries = entries.where((entry) => entry.hasTotp).toList();
      _loading = false;
    });
  }

  Future<void> _send(EntrySummaryDto entry) async {
    setState(() => _busyId = entry.id);
    final l10n = l10nOf(context);
    final ok = await _service.pushEntry(entry.id);
    if (!mounted) return;
    setState(() => _busyId = null);
    showKeyelSnack(
      context,
      ok ? l10n.wearSent : l10n.wearFailed,
      icon: ok ? Icons.watch_rounded : Icons.error_outline_rounded,
    );
  }

  Future<void> _clearAll() async {
    final l10n = l10nOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wearClearTitle),
        content: Text(l10n.wearClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.wearClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _service.clearWatch();
    if (!mounted) return;
    showKeyelSnack(
      context,
      ok ? l10n.wearCleared : l10n.wearFailed,
      icon: ok ? Icons.check_circle_outline : Icons.error_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wearTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  KeyelSectionCard(
                    icon: Icons.watch_rounded,
                    title: l10n.wearTitle,
                    child: Text(
                      _available ? l10n.wearInfo : l10n.wearUnavailable,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          l10n.wearEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ..._entries.map(
                      (entry) => ListTile(
                        leading: const Icon(Icons.password_outlined),
                        title: Text(entry.title),
                        subtitle: Text(entry.subtitle),
                        trailing: _busyId == entry.id
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton(
                                onPressed: _available
                                    ? () => _send(entry)
                                    : null,
                                child: Text(l10n.wearSend),
                              ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _available ? _clearAll : null,
                    icon: const Icon(Icons.watch_off_outlined),
                    label: Text(l10n.wearClearAll),
                  ),
                ],
              ),
      ),
    );
  }
}
