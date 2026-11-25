import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_app/core/geo.dart';
import 'package:gps_tracker_app/models/models.dart';

RouteInfo _route() => RouteInfo.fromJson({
      'id': 1,
      'name': 'Route A',
      'description': '',
      'stops': [
        {'sequence': 1, 'name': 'A', 'latitude': 12.9249, 'longitude': 80.1000},
        {'sequence': 2, 'name': 'B', 'latitude': 12.9516, 'longitude': 80.1462},
        {'sequence': 3, 'name': 'C', 'latitude': 13.0067, 'longitude': 80.2206},
      ],
    });

void main() {
  test('haversine is roughly right (Tambaram -> Chromepet about 6 km)', () {
    final km = haversineKm(12.9249, 80.1000, 12.9516, 80.1462);
    expect(km, inInclusiveRange(5.5, 7.0));
  });

  test('bearing north is ~0 and east is ~90', () {
    expect(bearingDeg(0, 0, 1, 0), closeTo(0, 0.5));
    expect(bearingDeg(0, 0, 0, 1), closeTo(90, 0.5));
  });

  test('nearest stop picks the closest one', () {
    final loc = VehicleLocation(
      vehicleCode: 'BUS-001',
      status: 'moving',
      latitude: 12.9520,
      longitude: 80.1470,
    );
    final n = nearestStop(_route(), loc)!;
    expect(n.index, 1);
    expect(n.stop.name, 'B');
  });

  test('no fix -> no nearest stop; cumulative km increases', () {
    expect(nearestStop(_route(), VehicleLocation(vehicleCode: 'X', status: 'no_data')), isNull);
    final c = cumulativeKm(_route());
    expect(c.first, 0);
    expect(c[2], greaterThan(c[1]));
  });
}
