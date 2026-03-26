import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/request_service.dart';
import '../../widgets/global_header.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestNumber;

  const RequestDetailScreen({super.key, required this.requestNumber});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final RequestService _requestService = RequestService();

  bool _isLoading = true;
  Map<String, dynamic>? _requestData;
  List<dynamic> _categories = [];

  LatLng _locationCoords = const LatLng(43.238949, 76.889709);
  bool _isMapLoading = true;

  // === СТАТИЧНЫЙ СПИСОК ПРИЧИН ОТМЕНЫ ===
  final List<String> _cancellationReasons = [
    'Ошибочная заявка',
    'Заявка не актуальна',
    'Неправильные данные',
    'Другая причина'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

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

        if (request != null && request['location'] != null) {
          _getCoordsFromAddress(request['location']);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCoordsFromAddress(String address) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': address, 'format': 'json', 'limit': 1},
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
        }
      } else {
        if (mounted) setState(() => _isMapLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // === ПЕРВЫЙ BOTTOM SHEET: "ПРИЧИНА ОТМЕНЫ" ===
  void _showCancellationInitialSheet() {
    String? localSelectedReason;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isReasonSelected = localSelectedReason != null;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Причина отмены', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final result = await _showReasonSelectionSheet(currentSelection: localSelectedReason);

                        if (result != null) {
                          setModalState(() {
                            localSelectedReason = result;
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isReasonSelected ? const Color(0xFFF1F5F9) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                isReasonSelected ? Icons.assignment_outlined : Icons.document_scanner_outlined,
                                color: isReasonSelected ? AppColors.darkBackground : Colors.grey.shade600,
                                size: 22
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localSelectedReason ?? 'Выберите причину',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: isReasonSelected ? AppColors.darkBackground : Colors.grey.shade600,
                                    fontWeight: isReasonSelected ? FontWeight.w600 : FontWeight.w500
                                ),
                              ),
                            ),
                            // Стрелочка
                            Icon(Icons.keyboard_arrow_right, color: Colors.grey.shade500, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // === КНОПКИ ВНИЗУ ===
                    Row(
                      children: [
                        // Кнопка Назад
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Назад', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isReasonSelected) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заявка отменена: $localSelectedReason')));
                                Navigator.pop(context);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isReasonSelected ? Colors.redAccent : const Color(0xFFE2E8F0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Отменить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
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

  // === ВТОРОЙ BOTTOM SHEET: "ВЫБОР ПРИЧИНЫ" ===
  Future<String?> _showReasonSelectionSheet({required String? currentSelection}) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String? tempSelection = currentSelection;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    const Text('Причина отмены', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                    const SizedBox(height: 24),

                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _cancellationReasons.length,
                        itemBuilder: (context, index) {
                          final reason = _cancellationReasons[index];
                          final bool isSelected = tempSelection == reason;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempSelection = reason;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                children: [
                                  // Иконка
                                  const Icon(Icons.document_scanner_outlined, color: Colors.grey, size: 22),
                                  const SizedBox(width: 12),
                                  // Текст причины
                                  Expanded(
                                    child: Text(
                                        reason,
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: isSelected ? AppColors.darkBackground : Colors.grey.shade700,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500
                                        )
                                    ),
                                  ),
                                  // Чекбокс
                                  SizedBox(
                                    height: 20, width: 20,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setModalState(() {
                                          tempSelection = reason;
                                        });
                                      },
                                      activeColor: AppColors.primaryMint,
                                      shape: const CircleBorder(),
                                      side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // === КНОПКА ВНИЗУ ===
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: tempSelection == null
                            ? null
                            : () {
                          Navigator.pop(context, tempSelection);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMint,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Выбрать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Вспомогательные методы
  String _getCategoryName(dynamic categoryId) {
    if (categoryId == null) return 'Без категории';
    try {
      final cat = _categories.firstWhere((c) => c['id'].toString() == categoryId.toString());
      return cat['name'];
    } catch (e) {
      return 'Без категории';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlobalHeader(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
          : _requestData == null
          ? const Center(child: Text('Заявка не найдена', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final displayId = widget.requestNumber.length > 8 ? widget.requestNumber.substring(0, 8).toUpperCase() : widget.requestNumber.toUpperCase();
    final title = _requestData!['title'] ?? 'Без названия';
    final description = _requestData!['description'] ?? 'Описание отсутствует';
    final categoryName = _getCategoryName(_requestData!['category_id']);
    final location = _requestData!['location'] ?? 'Адрес не указан';
    final urgency = _translateUrgency(_requestData!['urgency']);
    final String baseUrl = 'https://city-service-production.up.railway.app';
    String rawPhotoUrl = _requestData!['photo_url'] ?? _requestData!['photo'] ?? '';
    if (rawPhotoUrl.isNotEmpty && !rawPhotoUrl.startsWith('/')) rawPhotoUrl = '/$rawPhotoUrl';
    final String fullImageUrl = rawPhotoUrl.isNotEmpty ? '$baseUrl$rawPhotoUrl' : '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkBackground, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Заявка №$displayId', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 8),
                Text(categoryName, style: const TextStyle(fontSize: 16, color: AppColors.primaryMint, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primaryMint, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(location, style: const TextStyle(fontSize: 15, color: AppColors.darkBackground, fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _isMapLoading
                        ? Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(color: AppColors.primaryMint)))
                        : FlutterMap(
                      options: MapOptions(
                        initialCenter: _locationCoords,
                        initialZoom: 16.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'kz.cityservice.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(point: _locationCoords, width: 40, height: 40, child: const Icon(Icons.location_on, size: 40, color: Colors.redAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (fullImageUrl.isNotEmpty) ...[
                  const Text('Изображение', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: fullImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 200, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))),
                      errorWidget: (context, url, error) => Container(height: 200, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40))),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text('Описание проблемы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4)),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                const SizedBox(height: 20),
                _buildDetailRow('Срочность', urgency, isHighlight: urgency == 'Критичная'),
                _buildDetailRow('Заявка от', 'Айсана Байболатова'),
                _buildDetailRow('Номер', '+7 (702) 234-56-78'),
                _buildDetailRow('Статус', 'В ожидании', isStatus: true),
                _buildDetailRow('Исполнитель', 'ИП CleanUralskCar'),
                _buildDetailRow('Ответственное лицо', 'Ерлан Қасымов'),
                _buildDetailRow('Номер', '+7 (701) 890-12-34'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Открытие WhatsApp...')));
                    },
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    label: const Text('Связаться через WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showCancellationInitialSheet,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отменить заявку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isHighlight = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(
            flex: 3,
            child: isStatus
                ? Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(value, style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            )
                : Text(
                value,
                style: TextStyle(
                    color: isHighlight ? Colors.redAccent : AppColors.darkBackground,
                    fontSize: 15,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600
                )
            ),
          ),
        ],
      ),
    );
  }
}