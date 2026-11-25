import 'models.dart';

double? _d(dynamic v) => v == null ? null : (v as num).toDouble();

class AdminUser {
  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isAdmin,
    this.routeId,
    this.vehicleId,
    this.routeName,
    this.vehicleCode,
  });

  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isAdmin;
  final int? routeId;
  final int? vehicleId;
  final String? routeName;
  final String? vehicleCode;

  bool get assigned => vehicleId != null;

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as int,
        email: j['email'] as String,
        fullName: j['full_name'] as String,
        isActive: j['is_active'] as bool,
        isAdmin: j['is_admin'] as bool,
        routeId: j['route_id'] as int?,
        vehicleId: j['vehicle_id'] as int?,
        routeName: j['route_name'] as String?,
        vehicleCode: j['vehicle_code'] as String?,
      );
}

class AdminVehicle {
  AdminVehicle({
    required this.id,
    required this.code,
    required this.plateNumber,
    required this.routeId,
    required this.routeName,
    required this.isActive,
    required this.status,
    required this.userCount,
    this.lastSeen,
    this.latitude,
    this.longitude,
    this.speed,
  });

  final int id;
  final String code;
  final String plateNumber;
  final int routeId;
  final String routeName;
  final bool isActive;
  final String status; // moving | idle | offline | no_data
  final int userCount;
  final DateTime? lastSeen;
  final double? latitude;
  final double? longitude;
  final double? speed;

  bool get hasFix => latitude != null && longitude != null;

  factory AdminVehicle.fromJson(Map<String, dynamic> j) => AdminVehicle(
        id: j['id'] as int,
        code: j['code'] as String,
        plateNumber: (j['plate_number'] as String?) ?? '',
        routeId: j['route_id'] as int,
        routeName: (j['route_name'] as String?) ?? '',
        isActive: j['is_active'] as bool,
        status: j['status'] as String,
        userCount: (j['user_count'] as int?) ?? 0,
        lastSeen: j['last_seen'] == null ? null : DateTime.parse(j['last_seen'] as String).toLocal(),
        latitude: _d(j['latitude']),
        longitude: _d(j['longitude']),
        speed: _d(j['speed']),
      );
}

class AdminRoute {
  AdminRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
    required this.vehicleCount,
    required this.userCount,
  });

  final int id;
  final String name;
  final String description;
  final List<Stop> stops;
  final int vehicleCount;
  final int userCount;

  RouteInfo toRouteInfo() =>
      RouteInfo(id: id, name: name, description: description, stops: stops);

  factory AdminRoute.fromJson(Map<String, dynamic> j) => AdminRoute(
        id: j['id'] as int,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        stops: (j['stops'] as List).map((s) => Stop.fromJson(s as Map<String, dynamic>)).toList(),
        vehicleCount: (j['vehicle_count'] as int?) ?? 0,
        userCount: (j['user_count'] as int?) ?? 0,
      );
}

class FleetOverview {
  FleetOverview({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.moving,
    required this.idle,
    required this.offline,
    required this.noData,
    required this.totalUsers,
    required this.unassignedUsers,
    required this.totalRoutes,
    required this.vehicles,
  });

  final int totalVehicles;
  final int activeVehicles;
  final int moving;
  final int idle;
  final int offline;
  final int noData;
  final int totalUsers;
  final int unassignedUsers;
  final int totalRoutes;
  final List<AdminVehicle> vehicles;

  factory FleetOverview.fromJson(Map<String, dynamic> j) => FleetOverview(
        totalVehicles: j['total_vehicles'] as int,
        activeVehicles: j['active_vehicles'] as int,
        moving: j['moving'] as int,
        idle: j['idle'] as int,
        offline: j['offline'] as int,
        noData: j['no_data'] as int,
        totalUsers: j['total_users'] as int,
        unassignedUsers: j['unassigned_users'] as int,
        totalRoutes: j['total_routes'] as int,
        vehicles: (j['vehicles'] as List)
            .map((v) => AdminVehicle.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class HistoryPoint {
  HistoryPoint(this.latitude, this.longitude, this.speed, this.recordedAt);
  final double latitude;
  final double longitude;
  final double speed;
  final DateTime recordedAt;

  factory HistoryPoint.fromJson(Map<String, dynamic> j) => HistoryPoint(
        (j['latitude'] as num).toDouble(),
        (j['longitude'] as num).toDouble(),
        (j['speed'] as num).toDouble(),
        DateTime.parse(j['recorded_at'] as String).toLocal(),
      );
}
