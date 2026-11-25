import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/logo.dart';
import 'overview_page.dart';
import 'routes_page.dart';
import 'users_page.dart';
import 'vehicles_page.dart';

/// Admin Console frame: a dark side rail on wide screens, a bottom bar on phones.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = <Widget>[OverviewPage(), UsersPage(), VehiclesPage(), RoutesPage()];
  static const _items = <(String, IconData, IconData)>[
    ('Fleet', Icons.map_outlined, Icons.map_rounded),
    ('Users', Icons.people_outline_rounded, Icons.people_alt_rounded),
    ('Vehicles', Icons.directions_bus_outlined, Icons.directions_bus_rounded),
    ('Routes', Icons.alt_route_outlined, Icons.alt_route_rounded),
  ];

  Widget get _content => AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: SafeArea(bottom: false, child: _pages[_index])),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.charcoal,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              minWidth: 92,
              indicatorColor: AppColors.terracotta,
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: const IconThemeData(color: Color(0x99FFFFFF)),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelTextStyle: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
                  child: const AppLogo(width: 52),
                ),
              ),
              destinations: [
                for (final it in _items)
                  NavigationRailDestination(
                    icon: Icon(it.$2),
                    selectedIcon: Icon(it.$3),
                    label: Text(it.$1),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            Expanded(child: _content),
          ],
        ),
      );
    }

    return Scaffold(
      body: _content,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.terracotta.withAlpha(60),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final it in _items)
            NavigationDestination(icon: Icon(it.$2), selectedIcon: Icon(it.$3, color: AppColors.terracotta), label: it.$1),
        ],
      ),
    );
  }
}
