import 'dart:io'; // Добавили для File
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart'; // Добавили для basename
import '../storage/secure_storage.dart';

class RequestService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://city-service-production.up.railway.app/api',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // 1. Получить список всех заявок
  Future<List<dynamic>> getRequests() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/requests',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          return response.data;
        } else if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'];
        }
        return response.data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

// === ОБНОВЛЕННЫЙ МЕТОД: Создание заявки (возвращает Map с ID) ===
  Future<Map<String, dynamic>> createRequest({
    required String title,
    required int categoryId,
    required String description,
    required String urgency,
    required String location,
    String? deadline,
    File? photo,
  }) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return {'success': false, 'error': 'Необходима авторизация'};

      final Map<String, dynamic> formDataMap = {
        'title': title,
        'category_id': categoryId,
        'description': description,
        'urgency': urgency,
        'location': location,
        if (deadline != null) 'deadline': deadline,
      };

      if (photo != null) {
        final String fileName = basename(photo.path);
        formDataMap['photo'] = await MultipartFile.fromFile(photo.path, filename: fileName);
      }

      final formData = FormData.fromMap(formDataMap);

      debugPrint('=== ОТПРАВЛЯЕМ НОВУЮ ЗАЯВКУ С ФОТО ===');
      final response = await _dio.post(
        '/requests',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Заявка успешно создана!');

        String newId = '';
        if (response.data is Map) {
          newId = response.data['id']?.toString() ?? response.data['data']?['id']?.toString() ?? '';
        }

        return {'success': true, 'id': newId};
      }
      return {'success': false, 'error': 'Неожиданный ответ сервера: ${response.statusCode}'};

    } on DioException catch (e) {
      debugPrint('Ошибка Dio: ${e.response?.data}');
      String errorMessage = 'Ошибка сервера ${e.response?.statusCode ?? ""}';

      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['error'] ?? e.response?.data['message'] ?? errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = 'Сервер временно недоступен (503). Попробуйте без фото.';
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Внутренняя ошибка: $e'};
    }
  }

  // 3. Получить список категорий (без изменений)
  Future<List<dynamic>> getCategories() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'];
        }
        return response.data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // === НОВЫЙ МЕТОД: Изменение статуса заявки ===
  Future<String?> updateRequestStatus(String id, String newStatus) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return 'Необходима авторизация';

      // Отправляем PATCH запрос на обновление статуса
      final response = await _dio.patch(
        '/requests/$id',
        data: {'status': newStatus},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // Успешно
      }
      return 'Неожиданный ответ сервера: ${response.statusCode}';
    } on DioException catch (e) {
      debugPrint('Ошибка смены статуса: ${e.response?.data}');
      return 'Ошибка сервера: ${e.response?.statusCode}';
    } catch (e) {
      return 'Внутренняя ошибка: $e';
    }
  }

// === ОБНОВЛЕННЫЙ МЕТОД: Отмена заявки (как в Swagger) ===
  Future<String?> cancelRequest(String id, String reasonSlug) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return 'Необходима авторизация';

      debugPrint('=== ОТПРАВЛЯЕМ ЗАПРОС НА ОТМЕНУ ===');
      debugPrint('ID заявки: $id');
      debugPrint('Reason: $reasonSlug');

      final response = await _dio.post(
        '/requests/$id/cancel',
        data: {
          'reason': reasonSlug, // Отправляем английский ключ
          'comment': 'Отменено через мобильное приложение' // Отправляем обязательный коммент
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return null; // Успех
      }
      return 'Неожиданный ответ: ${response.statusCode}';

    } on DioException catch (e) {
      String errorMessage = 'Ошибка сервера: ${e.response?.statusCode ?? "Неизвестно"}';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['error'] ?? errorMessage;
      }
      return errorMessage;
    } catch (e) {
      return 'Внутренняя ошибка: $e';
    }
  }
}