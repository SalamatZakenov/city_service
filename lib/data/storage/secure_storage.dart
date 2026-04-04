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

  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  // === ДОБАВЬ ЭТИ МЕТОДЫ В КЛАСС SecureStorage ===

  // Удалить роль
  static Future<void> deleteRole() async {
    // Убедись, что ключ ('role' или 'user_role') совпадает с тем, что в методе saveRole/getRole
    await _storage.delete(key: 'role');
  }

  // Удалить токен (если его вдруг тоже нет)
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }
}