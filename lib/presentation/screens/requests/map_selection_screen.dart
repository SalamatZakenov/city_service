import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import 'package:dio/dio.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();

  // Координаты Алматы по умолчанию (если GPS выключен)
  LatLng _currentCenter = const LatLng(43.238949, 76.889709);
  bool _isLoadingLocation = true;
  bool _isDragging = false;
  String _currentAddressText = 'Перемещайте карту...';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Получаем текущую геопозицию пользователя
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final newLocation = LatLng(position.latitude, position.longitude);

    if (mounted) {
      setState(() {
        _currentCenter = newLocation;
        _isLoadingLocation = false;
      });

      // === ИСПРАВЛЕНИЕ БАГА ===
      // Принудительно двигаем камеру карты на новые координаты пользователя
      _mapController.move(newLocation, 16.0);
    }

    _updateAddress(newLocation);
  }

  // === НОВЫЕ МЕТОДЫ: Приближение и Отдаление ===
  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': position.latitude,
          'lon': position.longitude,
          'zoom': 18,
          'addressdetails': 1,
          'accept-language': 'ru',
        },
        options: Options(
          headers: {'User-Agent': 'kz.cityservice.app'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'];

        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['path'] ?? '';
          final houseNumber = address['house_number'] ?? '';
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';

          String finalAddress = '';

          if (road.isNotEmpty && houseNumber.isNotEmpty) {
            finalAddress = '$road, $houseNumber';
          } else if (road.isNotEmpty) {
            finalAddress = road;
          } else if (suburb.isNotEmpty) {
            finalAddress = 'мкр. $suburb';
          } else {
            finalAddress = data['display_name'] ?? 'Неизвестный адрес';
          }

          if (mounted) {
            setState(() {
              _currentAddressText = finalAddress;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddressText = 'Ошибка сети';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBackground),
        title: const Text('Укажите место', style: TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _isDragging = true;
                    _currentCenter = position.center ?? _currentCenter;
                    _currentAddressText = 'Поиск...';
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  setState(() => _isDragging = false);
                  _updateAddress(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'kz.cityservice.app',
              ),
            ],
          ),

          // МАРКЕР ПО ЦЕНТРУ ЭКРАНА
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _isDragging ? -15 : 0, 0),
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),

          // === КНОПКИ УПРАВЛЕНИЯ КАРТОЙ (+, -, Геолокация) ===
          Positioned(
            right: 16,
            bottom: 220, // Поднимаем над нижней плашкой
            child: Column(
              children: [
                _buildMapControl(Icons.add, _zoomIn),
                const SizedBox(height: 8),
                _buildMapControl(Icons.remove, _zoomOut),
                const SizedBox(height: 16),
                _buildMapControl(Icons.my_location, _determinePosition, iconColor: AppColors.primaryMint),
              ],
            ),
          ),

          // ПЛАШКА С АДРЕСОМ СНИЗУ И КНОПКА "ВЫБРАТЬ"
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Выбранный адрес:', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      _currentAddressText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isDragging || _currentAddressText == 'Поиск...'
                            ? null
                            : () {
                          Navigator.pop(context, _currentAddressText);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMint,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Подтвердить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для красивых круглых кнопок управления
  Widget _buildMapControl(IconData icon, VoidCallback onTap, {Color iconColor = AppColors.darkBackground}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }
}