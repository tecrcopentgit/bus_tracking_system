import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/admin_models.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_common.dart';
import '../../widgets/buttons.dart';
import '../../widgets/tracking_map.dart' show warmTiles;

class _Draft {
  _Draft(String name, this.lat, this.lon) : ctrl = TextEditingController(text: name);
  final TextEditingController ctrl;
  final double lat;
  final double lon;
}

/// Create or edit a route by tapping the map to add stops in order.
class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({super.key, this.route, required this.parentContext});
  final AdminRoute? route;
  final BuildContext parentContext;

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  static const _fallback = LatLng(13.0827, 80.2707);

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _stops = <_Draft>[];
  final _removed = <_Draft>[]; // controllers are disposed with the screen, not on removal
  final _map = MapController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    if (r != null) {
      _name.text = r.name;
      _desc.text = r.description;
      for (final s in r.stops) {
        _stops.add(_Draft(s.name, s.latitude, s.longitude));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    for (final s in [..._stops, ..._removed]) {
      s.ctrl.dispose();
    }
    _map.dispose();
    super.dispose();
  }

  void _add(LatLng p) {
    setState(() => _stops.add(_Draft('Stop ${_stops.length + 1}', p.latitude, p.longitude)));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showMessage(context, 'Give the route a name', error: true);
      return;
    }
    if (_stops.length < 2) {
      showMessage(context, 'Add at least two stops by tapping the map', error: true);
      return;
    }
    final stops = <Stop>[
      for (var i = 0; i < _stops.length; i++)
        Stop(
          sequence: i + 1,
          name: _stops[i].ctrl.text.trim().isEmpty ? 'Stop ${i + 1}' : _stops[i].ctrl.text.trim(),
          latitude: _stops[i].lat,
          longitude: _stops[i].lon,
        ),
    ];
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => context.read<AdminProvider>().saveRoute(
            id: widget.route?.id,
            name: name,
            description: _desc.text.trim(),
            stops: stops,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) showMessage(widget.parentContext, 'Route saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = [for (final s in _stops) LatLng(s.lat, s.lon)];
    final options = points.length >= 2
        ? MapOptions(
            onTap: (_, p) => _add(p),
            initialCameraFit:
                CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(48)),
          )
        : MapOptions(
            onTap: (_, p) => _add(p),
            initialCenter: points.isNotEmpty ? points.first : _fallback,
            initialZoom: 12,
          );

    return Scaffold(
      appBar: AppBar(title: Text(widget.route == null ? 'New route' : 'Edit route')),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: options,
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.gps_tracker_app',
                      tileBuilder: (context, w, tile) => ColorFiltered(colorFilter: warmTiles, child: w),
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 5,
                          color: AppColors.terracotta,
                          borderStrokeWidth: 2,
                          borderColor: Colors.white,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (var i = 0; i < _stops.length; i++)
                          Marker(
                            point: points[i],
                            width: 30,
                            height: 30,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppColors.green
                                    : (i == _stops.length - 1 ? AppColors.pink : AppColors.charcoal),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: Text('${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: neuShadow,
                    ),
                    child: const Text('Tap the map to add stops in order',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Route name', prefixIcon: Icon(Icons.alt_route_rounded)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_rounded)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Stops (${_stops.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    if (_stops.isNotEmpty)
                      TextButton(onPressed: () => setState(() {
                          _removed.addAll(_stops);
                          _stops.clear();
                        }),
                        child: const Text('Clear all')),
                  ],
                ),
                const SizedBox(height: 6),
                if (_stops.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('No stops yet. Tap the map above.', style: TextStyle(color: AppColors.muted)),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: (from, to) => setState(() {
                      if (to > from) to -= 1;
                      _stops.insert(to, _stops.removeAt(from));
                    }),
                    children: [
                      for (var i = 0; i < _stops.length; i++)
                        Container(
                          key: ObjectKey(_stops[i]),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: neuShadow,
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.drag_indicator_rounded, color: AppColors.muted),
                                ),
                              ),
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: AppColors.terracotta,
                                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _stops[i].ctrl,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    Text('${_stops[i].lat.toStringAsFixed(5)}, ${_stops[i].lon.toStringAsFixed(5)}',
                                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove stop',
                                icon: const Icon(Icons.close_rounded, color: AppColors.pink),
                                onPressed: () => setState(() => _removed.add(_stops.removeAt(i))),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                GradientButton(
                  label: widget.route == null ? 'Create route' : 'Save route',
                  icon: Icons.check_rounded,
                  busy: _busy,
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
