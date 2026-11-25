import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/admin_models.dart';
import '../models/models.dart';

/// All admin data + actions. Overview (fleet) refreshes every few seconds;
/// users and routes reload after each change or on pull-to-refresh.
/// Action methods throw [ApiException] so the UI can show the server message.
class AdminProvider extends ChangeNotifier {
  AdminProvider(this._api);

  final ApiClient _api;

  bool loading = true;
  String? error; // fatal: nothing could be loaded
  String? liveError; // non-fatal: background refresh failed
  FleetOverview? overview;
  List<AdminUser> users = [];
  List<AdminRoute> routes = [];

  Timer? _timer;
  bool _disposed = false;
  bool _refreshingLive = false;

  List<AdminVehicle> get vehicles => overview?.vehicles ?? const [];

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
      (data as List).map((e) => f(e as Map<String, dynamic>)).toList();

  Future<void> _fetchAll() async {
    final r = await Future.wait<dynamic>([
      _api.request('GET', '/admin/overview'),
      _api.request('GET', '/admin/users'),
      _api.request('GET', '/admin/routes'),
    ]);
    overview = FleetOverview.fromJson(r[0] as Map<String, dynamic>);
    users = _list(r[1], AdminUser.fromJson);
    routes = _list(r[2], AdminRoute.fromJson);
    liveError = null;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      await _fetchAll();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => refreshLive());
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      _notify();
    }
  }

  /// Quiet background refresh of the fleet overview.
  Future<void> refreshLive() async {
    if (_refreshingLive || _disposed) return;
    _refreshingLive = true;
    try {
      overview = FleetOverview.fromJson(
          await _api.request('GET', '/admin/overview') as Map<String, dynamic>);
      liveError = null;
    } on ApiException catch (e) {
      liveError = e.message;
    } finally {
      _refreshingLive = false;
      _notify();
    }
  }

  /// Reload everything (used after changes and by pull-to-refresh).
  Future<void> refreshAll() async {
    try {
      await _fetchAll();
    } on ApiException catch (e) {
      liveError = e.message;
    }
    _notify();
  }

  Future<void> _then(Future<dynamic> action) async {
    await action; // let ApiException propagate to the caller
    await refreshAll();
  }

  // ---- users
  Future<void> createUser({
    required String fullName,
    required String email,
    required String password,
    bool isAdmin = false,
    int? routeId,
    int? vehicleId,
  }) =>
      _then(_api.request('POST', '/admin/users', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'is_admin': isAdmin,
        if (routeId != null && vehicleId != null) 'route_id': routeId,
        if (routeId != null && vehicleId != null) 'vehicle_id': vehicleId,
      }));

  Future<void> updateUser(int id, Map<String, dynamic> changes) =>
      _then(_api.request('PATCH', '/admin/users/$id', data: changes));

  Future<void> assign(int userId, int routeId, int vehicleId) => _then(_api.request(
      'PUT', '/admin/users/$userId/assignment',
      data: {'route_id': routeId, 'vehicle_id': vehicleId}));

  Future<void> unassign(int userId) =>
      _then(_api.request('DELETE', '/admin/users/$userId/assignment'));

  // ---- vehicles
  Future<void> createVehicle(String code, String plate, int routeId) =>
      _then(_api.request('POST', '/admin/vehicles',
          data: {'code': code, 'plate_number': plate, 'route_id': routeId}));

  Future<void> updateVehicle(int id, Map<String, dynamic> changes) =>
      _then(_api.request('PATCH', '/admin/vehicles/$id', data: changes));

  Future<List<HistoryPoint>> vehicleHistory(int id, {int limit = 15}) async {
    final data = await _api.request('GET', '/admin/vehicles/$id/history',
        query: {'limit': limit}) as Map<String, dynamic>;
    return _list(data['points'], HistoryPoint.fromJson);
  }

  // ---- routes
  Future<void> saveRoute({
    int? id,
    required String name,
    required String description,
    required List<Stop> stops,
  }) {
    final body = {
      'name': name,
      'description': description,
      'stops': [
        for (final s in stops)
          {'name': s.name, 'latitude': s.latitude, 'longitude': s.longitude},
      ],
    };
    return _then(id == null
        ? _api.request('POST', '/admin/routes', data: body)
        : _api.request('PUT', '/admin/routes/$id', data: body));
  }

  Future<void> deleteRoute(int id) => _then(_api.request('DELETE', '/admin/routes/$id'));

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
