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

// === ОБНОВЛЕННЫЙ МЕТОД: Загрузка всех заявок (сборка из двух мест для Подрядчика) ===
  Future<List<dynamic>> getRequests() async {
    try {
      final token = await SecureStorage.getToken();
      final role = await SecureStorage.getRole(); // Узнаем роль

      if (token == null) return [];

      if (role == 'contractor') {
        debugPrint('=== ЗАГРУЖАЕМ ЗАЯВКИ ПОДРЯДЧИКА (Новые + Мои) ===');

        // 1. Делаем сразу ДВА запроса параллельно для скорости
        final results = await Future.wait([
          _dio.get('/contractor/requests', options: Options(headers: {'Authorization': 'Bearer $token'})).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 500)),
          _dio.get('/contractor/requests/my', options: Options(headers: {'Authorization': 'Bearer $token'})).catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 500)),
        ]);

        List<dynamic> allRequests = [];

        // 2. Добавляем "Новые" заявки
        if (results[0].statusCode == 200) {
          final data = results[0].data['data'] ?? results[0].data;
          if (data is List) allRequests.addAll(data);
        }

        // 3. Добавляем "Мои" заявки (в работе и исполненные)
        if (results[1].statusCode == 200) {
          final data = results[1].data['data'] ?? results[1].data;
          if (data is List) allRequests.addAll(data);
        }

        return allRequests;

      } else {
        // === ЛОГИКА ДЛЯ МОНИТОРА (без изменений) ===
        debugPrint('=== ЗАГРУЖАЕМ ЗАЯВКИ МОНИТОРА ===');
        final response = await _dio.get(
          '/requests',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200) {
          final data = response.data['data'] ?? response.data;
          if (data is List) return data;
        }
        return [];
      }
    } catch (e) {
      debugPrint('Ошибка загрузки заявок: $e');
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

// === ОБНОВЛЕННЫЙ МЕТОД: Изменение статуса заявки ===
  Future<String?> updateRequestStatus(String id, String newStatus) async {
    try {
      final token = await SecureStorage.getToken();
      final role = await SecureStorage.getRole(); // Проверяем роль
      if (token == null) return 'Необходима авторизация';

      // === ИСПОЛЬЗУЕМ НОВЫЙ АДРЕС /take ДЛЯ ПОДРЯДЧИКА ===
      final String endpoint = (role == 'contractor')
          ? '/contractor/requests/$id/take'  // <--- ВОТ ОНО!
          : '/requests/$id';

      debugPrint('=== МЕНЯЕМ СТАТУС ЗАЯВКИ ===');
      debugPrint('Эндпоинт: $endpoint');

      // Для роутов вроде /take и /cancel почти всегда используется POST
      final response = await _dio.post(
        endpoint,
        data: {
          'status': newStatus,
          'comment': 'Взято в работу через мобильное приложение'
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return null; // Успешно
      }
      return 'Неожиданный ответ сервера: ${response.statusCode}';

    } on DioException catch (e) {
      debugPrint('Ошибка смены статуса: ${e.response?.statusCode} - ${e.response?.data}');
      String errorMessage = 'Ошибка сервера: ${e.response?.statusCode}';

      if (e.response?.data != null && e.response?.data is Map && e.response?.data['error'] != null) {
        errorMessage = e.response?.data['error'];
      }
      return errorMessage;
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

  // === НОВЫЙ МЕТОД: Получить детали одной заявки ===
  Future<Map<String, dynamic>?> getRequestById(String id) async {
    try {
      final token = await SecureStorage.getToken();
      final role = await SecureStorage.getRole();

      final String endpoint = (role == 'contractor')
          ? '/contractor/requests/$id'
          : '/requests/$id';

      final response = await _dio.get(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки деталей заявки: $e');
      return null;
    }
  }

// === ОБНОВЛЕННЫЙ МЕТОД: Завершение заявки (теперь с днями!) ===
  Future<String?> completeRequest(String id, String comment, int rating, int daysSpent, File photo) async { // <--- Добавили int daysSpent
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return 'Необходима авторизация';

      String fileName = photo.path.split('/').last;

      FormData formData = FormData.fromMap({
        'comment': comment,
        'rating': rating,
        'days_spent': daysSpent,
        'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
      });

      final response = await _dio.post(
        '/contractor/requests/$id/complete',
        data: formData,
        options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'multipart/form-data',
            }
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return null;
      }
      return 'Неожиданный ответ сервера: ${response.statusCode}';
    } on DioException catch (e) {
      String errorMessage = 'Ошибка сервера: ${e.response?.statusCode}';
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['error'] != null) {
        errorMessage = e.response?.data['error'];
      }
      return errorMessage;
    } catch (e) {
      return 'Внутренняя ошибка: $e';
    }
  }
}