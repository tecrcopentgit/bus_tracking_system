import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nav_controller.dart';
import '../widgets/bottom_nav.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'route_page.dart';
import 'vehicle_page.dart';

/// Signed-in frame: five pages with a floating animated bottom bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[
    HomePage(),
    RoutePage(),
    MapPage(),
    VehiclePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 340),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(nav.index), child: _pages[nav.index]),
      ),
      bottomNavigationBar: BusBottomNav(index: nav.index, onChanged: nav.go),
    );
  }
}
