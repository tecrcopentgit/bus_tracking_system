import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/config.dart';
import '../core/geo.dart';
import '../models/models.dart';

class SpeedSample {
  const SpeedSample(this.time, this.speed);
  final DateTime time;
  final double speed;
}

/// Loads the user's route + vehicle once, then polls the latest location.
/// Created when the Home screen opens and disposed on logout, so polling never
/// outlives the session.
class TrackingProvider extends ChangeNotifier {
  TrackingProvider(this._api);

  final ApiClient _api;

  bool loading = true;
  String? error; // fatal: couldn't load route/vehicle at all
  String? locationError; // non-fatal: refresh failed, showing last known data
  RouteInfo? route;
  Vehicle? vehicle;
  VehicleLocation? location;

  /// Recent speeds seen while the app was open (oldest first, max 12).
  final List<SpeedSample> samples = [];

  NearestStop? get nearest => route == null ? null : nearestStop(route!, location);

  void _record(VehicleLocation? l) {
    final at = l?.recordedAt;
    if (l == null || !l.hasFix || at == null) return;
    if (samples.isNotEmpty && samples.last.time == at) return;
    samples.add(SpeedSample(at, l.speed ?? 0));
    if (samples.length > 12) samples.removeAt(0);
  }

  Timer? _timer;
  bool _refreshing = false;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        _api.getMyRoute(),
        _api.getMyVehicle(),
        _api.getMyLocation(),
      ]);
      route = results[0] as RouteInfo;
      vehicle = results[1] as Vehicle;
      location = results[2] as VehicleLocation;
      locationError = null;
      _record(location);
      _startPolling();
    } on ApiException catch (e) {
      error = e.statusCode == 404
          ? 'No route or vehicle has been assigned to your account yet. '
              'Please ask your administrator, then tap Try again.'
          : e.message;
    } finally {
      loading = false;
      _notify();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(locationPollInterval, (_) => refreshLocation());
  }

  Future<void> refreshLocation() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    try {
      // Fetch vehicle too so the status chip (moving / idle / offline) stays live.
      final results = await Future.wait<Object>([
        _api.getMyLocation(),
        _api.getMyVehicle(),
      ]);
      location = results[0] as VehicleLocation;
      vehicle = results[1] as Vehicle;
      locationError = null;
      _record(location);
    } on ApiException catch (e) {
      locationError = e.message; // keep last known position visible
    } finally {
      _refreshing = false;
      _notify();
    }
  }

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
