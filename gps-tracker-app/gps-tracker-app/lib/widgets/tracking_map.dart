import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';
import 'status_chip.dart';

// Warm, slightly desaturated tint so OpenStreetMap tiles match the sand palette.
const ColorFilter warmTiles = ColorFilter.matrix(<double>[
  0.93, 0.10, 0.00, 0, 8,
  0.04, 0.88, 0.04, 0, 3,
  0.00, 0.08, 0.72, 0, -4,
  0.00, 0.00, 0.00, 1, 0,
]);

/// Live map: route line, start/end pins, stops and a bus marker that glides
/// smoothly to each new GPS fix, rotates toward its heading and pulses.
class TrackingMap extends StatefulWidget {
  const TrackingMap({
    super.key,
    required this.route,
    required this.location,
    this.interactive = true,
    this.showControls = true,
    this.controlsTop = 12,
    this.bottomInset = 0,
  });

  final RouteInfo route;
  final VehicleLocation? location;
  final bool interactive;
  final bool showControls;
  final double controlsTop;
  final double bottomInset;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> with TickerProviderStateMixin {
  static const _fallbackCenter = LatLng(13.0827, 80.2707);

  final MapController _controller = MapController();
  late final AnimationController _move =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  LatLng? _from;
  LatLng? _to;
  double _heading = 0;
  bool _follow = false;

  List<LatLng> get _routePoints =>
      widget.route.stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

  LatLng? get _bus {
    final l = widget.location;
    return (l != null && l.hasFix) ? LatLng(l.latitude!, l.longitude!) : null;
  }

  CameraFit _fit(List<LatLng> pts) => CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.all(44),
      );

  @override
  void initState() {
    super.initState();
    _from = _bus;
    _to = _bus;
    _move.addListener(_onTick);
  }

  LatLng? _current() {
    final to = _to;
    final from = _from;
    if (to == null) return null;
    if (from == null) return to;
    final t = Curves.easeInOut.transform(_move.value);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  void _onTick() {
    if (!_follow) return;
    final c = _current();
    if (c == null) return;
    try {
      _controller.move(c, _controller.camera.zoom);
    } catch (_) {
      // map not attached yet
    }
  }

  @override
  void didUpdateWidget(TrackingMap old) {
    super.didUpdateWidget(old);
    final b = _bus;
    if (b != null && b != _to) {
      final cur = _current() ?? b;
      if (haversineKm(cur.latitude, cur.longitude, b.latitude, b.longitude) > 0.002) {
        _heading = bearingDeg(cur.latitude, cur.longitude, b.latitude, b.longitude);
      }
      _from = cur;
      _to = b;
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _routePoints;
    final bus = _bus;
    final stops = widget.route.stops;
    final flags = widget.interactive ? InteractiveFlag.all : InteractiveFlag.none;
    final statusColor = statusStyle(widget.location?.status ?? 'no_data').color;

    final options = points.length >= 2
        ? MapOptions(
            initialCameraFit: _fit(points),
            interactionOptions: InteractionOptions(flags: flags),
          )
        : MapOptions(
            initialCenter: bus ?? (points.isNotEmpty ? points.first : _fallbackCenter),
            initialZoom: 13,
            interactionOptions: InteractionOptions(flags: flags),
          );

    Widget dot() => Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.terracotta, width: 3),
          ),
        );

    final stopMarkers = <Marker>[];
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final isStart = i == 0 && stops.length > 1;
      final isEnd = i == stops.length - 1 && stops.length > 1;
      if (isStart || isEnd) {
        stopMarkers.add(Marker(
          point: LatLng(s.latitude, s.longitude),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: Tooltip(
            message: s.name,
            child: Icon(
              Icons.location_on_rounded,
              size: 40,
              color: isStart ? AppColors.green : AppColors.pink,
              shadows: const [Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
          ),
        ));
      } else {
        stopMarkers.add(Marker(
          point: LatLng(s.latitude, s.longitude),
          width: 16,
          height: 16,
          child: Tooltip(message: s.name, child: dot()),
        ));
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: options,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.gps_tracker_app',
              tileBuilder: (context, tileWidget, tile) =>
                  ColorFiltered(colorFilter: warmTiles, child: tileWidget),
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 6,
                  color: AppColors.terracotta,
                  borderStrokeWidth: 2.5,
                  borderColor: Colors.white,
                ),
              ],
            ),
            MarkerLayer(markers: stopMarkers),
            AnimatedBuilder(
              animation: Listenable.merge([_move, _pulse]),
              builder: (context, _) {
                final pos = _current();
                if (pos == null) return const SizedBox.shrink();
                return MarkerLayer(
                  markers: [
                    Marker(
                      point: pos,
                      width: 96,
                      height: 96,
                      child: _BusMarker(
                        color: statusColor,
                        heading: _heading,
                        pulse: _pulse.value,
                      ),
                    ),
                  ],
                );
              },
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
            ),
          ],
        ),
        if (widget.showControls)
          Positioned(
            top: widget.controlsTop,
            right: 14,
            child: Column(
              children: [
                RoundIconButton(
                  icon: Icons.route_rounded,
                  tooltip: 'Show whole route',
                  onTap: points.length >= 2 ? () => _controller.fitCamera(_fit(points)) : null,
                ),
                const SizedBox(height: 10),
                RoundIconButton(
                  icon: Icons.my_location_rounded,
                  tooltip: _follow ? 'Stop following' : 'Follow bus',
                  active: _follow,
                  onTap: bus == null
                      ? null
                      : () {
                          setState(() => _follow = !_follow);
                          final c = _current();
                          if (_follow && c != null) _controller.move(c, 16);
                        },
                ),
              ],
            ),
          ),
        if (bus == null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18 + widget.bottomInset,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                boxShadow: neuShadow,
              ),
              child: const Text(
                'No GPS signal from the bus yet. It will appear here as soon as it reports.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _BusMarker extends StatelessWidget {
  const _BusMarker({required this.color, required this.heading, required this.pulse});
  final Color color;
  final double heading;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scale: 1 + pulse * 1.05,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(((1 - pulse) * 110).round()),
            ),
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Transform.rotate(
            angle: heading * math.pi / 180,
            child: Icon(Icons.navigation_rounded, color: color, size: 26),
          ),
        ),
      ],
    );
  }
}
