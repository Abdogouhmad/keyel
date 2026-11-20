import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keyel/core/focus/keyel_search_focus.dart';
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

/// Tab indices for [KeyelSubShell], matching [_destinations] and the branch
/// order in the app router.
abstract final class KeyelTab {
  /// The vault / home tab.
  static const int vault = 0;

  /// The generator tab.
  static const int generator = 1;

  /// The security dashboard tab.
  static const int security = 2;

  /// The settings tab.
  static const int settings = 3;
}

/// Root shell widget that wraps the tab content with the appropriate
/// navigation chrome: bottom nav on compact, rail on medium+.
class KeyelShell extends ConsumerWidget {
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

  /// Content of each tab, wrapped with the global shortcut scaffold.
  Widget _content(
    BuildContext context,
    WidgetRef ref,
    StatefulNavigationShell shell,
  ) {
    return KeyelShortcuts(
      // The shared node belongs to the vault search field, so Ctrl/Cmd+F
      // focuses it wherever the shell is mounted. On another tab the node is
      // unattached and requestFocus is a harmless no-op.
      onFind: () => focusVaultSearch(ref),
      onNewEntry: () => context.push(KeyelRoutes.newEntry),
      child: shell,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowClass = WindowSizeClass.of(context);

    if (windowClass.isCompact) {
      return _BottomNavScaffold(
        currentIndex: navigationShell.currentIndex,
        content: _content(context, ref, navigationShell),
        onTap: _onTap,
      );
    }
    if (windowClass == WindowSizeClass.medium) {
      // Icon-only rail.
      return _RailScaffold(
        currentIndex: navigationShell.currentIndex,
        content: _content(context, ref, navigationShell),
        onTap: _onTap,
        width: 76,
        showLabels: false,
      );
    }
    if (windowClass == WindowSizeClass.expanded) {
      // Rail with labels.
      return _RailScaffold(
        currentIndex: navigationShell.currentIndex,
        content: _content(context, ref, navigationShell),
        onTap: _onTap,
        width: 108,
        showLabels: true,
      );
    }

    // Large: drawer navigation.
    return _DrawerScaffold(
      currentIndex: navigationShell.currentIndex,
      content: _content(context, ref, navigationShell),
      onTap: _onTap,
    );
  }
}

/// Wraps a pushed sub-page (folders, trash, import/export, the entry editor)
/// with the same navigation chrome as [KeyelShell] on tablet and desktop
/// windows, so the rail or drawer stays visible instead of the page covering
/// it. On compact phones the page is returned as-is (full screen), matching
/// the previous behaviour.
class KeyelSubShell extends StatelessWidget {
  /// Creates the sub-page chrome.
  const new({required this.tabIndex, required this.child, super.key});

  /// Index of the tab this sub-page logically belongs to, highlighted in the
  /// rail/drawer. The rail still navigates to every tab.
  final int tabIndex;

  /// The pushed page.
  final Widget child;

  void _go(BuildContext context, int index) =>
      context.go(_destinations[index].path);

  @override
  Widget build(BuildContext context) {
    final windowClass = WindowSizeClass.of(context);

    // Phones keep the previous full-screen push.
    if (windowClass.isCompact) return child;

    if (windowClass == WindowSizeClass.medium) {
      return _RailScaffold(
        currentIndex: tabIndex,
        content: child,
        onTap: (index) => _go(context, index),
        width: 76,
        showLabels: false,
      );
    }
    if (windowClass == WindowSizeClass.expanded) {
      return _RailScaffold(
        currentIndex: tabIndex,
        content: child,
        onTap: (index) => _go(context, index),
        width: 108,
        showLabels: true,
      );
    }
    return _DrawerScaffold(
      currentIndex: tabIndex,
      content: child,
      onTap: (index) => _go(context, index),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact – floating bottom navigation
// ---------------------------------------------------------------------------

class _BottomNavScaffold extends StatelessWidget {
  const new({
    required this.currentIndex,
    required this.content,
    required this.onTap,
  });

  final int currentIndex;
  final Widget content;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content,
      bottomNavigationBar: _KeyelBottomNav(
        currentIndex: currentIndex,
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
          duration: KeyelMotion.resolve(context, KeyelMotion.fast),
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
  const new({
    required this.currentIndex,
    required this.content,
    required this.onTap,
    required this.width,
    required this.showLabels,
  });

  final int currentIndex;
  final Widget content;
  final ValueChanged<int> onTap;
  final double width;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: width,
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
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                        showLabel: showLabels,
                        itemWidth: width - 8,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Large – drawer navigation
// ---------------------------------------------------------------------------

class _DrawerScaffold extends StatelessWidget {
  const new({
    required this.currentIndex,
    required this.content,
    required this.onTap,
  });

  final int currentIndex;
  final Widget content;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            color: scheme.surface,
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: KeyelSpacing.lg,
                      top: KeyelSpacing.xl,
                      bottom: KeyelSpacing.xl,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primaryFixed,
                            borderRadius: BorderRadius.circular(
                              KeyelRadii.field,
                            ),
                          ),
                          child: Icon(
                            Icons.key_rounded,
                            color: scheme.onPrimaryFixed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: KeyelSpacing.md),
                        Expanded(
                          child: Text(
                            'Keyel',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeyelSpacing.md,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _destinations.length; i++)
                          _DrawerItem(
                            destination: _destinations[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
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
      borderRadius: BorderRadius.circular(KeyelRadii.pill),
      semanticLabel: destination.label,
      child: AnimatedContainer(
        duration: KeyelMotion.resolve(context, KeyelMotion.fast),
        curve: Curves.easeOut,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: KeyelSpacing.md,
          vertical: KeyelSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(KeyelRadii.pill),
        ),
        child: Row(
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 24,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: KeyelSpacing.md),
            Expanded(
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const new({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.showLabel,
    required this.itemWidth,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool showLabel;

  /// Fits inside the rail; the medium rail is narrower than the old hard-coded
  /// 80 dp item and used to overflow by 4 dp.
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeyelRadii.tile),
      semanticLabel: destination.label,
      child: AnimatedContainer(
        duration: KeyelMotion.resolve(context, KeyelMotion.fast),
        curve: Curves.easeOut,
        width: itemWidth,
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
            if (showLabel) ...[
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
          ],
        ),
      ),
    );
  }
}
