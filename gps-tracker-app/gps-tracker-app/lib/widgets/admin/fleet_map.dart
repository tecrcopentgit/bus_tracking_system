import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../pressable.dart';
import '../status_chip.dart';
import '../tracking_map.dart' show warmTiles;

const _routeColors = [
  AppColors.terracotta,
  AppColors.sky,
  AppColors.green,
  AppColors.amber,
  AppColors.pink,
];

/// Every route as a coloured line and every bus (with a fix) as a status-coloured marker.
class FleetMap extends StatefulWidget {
  const FleetMap({
    super.key,
    required this.routes,
    required this.vehicles,
    required this.onVehicleTap,
    this.selectedId,
  });

  final List<AdminRoute> routes;
  final List<AdminVehicle> vehicles;
  final ValueChanged<AdminVehicle> onVehicleTap;
  final int? selectedId;

  @override
  State<FleetMap> createState() => _FleetMapState();
}

class _FleetMapState extends State<FleetMap> {
  static const _fallback = LatLng(13.0827, 80.2707);
  final MapController _controller = MapController();

  List<LatLng> get _allPoints => [
        for (final r in widget.routes)
          for (final s in r.stops) LatLng(s.latitude, s.longitude),
        for (final v in widget.vehicles)
          if (v.hasFix) LatLng(v.latitude!, v.longitude!),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pts = _allPoints;
    final options = pts.length >= 2
        ? MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(pts),
              padding: const EdgeInsets.all(48),
            ),
          )
        : MapOptions(initialCenter: pts.isNotEmpty ? pts.first : _fallback, initialZoom: 12);

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
                for (var i = 0; i < widget.routes.length; i++)
                  Polyline(
                    points: [for (final s in widget.routes[i].stops) LatLng(s.latitude, s.longitude)],
                    strokeWidth: 5,
                    color: _routeColors[i % _routeColors.length].withAlpha(200),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final v in widget.vehicles)
                  if (v.hasFix && v.isActive)
                    Marker(
                      point: LatLng(v.latitude!, v.longitude!),
                      width: 84,
                      height: 64,
                      child: _VehicleMarker(
                        vehicle: v,
                        selected: v.id == widget.selectedId,
                        onTap: () => widget.onVehicleTap(v),
                      ),
                    ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
            ),
          ],
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Pressable(
            onTap: pts.length >= 2
                ? () => _controller.fitCamera(CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(pts),
                      padding: const EdgeInsets.all(48),
                    ))
                : null,
            scale: 0.88,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                boxShadow: neuShadow,
              ),
              child: const Icon(Icons.zoom_out_map_rounded, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.vehicle, required this.selected, required this.onTap});
  final AdminVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statusStyle(vehicle.status).color;
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(vehicle.code,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: selected ? 40 : 34,
            height: selected ? 40 : 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
