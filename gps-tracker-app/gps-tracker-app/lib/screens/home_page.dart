import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/geo.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/nav_controller.dart';
import '../providers/tracking_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/buttons.dart';
import '../widgets/data_gate.dart';
import '../widgets/logo.dart';
import '../widgets/neu_card.dart';
import '../widgets/pressable.dart';
import '../widgets/status_chip.dart';
import '../widgets/ticket.dart';
import '../widgets/tracking_map.dart';

/// Dashboard: greeting, dark live-status card, bus-pass ticket, map preview,
/// "bus is near" + "last update" cards and the first stops.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DataGate(
      builder: (context, t, route, vehicle) => RefreshIndicator(
        color: AppColors.terracotta,
        onRefresh: t.refreshLocation,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 130),
            children: _items(context, t, route, vehicle),
          ),
        ),
      ),
    );
  }

  List<Widget> _items(BuildContext context, TrackingProvider t, RouteInfo route, Vehicle vehicle) {
    final nav = context.read<NavController>();
    final user = context.watch<AuthProvider>().user;
    final first = (user?.fullName ?? 'there').trim().split(' ').first;
    final loc = t.location;
    final stops = route.stops;
    final nearest = t.nearest;
    int d = 0;
    Duration next() => Duration(milliseconds: 80 * d++);

    return [
      FadeSlideIn(
        delay: next(),
        child: Row(
          children: [
            Pressable(
              onTap: () => nav.go(4),
              child: Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: neuShadow,
                ),
                child: const AppLogo(width: 42),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $first 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                  const Text('Ready for your next ride?',
                      style: TextStyle(color: AppColors.muted, fontSize: 14)),
                ],
              ),
            ),
            SpinRefreshButton(onTap: t.loading ? null : t.refreshLocation),
          ],
        ),
      ),
      if (t.locationError != null) ...[
        const SizedBox(height: 14),
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.amber.withAlpha(150)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live updates paused. ${t.locationError} Showing the last known position.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      FadeSlideIn(delay: next(), child: _LiveCard(vehicle: vehicle, location: loc, samples: t.samples)),
      const SizedBox(height: 20),
      FadeSlideIn(
        delay: next(),
        child: TicketCard(
          title: route.name,
          subtitle: route.description.isEmpty ? 'Your assigned route' : route.description,
          seed: '${route.name}${vehicle.code}',
          onTap: () => nav.go(1),
          items: [
            TicketItem(Icons.pin_drop_outlined, '${stops.length} Stops', 'Route'),
            TicketItem(Icons.directions_bus_outlined, vehicle.code, 'Vehicle'),
            TicketItem(Icons.straighten_rounded, '${routeLengthKm(route).toStringAsFixed(1)} km', 'Distance'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FadeSlideIn(
        delay: next(),
        child: NeuCard(
          onTap: () => nav.go(2),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(route.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.more_vert_rounded, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 210,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: TrackingMap(
                          route: route,
                          location: loc,
                          interactive: false,
                          showControls: false,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: darkShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Explore Map',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              SizedBox(width: 8),
                              Icon(Icons.near_me_rounded, color: Colors.white, size: 17),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FadeSlideIn(
        delay: next(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _NearCard(nearest: nearest, onTap: () => nav.go(1))),
              const SizedBox(width: 14),
              Expanded(child: _UpdateCard(time: loc?.recordedAt, status: vehicle.status)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FadeSlideIn(
        delay: next(),
        child: NeuCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Top Stops',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => nav.go(1),
                    child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              for (var i = 0; i < stops.length && i < 3; i++)
                _StopRow(
                  stop: stops[i],
                  isStart: i == 0,
                  isEnd: i == stops.length - 1,
                  busHere: nearest?.index == i,
                ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// The dark "weather-style" card: big animated speed, status and recent speeds.
class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.vehicle, required this.location, required this.samples});

  final Vehicle vehicle;
  final VehicleLocation? location;
  final List<SpeedSample> samples;

  @override
  Widget build(BuildContext context) {
    final hasFix = location != null && location!.hasFix;
    final speed = hasFix ? (location!.speed ?? 0) : 0.0;
    final recent = samples.length > 5 ? samples.sublist(samples.length - 5) : samples;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        gradient: AppGradients.charcoal,
        borderRadius: BorderRadius.circular(32),
        boxShadow: darkShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CountUp(
                          value: speed,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 58,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 6, bottom: 6),
                          child: Text('km/h',
                              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StatusChip(vehicle.status, dark: true),
                  ],
                ),
              ),
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Rays(size: 112),
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.terracotta,
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 34),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withAlpha(30)),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Waiting for GPS updates…', style: TextStyle(color: Color(0xB3FFFFFF))),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < recent.length; i++)
                  Expanded(
                    child: _SampleColumn(
                      sample: recent[i],
                      isNow: i == recent.length - 1,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SampleColumn extends StatelessWidget {
  const _SampleColumn({required this.sample, required this.isNow});
  final SpeedSample sample;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final h = 8 + (sample.speed > 70 ? 70 : sample.speed) / 70 * 38;
    final c = isNow ? AppColors.terracottaLight : const Color(0x55FFFFFF);
    return Column(
      children: [
        Text(isNow ? 'Now' : formatClock(sample.time).substring(3),
            style: TextStyle(
                color: isNow ? Colors.white : const Color(0xB3FFFFFF),
                fontSize: 11,
                fontWeight: isNow ? FontWeight.w700 : FontWeight.w500)),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: h),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (_, v, __) => Container(
            width: 14,
            height: v < 0 ? 0 : v,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7)),
          ),
        ),
        const SizedBox(height: 8),
        Text('${sample.speed.round()}',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _NearCard extends StatelessWidget {
  const _NearCard({required this.nearest, required this.onTap});
  final NearestStop? nearest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(child: _Label('BUS IS NEAR')),
              const Spacer(),
              Bobbing(
                amplitude: 3,
                child: const Icon(Icons.location_on_rounded, color: AppColors.pink, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nearest?.stop.name ?? 'Waiting…',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.15),
          ),
          const SizedBox(height: 4),
          Text(
            nearest == null ? 'No GPS signal yet' : '${nearest!.km.toStringAsFixed(1)} km away',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.time, required this.status});
  final DateTime? time;
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = statusStyle(status);
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(child: _Label('LAST UPDATE')),
              const Spacer(),
              PulseDot(color: s.color, size: 9, animate: status == 'moving'),
            ],
          ),
          const SizedBox(height: 10),
          LiveAgo(
            time: time,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text('GPS fix', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isStart,
    required this.isEnd,
    required this.busHere,
  });

  final Stop stop;
  final bool isStart;
  final bool isEnd;
  final bool busHere;

  @override
  Widget build(BuildContext context) {
    final role = isStart ? 'Start' : (isEnd ? 'Terminus' : 'Stop ${stop.sequence}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isStart || isEnd ? AppGradients.terracotta : AppGradients.charcoal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('${stop.sequence}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(role, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          if (busHere)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.green.withAlpha(36),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Bus here',
                  style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.terracotta,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      );
}
