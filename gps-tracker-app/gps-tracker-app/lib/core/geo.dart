import 'dart:math' as math;

import '../models/models.dart';

double _rad(double d) => d * math.pi / 180;

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Compass bearing (0 = north, clockwise) from point 1 to point 2.
double bearingDeg(double lat1, double lon1, double lat2, double lon2) {
  final dLon = _rad(lon2 - lon1);
  final y = math.sin(dLon) * math.cos(_rad(lat2));
  final x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
      math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Distance along the route from the first stop to each stop.
List<double> cumulativeKm(RouteInfo route) {
  final out = <double>[];
  double total = 0;
  for (var i = 0; i < route.stops.length; i++) {
    if (i > 0) {
      final a = route.stops[i - 1];
      final b = route.stops[i];
      total += haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);
    }
    out.add(total);
  }
  return out;
}

double routeLengthKm(RouteInfo route) {
  final c = cumulativeKm(route);
  return c.isEmpty ? 0 : c.last;
}

class NearestStop {
  const NearestStop(this.index, this.stop, this.km);
  final int index;
  final Stop stop;
  final double km;
}

NearestStop? nearestStop(RouteInfo route, VehicleLocation? loc) {
  if (loc == null || !loc.hasFix || route.stops.isEmpty) return null;
  NearestStop? best;
  for (var i = 0; i < route.stops.length; i++) {
    final s = route.stops[i];
    final d = haversineKm(loc.latitude!, loc.longitude!, s.latitude, s.longitude);
    if (best == null || d < best.km) best = NearestStop(i, s, d);
  }
  return best;
}
