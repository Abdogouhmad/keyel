import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/core/router/vault_session_listenable.dart';
import 'package:keyel/data/vault_session_provider.dart';
import 'package:keyel/features/autofill/autofill_picker_screen.dart';
import 'package:keyel/features/debug/debug_vault_screen.dart';
import 'package:keyel/features/entry/entry_detail_screen.dart';
import 'package:keyel/features/entry/entry_edit_screen.dart';
import 'package:keyel/features/folders/folders_screen.dart';
import 'package:keyel/features/generator/generator_screen.dart';
import 'package:keyel/features/import_export/import_export_screen.dart';
import 'package:keyel/features/onboarding/onboarding_screen.dart';
import 'package:keyel/features/ota/ota_screen.dart';
import 'package:keyel/features/security_dashboard/security_screen.dart';
import 'package:keyel/features/settings/appearance_screen.dart';
import 'package:keyel/features/settings/settings_screen.dart';
import 'package:keyel/features/trash/trash_screen.dart';
import 'package:keyel/features/vault/vault_screen.dart';
import 'package:keyel/features/vault/widgets/unlock_vault_view.dart';
import 'package:keyel/ui/adaptive/keyel_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// No slide animation between tabs, like a normal bottom bar.
Page<void> _tab(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

/// Injectable router so the guard can read the Riverpod container.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = VaultSessionListenable(ref.container);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: KeyelRoutes.vault,
    refreshListenable: session,
    // Lifecycle guard: no vault → /onboarding, locked → /unlock.
    // Redirects only once the session state has resolved.
    redirect: (context, state) {
      final snapshot = session.state;
      if (snapshot.busy) return null;

      final status = snapshot.status;
      final location = state.matchedLocation;
      final isOnboarding = location == KeyelRoutes.onboarding;
      final isUnlock = location == KeyelRoutes.unlock;
      final isDebug = location == KeyelRoutes.debug;

      return switch (status) {
        VaultStatus.noVault when !isOnboarding => KeyelRoutes.onboarding,
        VaultStatus.locked when !isUnlock && !isDebug => KeyelRoutes.unlock,
        // Onboarding keeps its own flow after creation so the one-time
        // recovery key stays on screen until the user dismisses it.
        VaultStatus.unlocked when isUnlock => KeyelRoutes.vault,
        _ => null,
      };
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => KeyelShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: KeyelRoutes.vault,
                pageBuilder: (context, state) =>
                    _tab(state, const VaultScreen()),
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
        path: KeyelRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: KeyelRoutes.unlock,
        builder: (context, state) => const UnlockVaultView(),
      ),
      // Sub-pages pushed from the tabs. They are wrapped in KeyelSubShell so
      // the rail/drawer stays visible on tablet and desktop windows; on phones
      // KeyelSubShell is a pass-through and they stay full screen.
      GoRoute(
        path: KeyelRoutes.appearance,
        builder: (context, state) => const KeyelSubShell(
          tabIndex: KeyelTab.settings,
          child: AppearanceScreen(),
        ),
      ),
      GoRoute(
        path: KeyelRoutes.folders,
        builder: (context, state) => const KeyelSubShell(
          tabIndex: KeyelTab.settings,
          child: FoldersScreen(),
        ),
      ),
      GoRoute(
        path: KeyelRoutes.trash,
        builder: (context, state) => const KeyelSubShell(
          tabIndex: KeyelTab.settings,
          child: TrashScreen(),
        ),
      ),
      GoRoute(
        path: KeyelRoutes.importExport,
        builder: (context, state) => const KeyelSubShell(
          tabIndex: KeyelTab.settings,
          child: ImportExportScreen(),
        ),
      ),
      GoRoute(
        path: KeyelRoutes.softwareUpdate,
        builder: (context, state) => const OtaScreen(),
      ),
      GoRoute(
        path: KeyelRoutes.autofillPicker,
        builder: (context, state) => AutofillPickerScreen(
          package: state.uri.queryParameters['package'],
          webDomain: state.uri.queryParameters['webDomain'],
        ),
      ),
      GoRoute(
        path: KeyelRoutes.newEntry,
        builder: (context, state) => const KeyelSubShell(
          tabIndex: KeyelTab.vault,
          child: EntryEditScreen(),
        ),
      ),
      GoRoute(
        path: KeyelRoutes.debug,
        builder: (context, state) => const DebugVaultScreen(),
      ),
      GoRoute(
        path: '${KeyelRoutes.entryRoot}/:id/edit',
        builder: (context, state) => KeyelSubShell(
          tabIndex: KeyelTab.vault,
          child: EntryEditScreen(entryId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '${KeyelRoutes.entryRoot}/:id',
        builder: (context, state) => KeyelSubShell(
          tabIndex: KeyelTab.vault,
          child: EntryDetailScreen(entryId: state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
