import 'package:dio/dio.dart';

/// A user-presentable API failure. UI code only ever sees this type.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isNetworkError = false});

  final String message;
  final int? statusCode;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'The server took too long to respond. Please try again.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Cannot reach the server. Check your connection and the server address.',
          isNetworkError: true,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return ApiException(_detail(e.response?.data, code), statusCode: code);
      default:
        return ApiException('Something went wrong. Please try again.');
    }
  }

  static String _detail(dynamic data, int? code) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (code == 422) return 'Please check the entered details.';
    if (code != null && code >= 500) return 'Server error ($code). Try again later.';
    return 'Request failed${code != null ? ' ($code)' : ''}.';
  }

  @override
  String toString() => message;
}
