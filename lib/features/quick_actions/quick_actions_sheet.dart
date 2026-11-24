import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/focus/keyel_search_focus.dart';
import 'package:keyel/core/router/keyel_route_observer.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/data/vault_revision_provider.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Whether a quick-actions palette is currently on screen.
///
/// `Ctrl/Cmd+K` toggles the palette: a second press closes the open sheet instead
/// of stacking a second one. The flag lives outside Riverpod so the shortcut
/// callback can check it synchronously.
final ValueNotifier<bool> quickActionsOpen = ValueNotifier<bool>(false);

/// Toggles the searchable quick-actions palette.
///
/// A bottom sheet on phones and an end-aligned side sheet elsewhere, sharing
/// the same result list. [keyelRouteObserver] masks revealed secrets as soon as
/// this route is pushed, so opening the palette can never leave a secret
/// exposed underneath it.
Future<void> showQuickActions(BuildContext context) async {
  if (quickActionsOpen.value) {
    Navigator.of(context, rootNavigator: true).pop();
    return;
  }
  quickActionsOpen.value = true;
  try {
    await showKeyelAdaptiveSheet<void>(
      context: context,
      builder: (_) => const QuickActionsSheet(),
    );
  } finally {
    quickActionsOpen.value = false;
  }
}

/// A static action offered by the palette.
@immutable
class QuickAction {
  /// Creates an action with a localized label and icon.
  const new({required this.label, required this.icon, required this.run});

  /// Visible label; also used as the search text.
  final String label;

  /// Leading icon.
  final IconData icon;

  /// Executes the action against the current router and container.
  final void Function(GoRouter router, WidgetRef ref) run;
}

/// Escape closes the palette; Ctrl/Cmd+K is handled by the shared shortcut
/// class so a second press toggles it shut.
class _CloseQuickActionsIntent extends Intent {
  /// Creates the close intent.
  const new();
}

const Map<ShortcutActivator, Intent> _paletteShortcuts = {
  SingleActivator(LogicalKeyboardKey.escape): _CloseQuickActionsIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, control: true):
      KeyelQuickActionsIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, meta: true):
      KeyelQuickActionsIntent(),
};

/// Searchable palette of entry results and six static actions.
class QuickActionsSheet extends ConsumerStatefulWidget {
  /// Creates the palette body.
  const new({super.key});

  @override
  ConsumerState<QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends ConsumerState<QuickActionsSheet> {
  static const _searchDebounce = Duration(milliseconds: 180);
  static const _maxResults = 8;

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<VaultEntry> _results = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () => _search(value));
  }

  Future<void> _search(String query) async {
    if (ref.read(vaultSessionProvider).status != VaultStatus.unlocked) return;
    final generation = _generation = _generation + 1;
    setState(() => _searching = true);
    try {
      final summaries = await ref
          .read(vaultRepositoryProvider)
          .listEntries(query: query.trim());
      if (!mounted || generation != _generation) return;
      setState(() {
        // Metadata only: titles and subtitles can never contain a secret.
        _results = summaries
            .take(_maxResults)
            .map(VaultEntry.fromSummary)
            .toList();
      });
    } on Object catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _results = const []);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _searching = false);
      }
    }
  }

  int _generation = 0;

  List<QuickAction> _actions(BuildContext context) {
    final l10n = l10nOf(context);
    return [
      QuickAction(
        label: l10n.quickActionOpenEntry,
        icon: Icons.open_in_new_rounded,
        run: (router, ref) {
          router.go(KeyelRoutes.vault);
          focusVaultSearch(ref);
        },
      ),
      QuickAction(
        label: l10n.vaultNewItem,
        icon: Icons.add_rounded,
        run: (router, ref) async {
          await router.push(KeyelRoutes.newEntry);
          bumpVaultRevision(ref);
        },
      ),
      QuickAction(
        label: l10n.actionLockVault,
        icon: Icons.lock_rounded,
        run: (router, ref) => ref.read(vaultSessionProvider.notifier).lock(),
      ),
      QuickAction(
        label: l10n.navGenerator,
        icon: Icons.password_rounded,
        run: (router, _) => router.go(KeyelRoutes.generator),
      ),
      QuickAction(
        label: l10n.navSettings,
        icon: Icons.settings_outlined,
        run: (router, _) => router.go(KeyelRoutes.settings),
      ),
      QuickAction(
        label: l10n.softwareUpdate,
        icon: Icons.system_update_rounded,
        run: (router, _) => router.go(KeyelRoutes.softwareUpdate),
      ),
    ];
  }

  /// Captures the router and container before the sheet route disappears.
  void _select(void Function(GoRouter router, WidgetRef ref) run) {
    final router = GoRouter.of(context);
    final ref = this.ref;
    _close();
    run(router, ref);
  }

  void _close() {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = _searchController.text.trim().toLowerCase();
    final actions = _actions(context).where((action) {
      return query.isEmpty || action.label.toLowerCase().contains(query);
    }).toList();
    final entries = _results.where((entry) {
      if (query.isEmpty) return true;
      return entry.title.toLowerCase().contains(query) ||
          entry.username.toLowerCase().contains(query);
    }).toList();

    return Shortcuts(
      shortcuts: _paletteShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          KeyelQuickActionsIntent: CallbackAction<KeyelQuickActionsIntent>(
            onInvoke: (_) => _close(),
          ),
          _CloseQuickActionsIntent: CallbackAction<_CloseQuickActionsIntent>(
            onInvoke: (_) => _close(),
          ),
        },
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KeyelSpacing.lg,
                      KeyelSpacing.md,
                      KeyelSpacing.md,
                      KeyelSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: KeyelSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.quickActionsTitle,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        KeyelIconHull(
                          icon: Icons.close_rounded,
                          tooltip: l10n.actionClose,
                          onPressed: _close,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeyelSpacing.lg,
                      vertical: KeyelSpacing.xs,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onQueryChanged,
                      decoration: InputDecoration(
                        hintText: l10n.quickActionsHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                        KeyelSpacing.sm,
                        KeyelSpacing.xs,
                        KeyelSpacing.sm,
                        KeyelSpacing.md,
                      ),
                      children: [
                        for (final action in actions)
                          ListTile(
                            leading: Icon(action.icon, color: scheme.primary),
                            title: Text(action.label),
                            onTap: () => _select(action.run),
                          ),
                        if (entries.isNotEmpty && actions.isNotEmpty)
                          const Divider(height: KeyelSpacing.sm),
                        for (final entry in entries)
                          ListTile(
                            leading: Icon(entry.icon),
                            title: Text(entry.title, maxLines: 1),
                            subtitle: Text(
                              entry.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _select(
                              (router, _) => router.go(
                                KeyelRoutes.vaultEntryDetail(entry.id),
                              ),
                            ),
                          ),
                        if (query.isNotEmpty &&
                            actions.isEmpty &&
                            entries.isEmpty &&
                            !_searching)
                          Padding(
                            padding: const EdgeInsets.all(KeyelSpacing.lg),
                            child: Text(
                              l10n.quickActionsNoResults,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
