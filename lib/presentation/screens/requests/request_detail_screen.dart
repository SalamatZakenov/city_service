import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/request_service.dart';
import '../../../data/storage/secure_storage.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestNumber;

  const RequestDetailScreen({super.key, required this.requestNumber});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final RequestService _requestService = RequestService();

  bool _isLoading = true;
  bool _isChangingStatus = false;
  Map<String, dynamic>? _requestData;
  List<dynamic> _categories = [];
  String _userRole = 'user';

  LatLng _locationCoords = const LatLng(43.238949, 76.889709);
  bool _isMapLoading = true;

  final List<String> _cancellationReasons = [
    'Ошибочная заявка',
    'Заявка не актуальна',
    'Неправильные данные',
    'Другая причина'
  ];

  String _mapReasonToSlug(String uiReason) {
    switch (uiReason) {
      case 'Ошибочная заявка': return 'wrong_request';
      case 'Заявка не актуальна': return 'not_relevant';
      case 'Неправильные данные': return 'bad_data';
      case 'Другая причина': return 'other';
      default: return 'other';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final role = await SecureStorage.getRole();

      Map<String, dynamic>? fetchedRequestData;

      if (role == 'admin') {
        final token = await SecureStorage.getToken();
        final dio = Dio();
        try {
          final response = await dio.get(
            'https://city-service-production.up.railway.app/api/admin/requests',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final List<dynamic> allRequests = response.data['data'] ?? [];

          fetchedRequestData = allRequests.firstWhere(
                (req) => req['id'].toString() == widget.requestNumber ||
                req['request_number'].toString() == widget.requestNumber,
            orElse: () => null,
          );
        } catch (e) {
          print('Ошибка поиска заявки админа: $e');
        }
      } else {
        fetchedRequestData = await _requestService.getRequestById(widget.requestNumber);
      }

      final categories = await _requestService.getCategories();

      if (mounted) {
        setState(() {
          _userRole = role ?? 'user';
          _categories = categories;
          _requestData = fetchedRequestData;
          _isLoading = false;
        });

        if (_requestData != null && _requestData!['location'] != null) {
          _getCoordsFromAddress(_requestData!['location']);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    String cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedPhone.startsWith('8') && cleanedPhone.length == 11) {
      cleanedPhone = '7${cleanedPhone.substring(1)}';
    }

    final Uri whatsappUrl = Uri.parse('https://wa.me/$cleanedPhone');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть WhatsApp. Возможно, он не установлен.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _openMapApp(String mapType) async {
    final lat = _locationCoords.latitude;
    final lon = _locationCoords.longitude;
    String url = '';

    if (mapType == '2gis') {
      url = 'https://2gis.kz/geo/$lon,$lat';
    } else if (mapType == 'yandex') {
      url = 'https://yandex.ru/maps/?pt=$lon,$lat&z=16&l=map';
    } else if (mapType == 'google') {
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть карту')),
        );
      }
    }
  }

  void _showMapOptions() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Открыть в навигаторе', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                  const SizedBox(height: 16),
                  ListTile(
                    onTap: () { Navigator.pop(context); _openMapApp('2gis'); },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.map_outlined, color: Colors.green),
                    ),
                    title: const Text('2GIS', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () { Navigator.pop(context); _openMapApp('yandex'); },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.explore_outlined, color: Colors.red),
                    ),
                    title: const Text('Яндекс Карты', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () { Navigator.pop(context); _openMapApp('google'); },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on_outlined, color: Colors.blue),
                    ),
                    title: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Future<void> _takeIntoExecution() async {
    setState(() => _isChangingStatus = true);

    final error = await _requestService.updateRequestStatus(widget.requestNumber, 'in_progress');

    if (mounted) {
      setState(() => _isChangingStatus = false);

      if (error == null) {
        setState(() {
          _requestData!['status'] = 'in_progress';
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Заявка взята в работу!'), backgroundColor: AppColors.primaryMint)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.redAccent)
        );
      }
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

  void _showCancellationInitialSheet() {
    String? localSelectedReason;
    bool isCancelling = false;

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
                    const Align(alignment: Alignment.centerLeft, child: Text('Причина отмены', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground))),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: isCancelling ? null : () async {
                        final result = await _showReasonSelectionSheet(currentSelection: localSelectedReason);
                        if (result != null) setModalState(() => localSelectedReason = result);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: isReasonSelected ? const Color(0xFFF1F5F9) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            Icon(isReasonSelected ? Icons.assignment_outlined : Icons.document_scanner_outlined, color: isReasonSelected ? AppColors.darkBackground : Colors.grey.shade600, size: 22),
                            const SizedBox(width: 12),
                            Expanded(child: Text(localSelectedReason ?? 'Выберите причину', style: TextStyle(fontSize: 15, color: isReasonSelected ? AppColors.darkBackground : Colors.grey.shade600, fontWeight: isReasonSelected ? FontWeight.w600 : FontWeight.w500))),
                            Icon(Icons.keyboard_arrow_right, color: Colors.grey.shade500, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: isCancelling ? null : () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Назад', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)))),
                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isReasonSelected && !isCancelling)
                                ? () async {
                              setModalState(() => isCancelling = true);

                              final reasonSlug = _mapReasonToSlug(localSelectedReason!);
                              final error = await _requestService.cancelRequest(widget.requestNumber, reasonSlug);

                              if (mounted) {
                                setModalState(() => isCancelling = false);

                                if (error == null) {
                                  setState(() {
                                    _requestData!['status'] = 'cancelled';
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ Заявка успешно отменена'), backgroundColor: AppColors.primaryMint)
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error), backgroundColor: Colors.redAccent)
                                  );
                                }
                              }
                            }
                                : (isCancelling ? () {} : () => Navigator.pop(context)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isReasonSelected ? Colors.redAccent : const Color(0xFFE2E8F0),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0
                            ),
                            child: isCancelling
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Отменить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  void _showCompletionSheet() {
    int localRating = 5;
    File? localPhoto;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    final String reqNum = _requestData?['request_number']?.toString() ?? widget.requestNumber.substring(0, 8).toUpperCase();

    final String dateString = _requestData!['taken_at'] ?? _requestData!['created_at'];
    final DateTime startDate = DateTime.parse(dateString);
    int daysInWork = DateTime.now().difference(startDate).inDays;
    if (daysInWork <= 0) daysInWork = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24.0, right: 24.0, top: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Завершение заявки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Номер заявки', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('№$reqNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ]),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            const Text('В работе', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('$daysInWork дн.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMint)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Оценка работы Монитора', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => IconButton(
                        icon: Icon(index < localRating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 40),
                        onPressed: () => setModalState(() => localRating = index + 1),
                      )),
                    ),
                    const SizedBox(height: 16),
                    const Text('Фотография результата', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) setModalState(() => localPhoto = File(image.path));
                      },
                      child: Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12),
                          image: localPhoto != null ? DecorationImage(image: FileImage(localPhoto!), fit: BoxFit.cover) : null,
                        ),
                        child: localPhoto == null ? const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 32) : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(hintText: 'Комментарий...', filled: true, fillColor: Color(0xFFF1F5F9), border: InputBorder.none),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (localPhoto == null || isSubmitting) ? null : () async {
                          setModalState(() => isSubmitting = true);

                          final error = await _requestService.completeRequest(
                              widget.requestNumber,
                              commentController.text.isEmpty ? 'Выполнено' : commentController.text,
                              localRating,
                              daysInWork,
                              localPhoto!
                          );

                          if (mounted) {
                            setModalState(() => isSubmitting = false);
                            if (error == null) {
                              setState(() => _requestData!['status'] = 'done');
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Успешно завершено!')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Завершить заявку'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showReasonSelectionSheet({required String? currentSelection}) async {
    return await showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String? tempSelection = currentSelection;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Причина отмены', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                    const SizedBox(height: 24),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true, physics: const BouncingScrollPhysics(), itemCount: _cancellationReasons.length,
                        itemBuilder: (context, index) {
                          final reason = _cancellationReasons[index];
                          final bool isSelected = tempSelection == reason;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempSelection = reason),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.document_scanner_outlined, color: Colors.grey, size: 22), const SizedBox(width: 12),
                                  Expanded(child: Text(reason, style: TextStyle(fontSize: 15, color: isSelected ? AppColors.darkBackground : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
                                  SizedBox(height: 20, width: 20, child: Checkbox(value: isSelected, onChanged: (val) => setModalState(() => tempSelection = reason), activeColor: AppColors.primaryMint, shape: const CircleBorder(), side: BorderSide(color: Colors.grey.shade400, width: 1.5))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: tempSelection == null ? null : () { Navigator.pop(context, tempSelection); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, disabledBackgroundColor: const Color(0xFFE2E8F0), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text('Выбрать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // === НОВЫЙ МЕТОД ДЛЯ ОТРИСОВКИ БОЛЬШОЙ КНОПКИ СВЯЗИ ===
  Widget _buildContactButton(String title, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            if (phone == 'Не указан' || phone == 'Не назначено' || phone.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Номер телефона пока не указан'), backgroundColor: Colors.orange),
              );
              return;
            }
            _openWhatsApp(phone);
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // Цвет WhatsApp
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
            : _requestData == null
            ? const Center(child: Text('Заявка не найдена', style: TextStyle(color: Colors.grey, fontSize: 16)))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final displayId = _requestData?['request_number']?.toString() ??
        (widget.requestNumber.length > 8 ? widget.requestNumber.substring(0, 8).toUpperCase() : widget.requestNumber.toUpperCase());

    final status = _requestData!['status'] ?? 'new';
    final title = _requestData!['title'] ?? 'Без названия';
    final description = _requestData!['description'] ?? 'Описание отсутствует';
    final categoryName = _requestData!['category']?['name'] ?? _getCategoryName(_requestData!['category_id']);
    final location = _requestData!['location'] ?? 'Адрес не указан';
    final urgency = _translateUrgency(_requestData!['urgency']);
    final String baseUrl = 'https://city-service-production.up.railway.app';
    String rawPhotoUrl = _requestData!['photo_url'] ?? _requestData!['photo'] ?? '';

    String fullImageUrl = '';
    if (rawPhotoUrl.isNotEmpty) {
      if (rawPhotoUrl.startsWith('http://') || rawPhotoUrl.startsWith('https://')) {
        fullImageUrl = rawPhotoUrl;
      } else {
        if (!rawPhotoUrl.startsWith('/')) {
          rawPhotoUrl = '/$rawPhotoUrl';
        }
        fullImageUrl = '$baseUrl$rawPhotoUrl';
      }
    }

    final monitor = _requestData!['monitor'];
    final contractor = _requestData!['contractor'];

    final monitorName = monitor?['full_name'] ?? 'Не указано';
    final monitorPhone = monitor?['phone'] ?? 'Не указан';

    final contractorName = contractor?['company_name'] ?? contractor?['full_name'] ?? 'Не назначен';
    final contractorResponsible = contractor?['responsible_person'] ?? contractor?['full_name'] ?? 'Не назначено';
    final contractorPhone = contractor?['company_phone'] ?? contractor?['phone'] ?? 'Не указан';

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
                GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkBackground, size: 20))),
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

                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180, width: double.infinity,
                        child: _isMapLoading
                            ? Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(color: AppColors.primaryMint)))
                            : FlutterMap(
                          options: MapOptions(initialCenter: _locationCoords, initialZoom: 16.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                          children: [
                            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c', 'd'], userAgentPackageName: 'kz.cityservice.app'),
                            MarkerLayer(markers: [Marker(point: _locationCoords, width: 40, height: 40, child: const Icon(Icons.location_on, size: 40, color: Colors.redAccent))]),
                          ],
                        ),
                      ),
                    ),
                    if (!_isMapLoading)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          onPressed: _showMapOptions,
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Маршрут'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.darkBackground,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                if (fullImageUrl.isNotEmpty) ...[
                  const Text('Изображение', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(imageUrl: fullImageUrl),
                        ),
                      );
                    },
                    child: Hero(
                      tag: fullImageUrl,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                            imageUrl: fullImageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(height: 200, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))),
                            errorWidget: (context, url, error) => Container(height: 200, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)))
                        ),
                      ),
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

                // Инфа осталась чистой, без иконок
                _buildDetailRow('Срочность', urgency, isHighlight: urgency == 'Критичная'),
                _buildDetailRow('Заявка от', monitorName),
                _buildDetailRow('Номер', monitorPhone),
                _buildDetailRow('Статус', _translateStatus(status), isStatus: true, statusBgColor: _getStatusBgColor(status), statusTextColor: _getStatusTextColor(status)),
                _buildDetailRow('Исполнитель', contractorName),

                if (contractor != null) ...[
                  _buildDetailRow('Ответственное лицо', contractorResponsible),
                  _buildDetailRow('Номер', contractorPhone),
                ],

                const SizedBox(height: 32),

                // === НОВЫЕ БОЛЬШИЕ КНОПКИ СВЯЗИ ===
                if (_userRole == 'admin') ...[
                  _buildContactButton('Написать Монитору', monitorPhone),
                  if (contractor != null) _buildContactButton('Написать Подрядчику', contractorPhone),
                ] else if (_userRole == 'contractor') ...[
                  _buildContactButton('Написать Монитору', monitorPhone),
                ] else ...[
                  // Это Монитор
                  if (contractor != null) _buildContactButton('Написать Подрядчику', contractorPhone),
                ],

                const SizedBox(height: 8), // Отступ перед действиями

                // === КНОПКИ ДЕЙСТВИЙ (ВЗЯТЬ/ОТМЕНИТЬ) ===
                if (_userRole == 'contractor') ...[
                  if (status == 'new')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final error = await _requestService.updateRequestStatus(widget.requestNumber, 'in_progress');
                          if (error == null) {
                            setState(() => _requestData!['status'] = 'in_progress');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка взята в работу!'), backgroundColor: AppColors.primaryMint));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('Взять на исполнение', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                  if (status == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showCompletionSheet,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('Изменить статус', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                ] else ...[
                  if (status != 'cancelled')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showCancellationInitialSheet,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.redAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Отменить заявку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ),
                    ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Обновленный виджет строки информации (убрал `trailing`)
  Widget _buildDetailRow(String title, String value, {bool isHighlight = false, bool isStatus = false, Color? statusBgColor, Color? statusTextColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500))),
          Expanded(
            flex: 3,
            child: isStatus
                ? Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor ?? Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(value, style: TextStyle(color: statusTextColor ?? Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            )
                : Text(value, style: TextStyle(color: isHighlight ? Colors.redAccent : AppColors.darkBackground, fontSize: 15, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.primaryMint),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}