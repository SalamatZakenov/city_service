import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://city-service-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Теперь возвращаем String? (null - если успех, текст - если ошибка)
  Future<String?> login(String email, String password) async {
    try {
      debugPrint('=== ОТПРАВЛЯЕМ ЗАПРОС ЛОГИНА ===');
      debugPrint('Email: $email');
      debugPrint('Password: $password');

      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint('=== СЕРВЕР ОТВЕТИЛ УСПЕШНО ===');
      debugPrint('Статус: ${response.statusCode}');
      debugPrint('Тело ответа: ${response.data}');

      if (response.statusCode == 200) {
        // Достаем основной объект data
        final responseData = response.data['data'];
        final token = responseData?['token'];

        // Достаем роль из вложенного объекта user
        final role = responseData?['user']?['role'];

        if (token != null) {
          await SecureStorage.saveToken(token);

          // Сохраняем роль в память (напр. "contractor")
          if (role != null) {
            await SecureStorage.saveRole(role);
            debugPrint('✅ Роль $role сохранена в SecureStorage');
          }

          debugPrint('✅ Токен успешно сохранен!');
          return null;
        } else {
          return 'Сервер ответил 200, но токена в ответе нет';
        }
      }
      return 'Неожиданный статус: ${response.statusCode}';

    } on DioException catch (e) {
      debugPrint('=== ОШИБКА DIO ===');
      debugPrint('Статус: ${e.response?.statusCode}');
      debugPrint('Ответ: ${e.response?.data}');

      if (e.response != null) {
        return 'Ошибка ${e.response?.statusCode}: ${e.response?.data}';
      }
      return 'Ошибка сети: ${e.message}';
    } catch (e) {
      debugPrint('=== НЕИЗВЕСТНАЯ ОШИБКА ===');
      debugPrint(e.toString());
      return 'Внутренняя ошибка: $e';
    }
  }
}