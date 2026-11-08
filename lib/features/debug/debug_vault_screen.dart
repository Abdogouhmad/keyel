import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_repository.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Temporary debug screen for roadmap 0.4.0.
///
/// It exercises the real Rust vault through the FRB bridge: create, unlock,
/// add a login, list, reveal, trash/restore and lock. It is intentionally
/// plain; the real onboarding and vault UI arrive in later phases.
class DebugVaultScreen extends ConsumerStatefulWidget {
  /// Creates the debug screen.
  const new({super.key});

  @override
  ConsumerState<DebugVaultScreen> createState() => _DebugVaultScreenState();
}

class _DebugVaultScreenState extends ConsumerState<DebugVaultScreen> {
  final _master = TextEditingController();
  final _recovery = TextEditingController();
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _search = TextEditingController();
  final _oldMaster = TextEditingController();
  final _newMaster = TextEditingController();

  List<EntrySummaryDto> _entries = const [];
  bool _loading = false;
  bool _showTrash = false;
  bool _showRecoveryUnlock = false;
  String? _revealed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(vaultSessionProvider).status;
      if (status == VaultStatus.unlocked) {
        unawaited(_loadEntries());
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _recovery.dispose();
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _search.dispose();
    _oldMaster.dispose();
    _newMaster.dispose();
    super.dispose();
  }

