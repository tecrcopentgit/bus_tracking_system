/// Plain data classes mirroring the backend's JSON.

double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.routeId,
    this.vehicleId,
    this.isAdmin = false,
  });

  final int id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final int? routeId;
  final int? vehicleId;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String,
        fullName: j['full_name'] as String,
        routeId: j['route_id'] as int?,
        vehicleId: j['vehicle_id'] as int?,
        isAdmin: (j['is_admin'] as bool?) ?? false,
      );
}

class Stop {
  Stop({
    required this.sequence,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final int sequence;
  final String name;
  final double latitude;
  final double longitude;

  factory Stop.fromJson(Map<String, dynamic> j) => Stop(
        sequence: j['sequence'] as int,
        name: j['name'] as String,
        latitude: _d(j['latitude'])!,
        longitude: _d(j['longitude'])!,
      );
}

class RouteInfo {
  RouteInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
  });

  final int id;
  final String name;
  final String description;
  final List<Stop> stops;

  factory RouteInfo.fromJson(Map<String, dynamic> j) => RouteInfo(
        id: j['id'] as int,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        stops: (j['stops'] as List)
            .map((s) => Stop.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// moving | idle | offline | no_data
class Vehicle {
  Vehicle({
    required this.id,
    required this.code,
    required this.plateNumber,
    required this.status,
    this.lastSeen,
  });

  final int id;
  final String code;
  final String plateNumber;
  final String status;
  final DateTime? lastSeen;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as int,
        code: j['code'] as String,
        plateNumber: (j['plate_number'] as String?) ?? '',
        status: j['status'] as String,
        lastSeen: j['last_seen'] == null
            ? null
            : DateTime.parse(j['last_seen'] as String).toLocal(),
      );
}

class VehicleLocation {
  VehicleLocation({
    required this.vehicleCode,
    required this.status,
    this.latitude,
    this.longitude,
    this.speed,
    this.recordedAt,
  });

  final String vehicleCode;
  final String status;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final DateTime? recordedAt;

  /// False until the vehicle has reported at least once.
  bool get hasFix => latitude != null && longitude != null;

  factory VehicleLocation.fromJson(Map<String, dynamic> j) => VehicleLocation(
        vehicleCode: j['vehicle_code'] as String,
        status: j['status'] as String,
        latitude: _d(j['latitude']),
        longitude: _d(j['longitude']),
        speed: _d(j['speed']),
        recordedAt: j['recorded_at'] == null
            ? null
            : DateTime.parse(j['recorded_at'] as String).toLocal(),
      );
}
