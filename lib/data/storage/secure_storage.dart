import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Сохранить токен
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Получить токен
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Удалить токен (для логаута)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }
}