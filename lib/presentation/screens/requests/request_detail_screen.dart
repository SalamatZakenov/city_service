import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/request_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestNumber;

  const RequestDetailScreen({super.key, required this.requestNumber});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final RequestService _requestService = RequestService();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  Map<String, dynamic>? _requestData;
  List<dynamic> _categories = [];

  // Координаты для карты (по умолчанию центр Алматы)
  LatLng _locationCoords = const LatLng(43.238949, 76.889709);
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  // === СКАЧИВАЕМ ДАННЫЕ ЗАЯВКИ ===
  Future<void> _fetchRequestDetails() async {
    try {
      _categories = await _requestService.getCategories();
      final allRequests = await _requestService.getRequests();

      final request = allRequests.firstWhere(
            (req) => req['id'].toString() == widget.requestNumber,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _requestData = request;
          _isLoading = false;
        });

        // Если нашли заявку, пробуем получить её координаты по адресу
        if (request != null && request['location'] != null) {
          _getCoordsFromAddress(request['location']);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // === ПЕРЕВОДИМ ТЕКСТ АДРЕСА В КООРДИНАТЫ ДЛЯ КАРТЫ ===
  Future<void> _getCoordsFromAddress(String address) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': 1,
        },
        options: Options(headers: {'User-Agent': 'kz.cityservice.app'}),
      );

      if (response.data != null && response.data.isNotEmpty) {
        final lat = double.parse(response.data[0]['lat']);
        final lon = double.parse(response.data[0]['lon']);
        if (mounted) {
          setState(() {
            _locationCoords = LatLng(lat, lon);
            _isMapLoading = false;
          });
          // Двигаем карту на новую точку
          _mapController.move(_locationCoords, 16.0);
        }
      } else {
        if (mounted) setState(() => _isMapLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // Вспомогательные методы форматирования
  String _getCategoryName(dynamic categoryId) {
    if (categoryId == null) return 'Без категории';
    try {
      final cat = _categories.firstWhere((c) => c['id'].toString() == categoryId.toString());
      return cat['name'];
    } catch (e) {
      return 'Без категории';
    }
  }

  String _translateStatus(String? statusEn) {
    switch (statusEn?.toLowerCase()) {
      case 'new': return 'Новая';
      case 'in_progress': return 'В работе';
      case 'done': return 'Исполнено';
      default: return 'Новая';
    }
  }

  Color _getStatusBgColor(String? statusEn) {
    switch (statusEn?.toLowerCase()) {
      case 'new': return AppColors.statusNewBg;
      case 'in_progress': return AppColors.statusInProgressBg;
      case 'done': return AppColors.statusDoneBg;
      default: return AppColors.statusNewBg;
    }
  }

  Color _getStatusTextColor(String? statusEn) {
    switch (statusEn?.toLowerCase()) {
      case 'new': return AppColors.statusNewText;
      case 'in_progress': return AppColors.statusInProgressText;
      case 'done': return AppColors.statusDoneText;
      default: return AppColors.statusNewText;
    }
  }

  String _translateUrgency(String? urgencyEn) {
    switch (urgencyEn?.toLowerCase()) {
      case 'low': return 'Низкая';
      case 'medium': return 'Средняя';
      case 'critical': return 'Критичная';
      default: return 'Средняя';
    }
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Не указано';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['янв.', 'фев.', 'мар.', 'апр.', 'мая', 'июн.', 'июл.', 'авг.', 'сен.', 'окт.', 'ноя.', 'дек.'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Неизвестно';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayId = widget.requestNumber.length > 8
        ? widget.requestNumber.substring(0, 8).toUpperCase()
        : widget.requestNumber.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkBackground, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Заявка №$displayId',
          style: const TextStyle(color: AppColors.darkBackground, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.darkBackground),
            onPressed: () {}, // Заглушка для редактирования
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
          : _requestData == null
          ? const Center(child: Text('Заявка не найдена', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Извлекаем данные
    final status = _requestData!['status'];
    final title = _requestData!['title'] ?? 'Без названия';
    final description = _requestData!['description'] ?? 'Описание отсутствует';
    final categoryId = _requestData!['category_id'];
    final categoryName = _getCategoryName(categoryId);
    final location = _requestData!['location'] ?? 'Адрес не указан';
    final urgency = _translateUrgency(_requestData!['urgency']);
    final createdAt = _formatDateString(_requestData!['created_at'] ?? _requestData!['createdAt']);
    final deadline = _formatDateString(_requestData!['deadline']);

    // URL фото
    final String baseUrl = 'https://city-service-production.up.railway.app';
    String rawPhotoUrl = _requestData!['photo_url'] ?? _requestData!['photo'] ?? '';
    if (rawPhotoUrl.isNotEmpty && !rawPhotoUrl.startsWith('/')) rawPhotoUrl = '/$rawPhotoUrl';
    final String fullImageUrl = rawPhotoUrl.isNotEmpty ? '$baseUrl$rawPhotoUrl' : '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === КАРТА С ЛОКАЦИЕЙ ===
          SizedBox(
            height: 220,
            width: double.infinity,
            child: _isMapLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
                : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _locationCoords,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Делаем карту статичной, чтобы не мешала скроллу
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'kz.cityservice.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _locationCoords,
                      width: 60, height: 60,
                      child: const Icon(Icons.location_on, size: 50, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Статус
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _getStatusBgColor(status), borderRadius: BorderRadius.circular(20)),
                  child: Text(_translateStatus(status), style: TextStyle(color: _getStatusTextColor(status), fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),

                // Название проблемы (Title)
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 24),

                // Описание
                const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4)),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                const SizedBox(height: 16),

                // Детали заявки
                const Text('Детали заявки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 16),
                _buildDetailRow('От', 'Монитор Байболды А.'), // Статика
                _buildDetailRow('Кому', 'ИП CleanUralskCar'), // Статика
                _buildDetailRow('Категория', categoryName),
                _buildDetailRow('Взято на работу', 'Нет'), // Статика
                _buildDetailRow('Дата принятия', createdAt),
                _buildDetailRow('Срок', deadline),
                _buildDetailRow('Срочность', urgency),

                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                const SizedBox(height: 16),

                // Местоположение
                const Text('Местоположение', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.location_on_outlined, color: AppColors.darkBackground, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(location, style: const TextStyle(fontSize: 15, color: AppColors.darkBackground, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                const SizedBox(height: 16),

                // Прикрепленные фото
                const Text('Фотографии', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 16),

                fullImageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 200, color: const Color(0xFFF1F5F9), child: const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))),
                    errorWidget: (context, url, error) => Container(height: 200, color: const Color(0xFFF1F5F9), child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40))),
                  ),
                )
                    : Container(
                  width: double.infinity, height: 100,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Фото не прикреплено', style: TextStyle(color: Colors.grey))),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(color: AppColors.darkBackground, fontSize: 15, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}