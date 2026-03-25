import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
      setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    // Если всё ок, берем координаты
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentCenter = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });


    _updateAddress(_currentCenter);
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
          'zoom': 18, // Максимальная детализация (до здания)
          'addressdetails': 1,
          'accept-language': 'ru', // Просим вернуть адрес на русском языке!
        },
        options: Options(
          headers: {'User-Agent': 'kz.cityservice.app'}, // Представляемся серверу
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'];

        if (address != null) {
          // Пытаемся вытащить улицу и номер дома
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

          setState(() {
            _currentAddressText = finalAddress;
          });
        }
      }
    } catch (e) {
      setState(() {
        _currentAddressText = 'Ошибка сети';
      });
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
        actions: [
          // Кнопка возврата к моей локации
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primaryMint),
            onPressed: () => _determinePosition(),
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
          : Stack(
        children: [
          // САМА КАРТА
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
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
                // Когда отпустили палец, переводим координаты в адрес
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

          // МАРКЕР ПО ЦЕНТРУ ЭКРАНА (как в Яндекс Такси)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // Приподнимаем, чтобы острие было ровно в центре
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
                          // Возвращаем выбранный адрес на прошлый экран!
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
}