  VaultRepository get _repository => ref.read(vaultRepositoryProvider);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        showKeyelSnack(
          context,
          describeVaultError(error),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _create() async {
    final master = _master.text;
    if (master.isEmpty) {
      showKeyelSnack(context, 'Enter a master password first.');
      return;
    }
    await _guard(() async {
      final recovery = await ref
          .read(vaultSessionProvider.notifier)
          .create(master);
      _master.clear();
      _password.clear();
      await _loadEntries();
      if (mounted && recovery != null) {
        await _showRecoveryKey(recovery);
      }
    });
  }

  Future<void> _unlock({required bool recovery}) async {
    final value = recovery ? _recovery.text : _master.text;
    if (value.isEmpty) {
      showKeyelSnack(
        context,
        recovery ? 'Enter the recovery key.' : 'Enter the master password.',
      );
      return;
    }
    await _guard(() async {
      final notifier = ref.read(vaultSessionProvider.notifier);
      if (recovery) {
        await notifier.unlockWithRecovery(value);
        _recovery.clear();
      } else {
        await notifier.unlockWithMaster(value);
        _master.clear();
      }
      await _loadEntries();
    });
  }

  Future<void> _addLogin() async {
    final title = _title.text.trim();
    final password = _password.text;
    if (title.isEmpty || password.isEmpty) {
      showKeyelSnack(context, 'Title and password are required.');
      return;
    }
    await _guard(() async {
      await _repository.createLogin(
        title: title,
        username: _username.text.trim(),
        password: password,
        url: _url.text.trim(),
      );
      _title.clear();
      _username.clear();
      _password.clear();
      _url.clear();
      await _loadEntries();
    });
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final entries = await _repository.listEntries(
        query: _search.text,
        includeDeleted: _showTrash,
      );
      if (mounted) {
        setState(() => _entries = entries);
      }
    } on Object catch (error) {
      if (mounted) {
        showKeyelSnack(
          context,
          describeVaultError(error),
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reveal(EntrySummaryDto entry) async {
    await _guard(() async {
      final secret = await _repository.revealField(
        entry.id,
        SecretFieldDto.loginPassword,
      );
      if (!mounted) return;
      setState(() => _revealed = secret);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Password · ${entry.title}'),
          content: SelectableText(
            secret,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() => _revealed = null);
      }
    });
  }

  Future<void> _toggleDeleted(EntrySummaryDto entry) async {
    await _guard(() async {
      if (entry.deletedAt != null) {
        await _repository.restoreEntry(entry.id);
      } else {
        await _repository.deleteEntry(entry.id);
      }
      await _loadEntries();
    });
  }

  Future<void> _changeMaster() async {
    if (_oldMaster.text.isEmpty || _newMaster.text.isEmpty) {
      showKeyelSnack(context, 'Enter the old and new master password.');
      return;
    }
    await _guard(() async {
      await ref
          .read(vaultSessionProvider.notifier)
          .changeMaster(
            oldMaster: _oldMaster.text,
            newMaster: _newMaster.text,
          );
      _oldMaster.clear();
      _newMaster.clear();
      if (mounted) {
        showKeyelSnack(context, 'Master password changed.');
      }
    });
  }

  Future<void> _showRecoveryKey(String recoveryKey) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recovery key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store this offline. It is shown once and unlocks the vault if '
              'you forget the master password.',
            ),
            const SizedBox(height: 16),
            SelectableText(
              recoveryKey,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('I stored it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vaultSessionProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Vault bridge (debug)'),
        backgroundColor: scheme.surface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KeyelSpacing.md),
          children: [
            _StatusCard(session: session, path: _repository.vaultPath),
            const SizedBox(height: KeyelSpacing.md),
            if (session.status == VaultStatus.noVault) _buildCreate(scheme),
            if (session.status == VaultStatus.locked) _buildUnlock(scheme),
            if (session.status == VaultStatus.unlocked) ...[
              _buildAddEntry(scheme),
              const SizedBox(height: KeyelSpacing.md),
              _buildEntries(scheme, session),
              const SizedBox(height: KeyelSpacing.md),
              _buildChangeMaster(scheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(ColorScheme scheme, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildCreate(ColorScheme scheme) {
    return _card(scheme, [
      Text('Create a vault', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KeyelSpacing.sm),
      const Text('Choose a master password. It cannot be recovered.'),
      const SizedBox(height: KeyelSpacing.md),
      TextField(
        key: const ValueKey('debugMaster'),
        controller: _master,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Master password'),
        onSubmitted: (_) => _create(),
      ),
      const SizedBox(height: KeyelSpacing.md),
      FilledButton(
        key: const ValueKey('debugCreate'),
        onPressed: _create,
        child: const Text('Create vault'),
      ),
    ]);
  }

  Widget _buildUnlock(ColorScheme scheme) {
    return _card(scheme, [
      Text('Unlock', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KeyelSpacing.md),
      TextField(
        key: const ValueKey('debugMaster'),
        controller: _master,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Master password'),
        onSubmitted: (_) => _unlock(recovery: false),
      ),
      const SizedBox(height: KeyelSpacing.md),
      FilledButton(
        key: const ValueKey('debugUnlock'),
        onPressed: () => _unlock(recovery: false),
        child: const Text('Unlock'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextButton.icon(
        onPressed: () =>
            setState(() => _showRecoveryUnlock = !_showRecoveryUnlock),
        icon: Icon(
          _showRecoveryUnlock
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
        ),
        label: const Text('Use recovery key'),
      ),
      if (_showRecoveryUnlock) ...[
        const SizedBox(height: KeyelSpacing.sm),
        TextField(
          controller: _recovery,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Recovery key'),
          onSubmitted: (_) => _unlock(recovery: true),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        OutlinedButton(
          onPressed: () => _unlock(recovery: true),
          child: const Text('Unlock with recovery key'),
        ),
      ],
    ]);
  }

  Widget _buildAddEntry(ColorScheme scheme) {
    return _card(scheme, [
      Text('Add a login', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KeyelSpacing.md),
      TextField(
        key: const ValueKey('debugEntryTitle'),
        controller: _title,
        decoration: const InputDecoration(labelText: 'Title'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextField(
        controller: _username,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextField(
        key: const ValueKey('debugEntryPassword'),
        controller: _password,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextField(
        controller: _url,
        keyboardType: TextInputType.url,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'URL (optional)'),
      ),
      const SizedBox(height: KeyelSpacing.md),
      FilledButton.icon(
        key: const ValueKey('debugAddLogin'),
        onPressed: _addLogin,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add login'),
      ),
    ]);
  }

  Widget _buildEntries(ColorScheme scheme, VaultSessionState session) {
    return _card(scheme, [
      Row(
        children: [
          Expanded(
            child: Text(
              'Entries (${_entries.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadEntries,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Lock now',
            onPressed: () {
              ref.read(vaultSessionProvider.notifier).lock();
              setState(() => _entries = const []);
            },
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      TextField(
        controller: _search,
        decoration: const InputDecoration(
          labelText: 'Search metadata',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (_) => _loadEntries(),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show trashed entries'),
        value: _showTrash,
        onChanged: (value) {
          setState(() => _showTrash = value);
          unawaited(_loadEntries());
        },
      ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(KeyelSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: KeyelSpacing.md),
          child: Text('No entries yet. Add one above.'),
        )
      else
        for (final entry in _entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              switch (entry.kind) {
                EntryKindDto.login => Icons.key_rounded,
                EntryKindDto.card => Icons.credit_card_rounded,
                EntryKindDto.note => Icons.sticky_note_2_rounded,
              },
            ),
            title: Text(entry.title),
            subtitle: Text(
              entry.deletedAt != null
                  ? 'In trash · ${entry.subtitle}'
                  : entry.subtitle,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.kind == EntryKindDto.login && entry.deletedAt == null)
                  IconButton(
                    tooltip: _revealed == null ? 'Reveal password' : 'Reveal',
                    onPressed: () => _reveal(entry),
                    icon: const Icon(Icons.visibility_rounded),
                  ),
                IconButton(
                  tooltip: entry.deletedAt == null ? 'Move to trash' : 'Restore',
                  onPressed: () => _toggleDeleted(entry),
                  icon: Icon(
                    entry.deletedAt == null
                        ? Icons.delete_outline_rounded
                        : Icons.restore_from_trash_rounded,
                  ),
                ),
              ],
            ),
          ),
      if (session.error != null) ...[
        const SizedBox(height: KeyelSpacing.sm),
        Text(
          session.error!,
          style: TextStyle(color: scheme.error),
        ),
      ],
    ]);
  }

  Widget _buildChangeMaster(ColorScheme scheme) {
    return _card(scheme, [
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'Change master password',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          TextField(
            controller: _oldMaster,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          TextField(
            controller: _newMaster,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: KeyelSpacing.md),
          OutlinedButton(
            onPressed: _changeMaster,
            child: const Text('Change master password'),
          ),
        ],
      ),
    ]);
  }
}

class _StatusCard extends StatelessWidget {
  const new({required this.session, required this.path});

  final VaultSessionState session;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (session.status) {
      VaultStatus.noVault => (
        'No vault',
        Icons.add_circle_outline_rounded,
        scheme.onSurfaceVariant,
      ),
      VaultStatus.locked => (
        'Locked',
        Icons.lock_rounded,
        scheme.primary,
      ),
      VaultStatus.unlocked => (
        'Unlocked',
        Icons.lock_open_rounded,
        scheme.tertiary,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(KeyelSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KeyelRadii.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: KeyelSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (path != null)
                  Text(
                    path!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (session.busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
