import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class AuthService {
  // Берем адрес из строки браузера, а не из текста внутри Swagger
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://city-service-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];

        if (token != null) {
          await SecureStorage.saveToken(token);
          debugPrint('✅ Успешный логин! Токен сохранен: $token');
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Ошибка сервера: ${e.response?.statusCode}');
      debugPrint('Тело ответа: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Неизвестная ошибка: $e');
      return false;
    }
  }
}