import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/routing/route_names.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AppNavShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const AppNavShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
        break;
      case 1:
        context.go(RouteNames.resumes);
        break;
      case 2:
        context.go(RouteNames.jobs);
        break;
      case 3:
        context.go(RouteNames.applications);
        break;
      case 4:
        context.go(RouteNames.skillGap);
        break;
      case 5:
        context.go(RouteNames.adminDashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;
    final isAdmin = auth.isAdmin;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final navItems = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description_rounded, color: AppColors.primary),
        label: 'Resumes',
      ),
      const NavigationDestination(
        icon: Icon(Icons.work_outline),
        selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
        label: 'Jobs',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_turned_in_outlined),
        selectedIcon: Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary),
        label: 'Applications',
      ),
      const NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights_rounded, color: AppColors.primary),
        label: 'Skill Gap',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
          label: 'Admin',
        ),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail
            NavigationRail(
              selectedIndex: selectedIndex.clamp(0, navItems.length - 1),
              onDestinationSelected: (idx) => _onItemTapped(context, idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Analyzer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                          onPressed: () => theme.toggleTheme(!isDark),
                          tooltip: 'Toggle Theme',
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.logout, color: AppColors.error),
                          onPressed: () => auth.logout(),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: navItems
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Main Content
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile / Tablet with Bottom Navigation Bar
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, navItems.length - 1),
        onDestinationSelected: (idx) => _onItemTapped(context, idx),
        destinations: navItems,
        elevation: 8,
      ),
    );
  }
}
