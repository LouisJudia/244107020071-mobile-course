import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data source lokal untuk penyimpanan token aman menggunakan Keystore/Keychain
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _emailKey = 'user_email';

  Future<void> save({
    required String access,
    required String refresh,
    String? email,
  }) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    if (email != null) {
      await _storage.write(key: _emailKey, value: email);
    }
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  Future<void> clear() => _storage.deleteAll();
}
