import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Only the JWT lives here. Never store passwords, secrets, or raw
/// credentials on-device — the backend is the source of truth for auth.
class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'unidocs_access_token';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
