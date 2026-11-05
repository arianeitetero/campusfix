import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';
import '../reports/browse_reports_screen.dart';
import '../reports/my_reports_screen.dart';
import '../reports/report_form_screen.dart';
import '../staff/staff_dashboard_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.body);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}

/// Bottom-navigation shell. Staff get an extra Dashboard tab; students never
/// see staff tooling at all.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  List<_Tab> _tabsFor(bool isStaff) => [
        if (isStaff)
          const _Tab('Dashboard', Icons.space_dashboard_outlined,
              Icons.space_dashboard, StaffDashboardScreen()),
        const _Tab('Browse', Icons.list_alt_outlined, Icons.list_alt,
            BrowseReportsScreen()),
        const _Tab('My reports', Icons.assignment_ind_outlined,
            Icons.assignment_ind, MyReportsScreen()),
        const _Tab('Profile', Icons.person_outline, Icons.person,
            ProfileScreen()),
      ];

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);
    final tabs = _tabsFor(isStaff);
    final index = _index.clamp(0, tabs.length - 1);
    final showFab = tabs[index].body is! ProfileScreen;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.body],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ReportFormScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Report issue'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
