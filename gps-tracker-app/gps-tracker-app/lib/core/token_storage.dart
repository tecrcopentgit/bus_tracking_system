import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT in the platform keystore (Keychain / EncryptedSharedPreferences).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage, String key = 'access_token'})
      : _key = key,
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final String _key;
  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> clear() => _storage.delete(key: _key);
}
