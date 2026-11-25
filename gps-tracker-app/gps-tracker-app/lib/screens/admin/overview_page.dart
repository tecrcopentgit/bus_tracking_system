import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_common.dart';
import '../../widgets/admin/fleet_map.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_view.dart';
import '../../widgets/neu_card.dart';
import 'vehicle_detail.dart';

/// Fleet overview: headline numbers, one map with every route and bus, and the vehicle list.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminProvider>();
    if (a.loading && a.overview == null) return const LoadingView();
    if (a.error != null || a.overview == null) {
      return ErrorView(message: a.error ?? 'Unable to load the fleet.', onRetry: a.load);
    }
    final o = a.overview!;
    final stats = <(IconData, String, int, Color)>[
      (Icons.directions_bus_rounded, 'Moving', o.moving, AppColors.green),
      (Icons.pause_circle_outline_rounded, 'Idle', o.idle, AppColors.amber),
      (Icons.wifi_off_rounded, 'Offline', o.offline, AppColors.pink),
      (Icons.sensors_off_rounded, 'No signal yet', o.noData, AppColors.muted),
      (Icons.people_alt_rounded, 'Users', o.totalUsers, AppColors.terracotta),
      (Icons.person_search_rounded, 'Unassigned', o.unassignedUsers, AppColors.sky),
    ];

    return RefreshIndicator(
      color: AppColors.terracotta,
      onRefresh: a.refreshAll,
      child: AdminBody(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            AdminHeader(
              title: 'Fleet overview',
              subtitle: '${o.activeVehicles} active vehicles · ${o.totalRoutes} routes',
              onRefresh: a.refreshAll,
            ),
            const SizedBox(height: 18),
            if (a.liveError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.amber.withAlpha(150)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.amber),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Live updates paused. ${a.liveError}')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 900 ? 6 : (c.maxWidth >= 560 ? 3 : 2);
                const gap = 12.0;
                final w = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < stats.length; i++)
                      SizedBox(
                        width: w,
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 60 * i),
                          child: StatTile(
                            icon: stats[i].$1,
                            label: stats[i].$2,
                            value: stats[i].$3,
                            color: stats[i].$4,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (o.offline + o.noData > 0) ...[
              const SizedBox(height: 12),
              const Text(
                '“Offline” means no GPS fix in the last 60 seconds; “No signal yet” means the vehicle has never reported. '
                'Check that the GPS simulator or the devices are running.',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.35),
              ),
            ],
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 250),
              child: NeuCard(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 380,
                    child: FleetMap(
                      routes: a.routes,
                      vehicles: a.vehicles,
                      onVehicleTap: (v) => showVehicleDetail(context, a, v),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Vehicles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            for (var i = 0; i < a.vehicles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 300 + i * 50),
                  child: VehicleTile(
                    vehicle: a.vehicles[i],
                    onTap: () => showVehicleDetail(context, a, a.vehicles[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
