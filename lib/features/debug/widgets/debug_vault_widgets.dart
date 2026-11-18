import 'package:flutter/material.dart';

import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

/// Status summary card for the debug vault screen.
class DebugStatusCard extends StatelessWidget {
  /// Creates a debug status card.
  const new({required this.session, required this.path, super.key});

  /// Current vault session snapshot.
  final VaultSessionState session;

  /// Vault file path, if known.
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
      VaultStatus.locked => ('Locked', Icons.lock_rounded, scheme.primary),
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

/// Card wrapper used by debug sections.
class DebugCard extends StatelessWidget {
  /// Creates a debug card.
  const new({required this.children, super.key});

  /// Card contents.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
}

/// Vault creation form for the debug screen.
class DebugCreateCard extends StatelessWidget {
  /// Creates the create-vault card.
  const new({
    required this.controller,
    required this.onCreate,
    super.key,
  });

  /// Master password controller.
  final TextEditingController controller;

  /// Creates the vault.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DebugCard(children: [
      Text('Create a vault', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KeyelSpacing.sm),
      const Text('Choose a master password. It cannot be recovered.'),
      const SizedBox(height: KeyelSpacing.md),
      TextField(
        key: const ValueKey('debugMaster'),
        controller: controller,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Master password'),
        onSubmitted: (_) => onCreate(),
      ),
      const SizedBox(height: KeyelSpacing.md),
      FilledButton(
        key: const ValueKey('debugCreate'),
        onPressed: onCreate,
        child: const Text('Create vault'),
      ),
    ]);
  }
}

/// Unlock form for the debug screen.
class DebugUnlockCard extends StatelessWidget {
  /// Creates the unlock card.
  const new({
    required this.masterController,
    required this.recoveryController,
    required this.showRecovery,
    required this.onUnlockMaster,
    required this.onUnlockRecovery,
    required this.onToggleRecovery,
    super.key,
  });

  /// Master password controller.
  final TextEditingController masterController;

  /// Recovery key controller.
  final TextEditingController recoveryController;

  /// Whether recovery unlock UI is visible.
  final bool showRecovery;

  /// Unlocks with master password.
  final VoidCallback onUnlockMaster;

  /// Unlocks with recovery key.
  final VoidCallback onUnlockRecovery;

  /// Toggles recovery UI.
  final VoidCallback onToggleRecovery;

