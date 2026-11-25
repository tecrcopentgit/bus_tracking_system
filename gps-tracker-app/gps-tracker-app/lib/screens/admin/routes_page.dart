import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/geo.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_common.dart';
import '../../widgets/animations.dart';
import '../../widgets/error_view.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/route_transitions.dart';
import 'route_editor_screen.dart';
import 'vehicles_page.dart' show RoundActionButton;

class RoutesPage extends StatelessWidget {
  const RoutesPage({super.key});

  void _open(BuildContext context, AdminProvider a, AdminRoute? r) {
    Navigator.of(context).push(fadeSlideRoute<void>(
      ChangeNotifierProvider<AdminProvider>.value(
        value: a,
        child: RouteEditorScreen(route: r, parentContext: context),
      ),
    ));
  }

  Future<void> _delete(BuildContext context, AdminProvider a, AdminRoute r) async {
    if (!await confirm(context, 'Delete ${r.name}?', 'This cannot be undone.', 'Delete')) return;
    if (!context.mounted) return;
    await runAction(context, () => a.deleteRoute(r.id), success: 'Route deleted');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AdminProvider>();
    if (a.loading && a.overview == null) return const LoadingView();
    if (a.error != null) return ErrorView(message: a.error!, onRetry: a.load);

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.terracotta,
          onRefresh: a.refreshAll,
          child: AdminBody(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                AdminHeader(
                  title: 'Routes',
                  subtitle: '${a.routes.length} routes · draw new ones on the map',
                  onRefresh: a.refreshAll,
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < a.routes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 60 * (i > 10 ? 10 : i)),
                      child: _RouteTile(
                        route: a.routes[i],
                        onEdit: () => _open(context, a, a.routes[i]),
                        onDelete: () => _delete(context, a, a.routes[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: AddFab(label: 'Add route', onTap: () => _open(context, a, null)),
        ),
      ],
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.route, required this.onEdit, required this.onDelete});
  final AdminRoute route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final km = routeLengthKm(route.toRouteInfo());
    final stops = route.stops;
    return NeuCard(
      onTap: onEdit,
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(gradient: AppGradients.terracotta, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.alt_route_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                if (route.description.isNotEmpty)
                  Text(route.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${stops.length} stops · ${km.toStringAsFixed(1)} km · ${route.vehicleCount} bus${route.vehicleCount == 1 ? '' : 'es'} · ${route.userCount} rider${route.userCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          RoundActionButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete route', onTap: onDelete),
        ],
      ),
    );
  }
}
