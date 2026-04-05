import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/storage/secure_storage.dart';
import '../../../data/api/request_service.dart';
import '../requests/requests_screen.dart';
import '../requests/request_detail_screen.dart';
import '../../widgets/global_header.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final RequestService _requestService = RequestService();
  bool _isLoading = true;
  bool _isAnalyticsExpanded = false;

  Map<String, dynamic> _stats = {};
  List<dynamic> _allRequests = [];

  final Map<String, LatLng> _requestCoordinates = {};
  final LatLng _almatyCenter = const LatLng(43.238949, 76.889709);

  String? _selectedCategoryFilter;
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  List<dynamic> _serverCategories = [];
  bool _isLoadingCategories = true;

  final List<String> _statuses = ['Все', 'Новая', 'В работе', 'Исполнено', 'Отменена'];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      final token = await SecureStorage.getToken();
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final results = await Future.wait([
        dio.get('https://city-service-production.up.railway.app/api/admin/stats'),
        dio.get('https://city-service-production.up.railway.app/api/admin/requests'),
        _requestService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _stats = (results[0] as Response).data['data'] ?? {};
          _allRequests = (results[1] as Response).data['data'] as List<dynamic>? ?? [];
          _serverCategories = results[2] as List<dynamic>;

          _isLoading = false;
          _isLoadingCategories = false;
        });

        _geocodeLocationsForMap(_allRequests);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _geocodeLocationsForMap(List<dynamic> requests) async {
    final dio = Dio();
    for (var req in requests) {
      if (!mounted) break;

      final id = req['id']?.toString() ?? '';
      if (id.isEmpty || _requestCoordinates.containsKey(id)) continue;

      final address = req['location'];
      if (address != null && address.toString().isNotEmpty) {
        try {
          final res = await dio.get(
            'https://nominatim.openstreetmap.org/search',
            queryParameters: {'q': address, 'format': 'json', 'limit': 1},
            options: Options(headers: {'User-Agent': 'kz.cityservice.app.admin'}),
          );

          if (res.data != null && res.data.isNotEmpty) {
            final lat = double.parse(res.data[0]['lat']);
            final lon = double.parse(res.data[0]['lon']);

            if (mounted) {
              setState(() {
                _requestCoordinates[id] = LatLng(lat, lon);
              });
            }
          }
        } catch (e) {
          // Игнорируем ошибки конкретного адреса
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  // === ОБНОВЛЕННЫЕ ЦВЕТА МАРКЕРОВ ===
  Color _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return Colors.blue;          // Новый - Синий
      case 'in_progress': return Colors.amber; // В работе - Желтый
      case 'done': return Colors.green;        // Исполнено - Зеленый
      case 'cancelled': return Colors.red;     // Отменено - Красный
      default: return Colors.grey;
    }
  }

  // === ЛОГИКА ФИЛЬТРОВ ===
  Future<void> _pickDateFilter() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryMint, onPrimary: Colors.white, onSurface: AppColors.darkBackground),
          ),
          child: child!,
        );
      },
    );
    setState(() => _selectedDateFilter = picked);
  }

  void _showSelectionSheet({required String title, required List<String> options, required String? currentValue, required ValueChanged<String?> onSelected}) {
    String? tempSelection = currentValue ?? 'Все';
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true, itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = tempSelection == option;
                          return ListTile(
                            onTap: () => setModalState(() => tempSelection = option),
                            leading: Checkbox(value: isSelected, onChanged: (val) => setModalState(() => tempSelection = option), activeColor: AppColors.primaryMint),
                            title: Text(option, style: TextStyle(color: isSelected ? AppColors.primaryMint : Colors.grey[600])),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint),
                        onPressed: () {
                          onSelected(tempSelection == 'Все' ? null : tempSelection);
                          Navigator.pop(context);
                        },
                        child: const Text('Применить', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryMint)),
      );
    }

    final byStatus = _stats['by_status'] ?? {};
    final total = _stats['total'] ?? 0;
    final newCount = byStatus['new'] ?? 0;
    final inProgressCount = byStatus['in_progress'] ?? 0;
    final doneCount = byStatus['done'] ?? 0;
    final cancelledCount = byStatus['cancelled'] ?? 0;

    List<dynamic> filteredRequests = List.from(_allRequests);

    if (_selectedStatusFilter != null) {
      String statusEn = '';
      switch (_selectedStatusFilter) {
        case 'Новая': statusEn = 'new'; break;
        case 'В работе': statusEn = 'in_progress'; break;
        case 'Исполнено': statusEn = 'done'; break;
        case 'Отменена': statusEn = 'cancelled'; break;
      }
      if (statusEn.isNotEmpty) {
        filteredRequests = filteredRequests.where((r) => r['status'] == statusEn).toList();
      }
    }

    if (_selectedCategoryFilter != null) {
      final selectedCatObj = _serverCategories.firstWhere((c) => c['name'] == _selectedCategoryFilter, orElse: () => null);
      if (selectedCatObj != null) {
        filteredRequests = filteredRequests.where((r) {
          final catId = r['category']?['id'] ?? r['category_id'];
          return catId.toString() == selectedCatObj['id'].toString();
        }).toList();
      }
    }

    if (_selectedDateFilter != null) {
      filteredRequests = filteredRequests.where((r) {
        final createdAtString = r['created_at'] ?? r['createdAt'];
        if (createdAtString == null) return false;
        final date = DateTime.parse(createdAtString.toString());
        return date.year == _selectedDateFilter!.year && date.month == _selectedDateFilter!.month && date.day == _selectedDateFilter!.day;
      }).toList();
    }

    // === ФОРМИРУЕМ МАРКЕРЫ ДЛЯ МИНИ-КАРТЫ ===
    final List<Marker> miniMapMarkers = filteredRequests
        .where((req) => _requestCoordinates.containsKey(req['id'].toString()))
        .map((req) {
      final latlng = _requestCoordinates[req['id'].toString()]!;
      final status = req['status'] ?? 'new';
      return Marker(
        point: latlng,
        width: 30,
        height: 30,
        child: Icon(Icons.location_on, color: _getMarkerColor(status), size: 30),
      );
    }).toList();

    List<String> dynamicCategoryNames = ['Все'];
    if (!_isLoadingCategories) {
      dynamicCategoryNames.addAll(_serverCategories.map((c) => c['name'].toString()));
    }

    String centerDateText = (_selectedDateFilter == null) ? 'Все' : 'Сегодня';
    if (_selectedDateFilter != null) {
      centerDateText = "${_selectedDateFilter!.day.toString().padLeft(2, '0')}.${_selectedDateFilter!.month.toString().padLeft(2, '0')}.${_selectedDateFilter!.year}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const GlobalHeader(),
      body: RefreshIndicator(
        onRefresh: _fetchAdminData,
        color: AppColors.primaryMint,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Панель администратора', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
              ),
              const SizedBox(height: 16),

              // === АНАЛИТИКА ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => setState(() => _isAnalyticsExpanded = !_isAnalyticsExpanded),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryMint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.analytics_outlined, color: AppColors.primaryMint, size: 22)),
                              const SizedBox(width: 12),
                              const Text('Статистика и аналитика', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                            ],
                          ),
                          Icon(_isAnalyticsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: !_isAnalyticsExpanded
                    ? const SizedBox.shrink()
                    : Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            _buildTopStatCard('Всего заявок', total.toString(), Colors.blueAccent),
                            const SizedBox(height: 12),
                            Row(children: [_buildSmallStatCard('Новые', newCount.toString(), Colors.amber), const SizedBox(width: 12), _buildSmallStatCard('В работе', inProgressCount.toString(), Colors.green)]),
                            const SizedBox(height: 12),
                            Row(children: [_buildSmallStatCard('Исполнено', doneCount.toString(), AppColors.primaryMint), const SizedBox(width: 12), _buildSmallStatCard('Отменено', cancelledCount.toString(), Colors.redAccent)]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 20.0), child: Text('Аналитика по категориям', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground))),
                      const SizedBox(height: 12),
                      Container(margin: const EdgeInsets.symmetric(horizontal: 20.0), padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: _buildCategoryAnalytics()),
                      const SizedBox(height: 24),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 20.0), child: Text('Аналитика по срочности', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground))),
                      const SizedBox(height: 12),
                      Container(margin: const EdgeInsets.symmetric(horizontal: 20.0), padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: _buildUrgencyAnalytics()),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === МИНИ-КАРТА (НЕПОДВИЖНАЯ) ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Карта заявок', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                    Text('${miniMapMarkers.length} на карте', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminFullScreenMap(
                        requests: filteredRequests,
                        coordinates: _requestCoordinates,
                      ),
                    ),
                  ).then((_) => _fetchAdminData());
                },
                child: Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AbsorbPointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _almatyCenter,
                          initialZoom: 11.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c', 'd']),
                          MarkerLayer(markers: miniMapMarkers),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // === ФИЛЬТРЫ ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(child: _buildFilterChip(_selectedDateFilter == null ? 'Дата' : "${_selectedDateFilter!.day}.${_selectedDateFilter!.month}", _pickDateFilter, isActive: _selectedDateFilter != null)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip(_isLoadingCategories ? 'Загрузка...' : (_selectedCategoryFilter ?? 'Категория'), () {
                      if (!_isLoadingCategories) _showSelectionSheet(title: 'Фильтр по категории', options: dynamicCategoryNames, currentValue: _selectedCategoryFilter, onSelected: (val) => setState(() => _selectedCategoryFilter = val));
                    }, isActive: _selectedCategoryFilter != null)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip(_selectedStatusFilter ?? 'Статус', () => _showSelectionSheet(title: 'Фильтр по статусу', options: _statuses, currentValue: _selectedStatusFilter, onSelected: (val) => setState(() => _selectedStatusFilter = val)), isActive: _selectedStatusFilter != null)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(centerDateText, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),

              // === ОТФИЛЬТРОВАННЫЙ СПИСОК ЗАЯВОК ===
              if (filteredRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('Нет заявок, подходящих под фильтры', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final req = filteredRequests[index];
                    final status = req['status'] ?? 'new';
                    final categoryName = req['category']?['name'] ?? 'Без категории';
                    final idString = req['id']?.toString() ?? '???';
                    final shortId = req['request_number']?.toString() ?? (idString.length > 8 ? idString.substring(0, 8).toUpperCase() : idString.toUpperCase());

                    return ExpandableRequestCard(
                      rawId: idString,
                      number: shortId,
                      statusText: _translateStatus(status),
                      statusBgColor: _getStatusBgColor(status),
                      statusTextColor: _getStatusTextColor(status),
                      category: categoryName,
                      address: req['location'] ?? 'Адрес не указан',
                      urgency: _translateUrgency(req['urgency']),
                      createdAtDate: _formatDateString(req['created_at']),
                      deadlineDate: _formatDateString(req['deadline']),
                      imageUrlPath: req['photo_url'] ?? req['photo'],
                      onReturnFromDetail: () => _fetchAdminData(),
                    );
                  },
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- МЕТОДЫ ОТРИСОВКИ ---
  Widget _buildFilterChip(String label, VoidCallback onTap, {bool isActive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: isActive ? AppColors.primaryMint : Colors.grey.shade600, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500))),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAnalytics() {
    final categories = _stats['by_category'] as List<dynamic>? ?? [];
    if (categories.isEmpty) return const Text('Нет данных', style: TextStyle(color: Colors.grey));

    int totalInCategories = 0;
    for (var cat in categories) {
      totalInCategories += (cat['count'] as int? ?? 0);
    }

    return Column(
      children: categories.map((cat) {
        final name = cat['category'] ?? 'Неизвестно';
        final count = cat['count'] as int? ?? 0;
        final percent = totalInCategories > 0 ? count / totalInCategories : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                  Text('$count шт.', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMint)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: percent, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMint)),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencyAnalytics() {
    final byUrgency = _stats['by_urgency'] ?? {};
    final critical = byUrgency['critical'] ?? 0;
    final medium = byUrgency['medium'] ?? 0;
    final low = byUrgency['low'] ?? 0;
    final totalUrgency = critical + medium + low;

    return Column(
      children: [
        _buildProgressBar('Критичная', critical, totalUrgency, Colors.redAccent),
        const SizedBox(height: 16),
        _buildProgressBar('Средняя', medium, totalUrgency, Colors.orangeAccent),
        const SizedBox(height: 16),
        _buildProgressBar('Низкая', low, totalUrgency, Colors.blueAccent),
      ],
    );
  }

  Widget _buildProgressBar(String title, int count, int total, Color color) {
    final percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            Text('$count шт.', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: percent, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(color)),
        )
      ],
    );
  }

  Widget _buildTopStatCard(String title, String count, Color color) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(count, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600))]));
  }

  Widget _buildSmallStatCard(String title, String count, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600))])));
  }

  String _translateStatus(String? statusEn) {
    switch (statusEn?.toLowerCase()) {
      case 'new': return 'Новая';
      case 'in_progress': return 'В работе';
      case 'done': return 'Исполнено';
      case 'cancelled': return 'Отменена';
      default: return 'Новая';
    }
  }

  Color _getStatusBgColor(String? statusEn) {
    switch (statusEn?.toLowerCase()) {
      case 'new': return AppColors.statusNewBg;
      case 'in_progress': return AppColors.statusInProgressBg;
      case 'done': return AppColors.statusDoneBg;
      case 'cancelled': return Colors.red.shade100;
      default: return AppColors.statusNewBg;
    }
  }

  Color _getStatusTextColor(String? statusEn) {
    switch (statusEn?.toLowerCase()) {
      case 'new': return AppColors.statusNewText;
      case 'in_progress': return AppColors.statusInProgressText;
      case 'done': return AppColors.statusDoneText;
      case 'cancelled': return Colors.red.shade800;
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
}

// =======================================================================
// === ЭКРАН ПОЛНОЭКРАННОЙ ИНТЕРАКТИВНОЙ КАРТЫ ДЛЯ АДМИНИСТРАТОРА ===
// =======================================================================

class AdminFullScreenMap extends StatefulWidget {
  final List<dynamic> requests;
  final Map<String, LatLng> coordinates;

  const AdminFullScreenMap({
    super.key,
    required this.requests,
    required this.coordinates,
  });

  @override
  State<AdminFullScreenMap> createState() => _AdminFullScreenMapState();
}

class _AdminFullScreenMapState extends State<AdminFullScreenMap> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_userLocation!, 13.0);
    }
  }

  // === ОБНОВЛЕННЫЕ ЦВЕТА МАРКЕРОВ НА БОЛЬШОЙ КАРТЕ ===
  Color _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return Colors.blue;          // Новый - Синий
      case 'in_progress': return Colors.amber; // В работе - Желтый
      case 'done': return Colors.green;        // Исполнено - Зеленый
      case 'cancelled': return Colors.red;     // Отменено - Красный
      default: return Colors.grey;
    }
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> fullMapMarkers = widget.requests
        .where((req) => widget.coordinates.containsKey(req['id'].toString()))
        .map((req) {
      final latlng = widget.coordinates[req['id'].toString()]!;
      final status = req['status'] ?? 'new';

      return Marker(
        point: latlng,
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestDetailScreen(requestNumber: req['id'].toString()),
              ),
            );
          },
          child: Icon(Icons.location_on, color: _getMarkerColor(status), size: 45),
        ),
      );
    }).toList();

    // === ИКОНКА ГЕОЛОКАЦИИ ПОЛЬЗОВАТЕЛЯ (Сплошной синий круг) ===
    if (_userLocation != null) {
      fullMapMarkers.add(
        Marker(
          point: _userLocation!,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue, // Сплошной синий
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3), // Белая обводка для контраста
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBackground),
        title: const Text('Карта заявок', style: TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(43.238949, 76.889709),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(markers: fullMapMarkers),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 40,
            child: Column(
              children: [
                _buildMapControl(Icons.add, _zoomIn),
                const SizedBox(height: 8),
                _buildMapControl(Icons.remove, _zoomOut),
                const SizedBox(height: 16),
                _buildMapControl(Icons.my_location, _getUserLocation, iconColor: Colors.blue),
              ],
            ),
          ),

          // === ОБНОВЛЕННАЯ ЛЕГЕНДА ЦВЕТОВ ===
          Positioned(
            left: 16,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.blue, 'Новые'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.amber, 'В работе'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.green, 'Исполнено'),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.red, 'Отменено'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 20),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap, {Color iconColor = AppColors.darkBackground}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }
}