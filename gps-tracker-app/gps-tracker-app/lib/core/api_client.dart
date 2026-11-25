import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_exception.dart';
import 'config.dart';
import 'token_storage.dart';

/// Thin typed wrapper around the backend. Every failure is surfaced as [ApiException].
class ApiClient {
  ApiClient(this._tokens, {String baseUrl = apiBaseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: '$baseUrl/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Accept': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        // An expired/revoked token anywhere in the app -> back to login.
        // (A wrong password on the login call itself is not a session expiry.)
        if (e.response?.statusCode == 401 &&
            !e.requestOptions.path.endsWith('/auth/login')) {
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));
  }

  final Dio _dio;
  final TokenStorage _tokens;

  /// Set by AuthProvider; called when the server rejects our token.
  void Function()? onUnauthorized;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> login(String email, String password) => _guard(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        return r.data!['access_token'] as String;
      });

  Future<String> register(String fullName, String email, String password) =>
      _guard(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {'full_name': fullName, 'email': email, 'password': password},
        );
        return r.data!['access_token'] as String;
      });

  /// Generic call used by the admin screens. 204 responses return null.
  Future<dynamic> request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) =>
      _guard(() async {
        final r = await _dio.request<dynamic>(
          path,
          data: data,
          queryParameters: query,
          options: Options(method: method),
        );
        return r.data;
      });

  Future<AppUser> getMe() => _guard(() async {
        final r = await _dio.get<Map<String, dynamic>>('/me');
        return AppUser.fromJson(r.data!);
      });

  Future<RouteInfo> getMyRoute() => _guard(() async {
        final r = await _dio.get<Map<String, dynamic>>('/me/route');
        return RouteInfo.fromJson(r.data!);
      });

  Future<Vehicle> getMyVehicle() => _guard(() async {
        final r = await _dio.get<Map<String, dynamic>>('/me/vehicle');
        return Vehicle.fromJson(r.data!);
      });

  Future<VehicleLocation> getMyLocation() => _guard(() async {
        final r = await _dio.get<Map<String, dynamic>>('/me/vehicle/location');
        return VehicleLocation.fromJson(r.data!);
      });
}