  @override
  Widget build(BuildContext context) {
    return DebugCard(children: [
      Text('Unlock', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KeyelSpacing.md),
      TextField(
        key: const ValueKey('debugMaster'),
        controller: masterController,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Master password'),
        onSubmitted: (_) => onUnlockMaster(),
      ),
      const SizedBox(height: KeyelSpacing.md),
      FilledButton(
        key: const ValueKey('debugUnlock'),
        onPressed: onUnlockMaster,
        child: const Text('Unlock'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextButton.icon(
        onPressed: onToggleRecovery,
        icon: Icon(
          showRecovery ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        ),
        label: const Text('Use recovery key'),
      ),
      if (showRecovery) ...[
        const SizedBox(height: KeyelSpacing.sm),
        TextField(
          controller: recoveryController,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Recovery key'),
          onSubmitted: (_) => onUnlockRecovery(),
        ),
        const SizedBox(height: KeyelSpacing.sm),
        OutlinedButton(
          onPressed: onUnlockRecovery,
          child: const Text('Unlock with recovery key'),
        ),
      ],
    ]);
  }
}

/// Add-login form for the debug screen.
class DebugAddEntryCard extends StatelessWidget {
  /// Creates the add-entry card.
  const new({
    required this.titleController,
    required this.usernameController,
    required this.passwordController,
    required this.urlController,
    required this.onAdd,
    super.key,
  });

  /// Title controller.
  final TextEditingController titleController;

  /// Username controller.
  final TextEditingController usernameController;

  /// Password controller.
  final TextEditingController passwordController;

  /// URL controller.
  final TextEditingController urlController;

  /// Adds the login.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DebugCard(children: [
      Text('Add a login', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KeyelSpacing.md),
      TextField(
        key: const ValueKey('debugEntryTitle'),
        controller: titleController,
        decoration: const InputDecoration(labelText: 'Title'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextField(
        controller: usernameController,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextField(
        key: const ValueKey('debugEntryPassword'),
        controller: passwordController,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      const SizedBox(height: KeyelSpacing.sm),
      TextField(
        controller: urlController,
        keyboardType: TextInputType.url,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'URL (optional)'),
      ),
      const SizedBox(height: KeyelSpacing.md),
      FilledButton.icon(
        key: const ValueKey('debugAddLogin'),
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add login'),
      ),
    ]);
  }
}

/// Entries list and controls for the debug screen.
class DebugEntriesCard extends StatelessWidget {
  /// Creates the entries card.
  const new({
    required this.entries,
    required this.loading,
    required this.showTrash,
    required this.searchController,
    required this.sessionError,
    required this.onRefresh,
    required this.onLock,
    required this.onSearchChanged,
    required this.onShowTrashChanged,
    required this.onReveal,
    required this.onToggleDeleted,
    super.key,
  });

  /// Entries to display.
  final List<EntrySummaryDto> entries;

  /// Whether entries are loading.
  final bool loading;

  /// Whether trashed entries are included.
  final bool showTrash;

  /// Search text controller.
  final TextEditingController searchController;

  /// Session error message, if any.
  final String? sessionError;

  /// Refreshes entries.
  final VoidCallback onRefresh;

  /// Locks the vault.
  final VoidCallback onLock;

  /// Called when the search query changes.
  final ValueChanged<String> onSearchChanged;

  /// Toggles showing trashed entries.
  final ValueChanged<bool> onShowTrashChanged;

  /// Reveals an entry password.
  final ValueChanged<EntrySummaryDto> onReveal;

  /// Deletes or restores an entry.
  final ValueChanged<EntrySummaryDto> onToggleDeleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DebugCard(children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Entries (${entries.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Lock now',
            onPressed: onLock,
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      TextField(
        controller: searchController,
        decoration: const InputDecoration(
          labelText: 'Search metadata',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: onSearchChanged,
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show trashed entries'),
        value: showTrash,
        onChanged: onShowTrashChanged,
      ),
      if (loading)
        const Padding(
          padding: EdgeInsets.all(KeyelSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (entries.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: KeyelSpacing.md),
          child: Text('No entries yet. Add one above.'),
        )
      else
        for (final entry in entries)
          DebugEntryTile(
            entry: entry,
            onReveal: () => onReveal(entry),
            onToggleDeleted: () => onToggleDeleted(entry),
          ),
      if (sessionError != null) ...[
        const SizedBox(height: KeyelSpacing.sm),
        Text(sessionError!, style: TextStyle(color: scheme.error)),
      ],
    ]);
  }
}

/// Single debug entry row.
class DebugEntryTile extends StatelessWidget {
  /// Creates a debug entry tile.
  const new({
    required this.entry,
    required this.onReveal,
    required this.onToggleDeleted,
    super.key,
  });

  /// Entry summary.
  final EntrySummaryDto entry;

  /// Reveals the password.
  final VoidCallback onReveal;

  /// Deletes or restores the entry.
  final VoidCallback onToggleDeleted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(switch (entry.kind) {
        EntryKindDto.login => Icons.key_rounded,
        EntryKindDto.card => Icons.credit_card_rounded,
        EntryKindDto.note => Icons.sticky_note_2_rounded,
      }),
      title: Text(entry.title),
      subtitle: Text(
        entry.deletedAt != null ? 'In trash · ${entry.subtitle}' : entry.subtitle,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.kind == EntryKindDto.login && entry.deletedAt == null)
            IconButton(
              tooltip: 'Reveal password',
              onPressed: onReveal,
              icon: const Icon(Icons.visibility_rounded),
            ),
          IconButton(
            tooltip: entry.deletedAt == null ? 'Move to trash' : 'Restore',
            onPressed: onToggleDeleted,
            icon: Icon(
              entry.deletedAt == null
                  ? Icons.delete_outline_rounded
                  : Icons.restore_from_trash_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

/// Change-master-password section for the debug screen.
class DebugChangeMasterCard extends StatelessWidget {
  /// Creates the change-master card.
  const new({
    required this.oldController,
    required this.newController,
    required this.onChange,
    super.key,
  });

  /// Current password controller.
  final TextEditingController oldController;

  /// New password controller.
  final TextEditingController newController;

  /// Applies the password change.
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return DebugCard(children: [
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'Change master password',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          TextField(
            controller: oldController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: KeyelSpacing.sm),
          TextField(
            controller: newController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: KeyelSpacing.md),
          OutlinedButton(
            onPressed: onChange,
            child: const Text('Change master password'),
          ),
        ],
      ),
    ]);
  }
}
