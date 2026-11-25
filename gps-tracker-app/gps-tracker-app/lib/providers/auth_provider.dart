import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/models.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  /// [requireAdmin] makes the admin app refuse non-administrator accounts.
  /// [minSplash] keeps the intro screen up long enough for its animation.
  AuthProvider(
    this._api,
    this._tokens, {
    this.requireAdmin = false,
    this.minSplash = const Duration(milliseconds: 2400),
  }) {
    _api.onUnauthorized = _handleSessionExpired;
  }

  final ApiClient _api;
  final TokenStorage _tokens;
  final bool requireAdmin;
  final Duration minSplash;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool busy = false;
  String? error;

  static const _notAdmin = 'This account is not an administrator.';

  bool _allowed(AppUser u) => !requireAdmin || u.isAdmin;

  Future<void> restoreSession() async {
    await Future.wait<void>([_restore(), Future<void>.delayed(minSplash)]);
    notifyListeners();
  }

  Future<void> _restore() async {
    final token = await _tokens.read();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      return;
    }
    try {
      final u = await _api.getMe();
      if (_allowed(u)) {
        user = u;
        status = AuthStatus.authenticated;
      } else {
        await _tokens.clear();
        status = AuthStatus.unauthenticated;
      }
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        error = e.message; // keep the token, let the user retry
      } else {
        await _tokens.clear();
      }
      status = AuthStatus.unauthenticated;
    }
  }

  Future<bool> _finish(Future<String> Function() getToken) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final token = await getToken();
      await _tokens.write(token);
      final u = await _api.getMe();
      if (!_allowed(u)) {
        await _tokens.clear();
        error = _notAdmin;
        return false;
      }
      user = u;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      await _tokens.clear();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) =>
      _finish(() => _api.login(email.trim().toLowerCase(), password));

  Future<bool> register(String fullName, String email, String password) => _finish(
      () => _api.register(fullName.trim(), email.trim().toLowerCase(), password));

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokens.clear();
    user = null;
    error = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _handleSessionExpired() {
    if (status != AuthStatus.authenticated) return;
    _tokens.clear();
    user = null;
    error = 'Your session expired. Please sign in again.';
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
