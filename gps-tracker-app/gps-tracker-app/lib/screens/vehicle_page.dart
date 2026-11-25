import 'package:flutter/material.dart';

import '../providers/tracking_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/data_gate.dart';
import '../widgets/neu_card.dart';
import '../widgets/painters.dart';
import '../widgets/status_chip.dart';

/// Vehicle: dark header with a number plate, a big animated speedometer
/// overlapping it, then telemetry tiles and a speed-history chart.
class VehiclePage extends StatelessWidget {
  const VehiclePage({super.key});

  static const double _gaugeH = 280;
  static const double _overlap = 90;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final headerH = 200 + top;

    return DataGate(
      builder: (context, t, route, vehicle) {
        final loc = t.location;
        final hasFix = loc != null && loc.hasFix;
        final double speed = hasFix ? (loc?.speed ?? 0.0) : 0.0;
        final double progress = (speed > 80 ? 80.0 : speed) / 80.0;

        return ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            SizedBox(
              height: headerH - _overlap + _gaugeH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: headerH,
                    child: FadeSlideIn(
                      dy: -0.1,
                      child: Container(
                        padding: EdgeInsets.fromLTRB( 24 , top + 14 , 24 , 0 ),
                        decoration: const BoxDecoration(
                          gradient: AppGradients.charcoal,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(46)),
                          boxShadow: darkShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('MY VEHICLE',
                                    style: TextStyle(
                                        color: AppColors.terracottaLight,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3,
                                        fontSize: 12)),
                                const Spacer(),
                                StatusChip(vehicle.status, dark: true),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(vehicle.code,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            if (vehicle.plateNumber.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.cream,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.ink, width: 2),
                                ),
                                child: Text(vehicle.plateNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.5,
                                        fontSize: 15)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: headerH - _overlap,
                    left: 26,
                    right: 26,
                    height: _gaugeH,
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: NeuCard(
                        radius: 34,
                        padding: const EdgeInsets.all(14),
                        child: Center(
                          child: SizedBox(
                            width: 250,
                            height: 250,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: progress),
                                  duration: const Duration(milliseconds: 1100),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, __) => CustomPaint(
                                    size: const Size.square(250),
                                    painter: SpeedGaugePainter(v),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CountUp(
                                      value: speed,
                                      style: const TextStyle(
                                          fontSize: 64, fontWeight: FontWeight.w900, height: 1),
                                    ),
                                    const Text('km/h',
                                        style: TextStyle(color: AppColors.muted, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Tile(
                            icon: Icons.south_rounded,
                            label: 'Latitude',
                            value: Text(loc?.latitude?.toStringAsFixed(5) ?? '—', style: _v),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _Tile(
                            icon: Icons.east_rounded,
                            label: 'Longitude',
                            value: Text(loc?.longitude?.toStringAsFixed(5) ?? '—', style: _v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 340),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Tile(
                            icon: Icons.schedule_rounded,
                            label: 'Last update',
                            value: LiveAgo(time: loc?.recordedAt, style: _v),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _Tile(
                            icon: Icons.alt_route_rounded,
                            label: 'Route',
                            value: Text(route.name, style: _v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 420),
                    child: _History(samples: t.samples),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static const TextStyle _v = TextStyle(fontSize: 17, fontWeight: FontWeight.w800);
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.terracotta.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.terracotta),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.samples});
  final List<SpeedSample> samples;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Speed history',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(samples.isEmpty ? '' : 'last ${samples.length} updates',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 14),
          if (samples.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text('Collecting live data…', style: TextStyle(color: AppColors.muted)),
              ),
            )
          else
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < samples.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                              begin: 0, end: 10 + (samples[i].speed > 80 ? 80 : samples[i].speed) / 80 * 86),
                          duration: Duration(milliseconds: 500 + i * 60),
                          curve: Curves.easeOutBack,
                          builder: (_, v, __) => Container(
                            height: v < 0 ? 0 : v,
                            decoration: BoxDecoration(
                              gradient: i == samples.length - 1
                                  ? AppGradients.terracotta
                                  : null,
                              color: i == samples.length - 1 ? null : AppColors.line,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
