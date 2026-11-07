import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/ui/keyel.dart';

/// A navigation destination descriptor used by [KeyelShell].
class _Destination {
  const new({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The ordered list of top-level destinations.
///
/// The order **must** match the branch order in the app router.
const _destinations = [
  _Destination(
    path: KeyelRoutes.vault,
    icon: Icons.key_outlined,
    selectedIcon: Icons.key_rounded,
    label: 'Vault',
  ),
  _Destination(
    path: KeyelRoutes.generator,
    icon: Icons.password_outlined,
    selectedIcon: Icons.password_rounded,
    label: 'Generator',
  ),
  _Destination(
    path: KeyelRoutes.security,
    icon: Icons.verified_user_outlined,
    selectedIcon: Icons.verified_user_rounded,
    label: 'Security',
  ),
  _Destination(
    path: KeyelRoutes.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

/// Root shell widget that wraps the tab content with the appropriate
/// navigation chrome: bottom nav on compact, rail on medium+.
class KeyelShell extends StatelessWidget {
  /// Creates the shell.
  const new({required this.navigationShell, super.key});

  /// Managed by [StatefulShellRoute.indexedStack] — holds tab state.
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tap on current tab: pop to root of that tab's stack.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final windowClass = WindowSizeClass.of(context);

    if (windowClass.isCompact) {
      return _BottomNavScaffold(shell: navigationShell, onTap: _onTap);
    }

    return _RailScaffold(shell: navigationShell, onTap: _onTap);
  }
}

// ---------------------------------------------------------------------------
// Compact – floating bottom navigation
// ---------------------------------------------------------------------------

class _BottomNavScaffold extends StatelessWidget {
  const new({required this.shell, required this.onTap});

  final StatefulNavigationShell shell;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _KeyelBottomNav(
        currentIndex: shell.currentIndex,
        onTap: onTap,
      ),
    );
  }
}

class _KeyelBottomNav extends StatelessWidget {
  const new({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KeyelRadii.card),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < _destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: _destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const new({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: PressableScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KeyelRadii.pill),
        semanticLabel: destination.label,
        child: AnimatedContainer(
          duration: KeyelMotion.fast,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 14 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(KeyelRadii.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medium / Expanded – navigation rail
// ---------------------------------------------------------------------------

class _RailScaffold extends StatelessWidget {
  const new({required this.shell, required this.onTap});

  final StatefulNavigationShell shell;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 108,
            color: scheme.surface,
            child: SafeArea(
              right: false,
              child: Column(
                children: [
                  const SizedBox(height: KeyelSpacing.md),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryFixed,
                      borderRadius: BorderRadius.circular(KeyelRadii.field),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      color: scheme.onPrimaryFixed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: KeyelSpacing.lg),
                  for (var i = 0; i < _destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: KeyelSpacing.sm),
                      child: _RailItem(
                        destination: _destinations[i],
                        selected: i == shell.currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const new({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.tile),
      semanticLabel: destination.label,
      child: AnimatedContainer(
        duration: KeyelMotion.fast,
        curve: Curves.easeOut,
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(KeyelRadii.tile),
        ),
        child: Column(
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 24,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: KeyelSpacing.xs),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
