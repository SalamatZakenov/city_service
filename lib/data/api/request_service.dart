import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class RequestService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://city-service-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // ==========================================
  // 1. Получить список всех заявок
  // ==========================================
  Future<List<dynamic>> getRequests() async {
    try {
      final token = await SecureStorage.getToken();

      if (token == null) {
        debugPrint('Токен не найден! Нужно заново авторизоваться.');
        return [];
      }

      final response = await _dio.get(
        '/requests',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Заявки успешно загружены!');

        if (response.data is List) {
          return response.data;
        } else if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'];
        }

        return response.data;
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Ошибка сервера при загрузке заявок: ${e.response?.statusCode}');
      debugPrint('Тело ответа: ${e.response?.data}');
      return [];
    } catch (e) {
      debugPrint('Неизвестная ошибка: $e');
      return [];
    }
  }

  // ==========================================
  // 2. ВОТ НАШ НОВЫЙ КОД: Создание новой заявки
  // ==========================================
  Future<String?> createRequest({
    required String title,
    required int categoryId,
    required String description,
    required String urgency,
    required String location,
    String? deadline,
  }) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return 'Необходима авторизация';

      // Упаковываем данные в формат multipart/form-data
      final formData = FormData.fromMap({
        'title': title,
        'category_id': categoryId,
        'description': description,
        'urgency': urgency,
        'location': location,
        if (deadline != null) 'deadline': deadline,
      });

      debugPrint('=== ОТПРАВЛЯЕМ НОВУЮ ЗАЯВКУ ===');
      final response = await _dio.post(
        '/requests',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Заявка успешно создана!');
        return null; // Нет ошибок
      }
      return 'Неожиданный ответ сервера: ${response.statusCode}';

    } on DioException catch (e) {
      debugPrint('Ошибка создания заявки: ${e.response?.data}');
      return 'Ошибка: ${e.response?.data ?? e.message}';
    } catch (e) {
      return 'Внутренняя ошибка: $e';
    }
  }
  // ==========================================
  // 3. Получить список категорий с сервера
  // ==========================================
  Future<List<dynamic>> getCategories() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Бэкенд возвращает JSON, где массив лежит внутри ключа "data" (судя по твоему скриншоту)
        if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'];
        }
        return response.data;
      }
      return [];
    } catch (e) {
      debugPrint('Ошибка загрузки категорий: $e');
      return [];
    }
  }
}