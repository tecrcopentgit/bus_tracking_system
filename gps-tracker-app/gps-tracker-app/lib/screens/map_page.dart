import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/tracking_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/data_gate.dart';
import '../widgets/status_chip.dart';
import '../widgets/tracking_map.dart';

/// Live map: edge-to-edge map with frosted-glass cards floating on top.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return DataGate(
      builder: (context, t, route, vehicle) {
        return Stack(
          children: [
            Positioned.fill(
              child: TrackingMap(
                route: route,
                location: t.location,
                controlsTop: media.padding.top + 104,
                bottomInset: media.padding.bottom + 110,
              ),
            ),
            Positioned(
              top: media.padding.top + 10,
              left: 16,
              right: 16,
              child: FadeSlideIn(dy: -0.3, child: _TopCard(route: route, vehicle: vehicle)),
            ),
            if (t.location != null && t.location!.hasFix)
              Positioned(
                left: 16,
                right: 16,
                bottom: media.padding.bottom + 10,
                child: FadeSlideIn(dy: 0.3, child: _BottomCard(t: t, vehicle: vehicle)),
              ),
          ],
        );
      },
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cream.withAlpha(215),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withAlpha(170)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.route, required this.vehicle});
  final RouteInfo route;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.terracotta),
            child: const Icon(Icons.alt_route_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Tracking ${vehicle.code}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          StatusChip(vehicle.status),
        ],
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({required this.t, required this.vehicle});
  final TrackingProvider t;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final loc = t.location!;
    final near = t.nearest;
    return _Glass(
      child: Row(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUp(
                value: loc.speed ?? 0,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text('km/h', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                near == null ? '' : 'Near ${near.stop.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              LiveAgo(
                time: loc.recordedAt,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
