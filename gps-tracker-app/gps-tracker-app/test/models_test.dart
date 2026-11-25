import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_app/core/format.dart';
import 'package:gps_tracker_app/models/models.dart';

void main() {
  test('VehicleLocation with no GPS fix yet', () {
    final loc = VehicleLocation.fromJson({
      'vehicle_id': 1,
      'vehicle_code': 'BUS-001',
      'status': 'no_data',
      'latitude': null,
      'longitude': null,
      'speed': null,
      'recorded_at': null,
    });
    expect(loc.hasFix, isFalse);
    expect(loc.status, 'no_data');
  });

  test('VehicleLocation parses numbers and UTC timestamp', () {
    final loc = VehicleLocation.fromJson({
      'vehicle_id': 1,
      'vehicle_code': 'BUS-001',
      'status': 'moving',
      'latitude': 12.97,
      'longitude': 80,
      'speed': 35,
      'recorded_at': '2026-09-01T10:00:00Z',
    });
    expect(loc.hasFix, isTrue);
    expect(loc.longitude, 80.0);
    expect(loc.recordedAt!.toUtc().hour, 10);
  });

  test('RouteInfo keeps stop order', () {
    final r = RouteInfo.fromJson({
      'id': 1,
      'name': 'Route A',
      'description': 'x',
      'stops': [
        {'sequence': 1, 'name': 'A', 'latitude': 1.0, 'longitude': 2.0},
        {'sequence': 2, 'name': 'B', 'latitude': 3.0, 'longitude': 4.0},
      ],
    });
    expect(r.stops.map((s) => s.name), ['A', 'B']);
  });

  test('formatAgo', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(formatAgo(now.subtract(const Duration(seconds: 2)), now: now), 'just now');
    expect(formatAgo(now.subtract(const Duration(seconds: 30)), now: now), '30s ago');
    expect(formatAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');
  });
}
