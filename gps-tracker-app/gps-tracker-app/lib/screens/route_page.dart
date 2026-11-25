import 'package:flutter/material.dart';

import '../core/geo.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/data_gate.dart';
import '../widgets/neu_card.dart';

/// Route: a vertical timeline. Travelled stretches fill in terracotta and a
/// pulsing bus badge sits on the stop the bus is currently closest to.
class RoutePage extends StatelessWidget {
  const RoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DataGate(
      builder: (context, t, route, vehicle) {
        final stops = route.stops;
        final cum = cumulativeKm(route);
        final nearest = t.nearest;
        final busIdx = nearest?.index;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
            children: [
              FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR ROUTE',
                        style: TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(route.name,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.05)),
                    if (route.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(route.description,
                            style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                      ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Pill(Icons.pin_drop_outlined, '${stops.length} stops'),
                        _Pill(Icons.straighten_rounded, '${routeLengthKm(route).toStringAsFixed(1)} km'),
                        _Pill(Icons.directions_bus_outlined, vehicle.code),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.charcoal,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: darkShadow,
                  ),
                  child: Row(
                    children: [
                      PulseDot(
                        color: nearest == null ? AppColors.muted : AppColors.green,
                        size: 10,
                        animate: nearest != null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nearest == null
                              ? 'Waiting for the bus to report its position…'
                              : 'Bus is near ${nearest.stop.name} · ${nearest.km.toStringAsFixed(1)} km away',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < stops.length; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 200 + i * 70),
                  child: _TimelineRow(
                    stop: stops[i],
                    km: cum[i],
                    first: i == 0,
                    last: i == stops.length - 1,
                    topDone: busIdx != null && i <= busIdx,
                    bottomDone: busIdx != null && i < busIdx,
                    passed: busIdx != null && i < busIdx,
                    current: busIdx == i,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        boxShadow: neuShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.terracotta),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stop,
    required this.km,
    required this.first,
    required this.last,
    required this.topDone,
    required this.bottomDone,
    required this.passed,
    required this.current,
  });

  final Stop stop;
  final double km;
  final bool first;
  final bool last;
  final bool topDone;
  final bool bottomDone;
  final bool passed;
  final bool current;

  Widget _line(bool visible, bool done) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 4,
          decoration: BoxDecoration(
            color: !visible
                ? Colors.transparent
                : (done ? AppColors.terracotta : AppColors.line),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _node() {
    if (current) {
      return SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const PulseRing(color: AppColors.terracotta, size: 38),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: darkShadow,
              ),
              child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: 52,
      height: 28,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: passed ? AppColors.terracotta : AppColors.cream,
            border: Border.all(color: AppColors.terracotta, width: 3),
          ),
          child: passed ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = first ? 'Start' : (last ? 'Terminus' : 'Stop ${stop.sequence}');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                _line(!first, topDone),
                _node(),
                _line(!last, bottomDone),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: NeuCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                gradient: current ? AppGradients.charcoal : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: current
                                  ? Colors.white
                                  : (passed ? AppColors.muted : AppColors.ink),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            current
                                ? 'Bus is here'
                                : '$role · ${km.toStringAsFixed(1)} km from start',
                            style: TextStyle(
                              fontSize: 13,
                              color: current ? AppColors.terracottaLight : AppColors.muted,
                              fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (passed)
                      const Icon(Icons.done_all_rounded, color: AppColors.green, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
