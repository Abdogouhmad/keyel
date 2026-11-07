import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/features/generator/generator_screen.dart';
import 'package:keyel/features/security_dashboard/security_screen.dart';
import 'package:keyel/features/settings/settings_screen.dart';
import 'package:keyel/features/vault/entry_detail_screen.dart';
import 'package:keyel/features/vault/entry_edit_screen.dart';
import 'package:keyel/features/vault/vault_screen.dart';
import 'package:keyel/ui/adaptive/keyel_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// No slide animation between tabs, like a normal bottom bar.
Page<void> _tab(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

/// The app router. Each tab keeps its own navigation stack and scroll
/// position. The order of branches must match `KeyelShell.destinations`.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: KeyelRoutes.vault,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => KeyelShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: KeyelRoutes.vault,
              pageBuilder: (context, state) => _tab(state, const VaultScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: KeyelRoutes.generator,
              pageBuilder: (context, state) =>
                  _tab(state, const GeneratorScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: KeyelRoutes.security,
              pageBuilder: (context, state) =>
                  _tab(state, const SecurityScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: KeyelRoutes.settings,
              pageBuilder: (context, state) =>
                  _tab(state, const SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: KeyelRoutes.newEntry,
      builder: (context, state) => const EntryEditScreen(),
    ),
    GoRoute(
      path: '${KeyelRoutes.entryRoot}/:id/edit',
      builder: (context, state) =>
          EntryEditScreen(entryId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '${KeyelRoutes.entryRoot}/:id',
      builder: (context, state) =>
          EntryDetailScreen(entryId: state.pathParameters['id']!),
    ),
  ],
);
