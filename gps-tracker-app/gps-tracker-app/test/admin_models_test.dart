import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_app/models/admin_models.dart';
import 'package:gps_tracker_app/models/models.dart';

void main() {
  test('AppUser reads is_admin (defaults to false)', () {
    final base = {'id': 1, 'email': 'a@b.c', 'full_name': 'A', 'route_id': null, 'vehicle_id': null};
    expect(AppUser.fromJson(base).isAdmin, isFalse);
    expect(AppUser.fromJson({...base, 'is_admin': true}).isAdmin, isTrue);
  });

  test('FleetOverview parses vehicles with and without a GPS fix', () {
    final o = FleetOverview.fromJson({
      'total_vehicles': 2,
      'active_vehicles': 2,
      'moving': 1,
      'idle': 0,
      'offline': 0,
      'no_data': 1,
      'total_users': 3,
      'unassigned_users': 1,
      'total_routes': 2,
      'vehicles': [
        {
          'id': 1, 'code': 'BUS-001', 'plate_number': 'X', 'route_id': 1, 'route_name': 'Route A',
          'is_active': true, 'status': 'moving', 'last_seen': '2026-09-01T10:00:00Z',
          'latitude': 12.9, 'longitude': 80.1, 'speed': 30, 'user_count': 2,
        },
        {
          'id': 2, 'code': 'BUS-002', 'plate_number': '', 'route_id': 2, 'route_name': 'Route B',
          'is_active': true, 'status': 'no_data', 'last_seen': null,
          'latitude': null, 'longitude': null, 'speed': null, 'user_count': 0,
        },
      ],
    });
    expect(o.vehicles.first.hasFix, isTrue);
    expect(o.vehicles.last.hasFix, isFalse);
    expect(o.noData, 1);
  });

  test('AdminUser assignment flag', () {
    final u = AdminUser.fromJson({
      'id': 5, 'email': 'x@y.z', 'full_name': 'X', 'is_active': true, 'is_admin': false,
      'route_id': 1, 'vehicle_id': 1, 'route_name': 'Route A', 'vehicle_code': 'BUS-001',
    });
    expect(u.assigned, isTrue);
    expect(u.vehicleCode, 'BUS-001');
  });
}
