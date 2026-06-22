import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../layout/responsive_breakpoint.dart';
import '../theme/app_font_size.dart';
import '../theme/app_label.dart';
import '../widgets/dynamic_status_bar.dart';
import 'route_paths.dart';

class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;
}

const List<ShellDestination> _shellDestinations = [
  ShellDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: _homeLabel,
  ),
  ShellDestination(
    icon: Icons.apps_outlined,
    selectedIcon: Icons.apps_rounded,
    label: _modulesLabel,
  ),
  ShellDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: _settingsLabel,
  ),
];

String _homeLabel(AppLocalizations l) => l.shellHome;
String _modulesLabel(AppLocalizations l) => l.shellModules;
String _settingsLabel(AppLocalizations l) => l.shellSettings;

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final size = resolveWindowSizeClass(MediaQuery.sizeOf(context).width);
    return DynamicStatusBar(
      child: switch (size) {
        WindowSizeClass.compact => _buildCompact(context),
        WindowSizeClass.medium => _buildRail(context, extended: false),
        WindowSizeClass.expanded => _buildRail(context, extended: true),
      },
    );
  }

  Scaffold _buildCompact(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.path;
    final isRootPage = [
      RoutePaths.dashboard,
      RoutePaths.modules,
      RoutePaths.settings,
    ].contains(location);
    
    return Scaffold(
      extendBody: true, // Crucial for floating nav bar
      body: navigationShell,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        offset: isRootPage ? Offset.zero : const Offset(0, 1.5),
        child: SafeArea(
          child: Container(
          height: 74,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < _shellDestinations.length; i++)
                      _BottomNavItem(
                        destination: _shellDestinations[i],
                        isSelected: navigationShell.currentIndex == i,
                        onTap: () => _goBranch(i),
                        label: _shellDestinations[i].label(l10n),
                      ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Scaffold _buildRail(BuildContext context, {required bool extended}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            extended: extended,
            backgroundColor: theme.colorScheme.surface,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final d in _shellDestinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label(l10n)),
                ),
            ],
          ),
          VerticalDivider(
            thickness: 1, 
            width: 1, 
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  final ShellDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16, 
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 26,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: Padding(
                  padding: isSelected 
                      ? const EdgeInsets.only(left: 8) 
                      : EdgeInsets.zero,
                  child: AppLabel(
                    text: label,
                    fontSize: AppFontSize.value12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
