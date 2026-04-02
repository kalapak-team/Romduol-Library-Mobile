import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';

  // Token
  static Future<void> saveToken(String token) async =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> deleteToken() => _storage.delete(key: _keyToken);

  // User info
  static Future<void> saveUserId(String id) =>
      _storage.write(key: _keyUserId, value: id);

  static Future<String?> getUserId() => _storage.read(key: _keyUserId);

  static Future<void> saveUserRole(String role) =>
      _storage.write(key: _keyUserRole, value: role);

  static Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  static Future<void> clearAll() => _storage.deleteAll();
}
