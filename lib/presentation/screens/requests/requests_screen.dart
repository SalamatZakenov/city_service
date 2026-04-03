import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';
import '../../../data/api/request_service.dart';
import '../../../data/storage/secure_storage.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final RequestService _requestService = RequestService();
  Future<List<dynamic>>? _requestsFuture;

  String? _selectedCategoryFilter;
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  String _userRole = '';

  List<dynamic> _serverCategories = [];
  bool _isLoadingCategories = true;

  final List<String> _statuses = ['Все', 'Новая', 'В работе', 'Исполнено'];

  @override
  void initState() {
    super.initState();
    _requestsFuture = _requestService.getRequests();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final role = await SecureStorage.getRole();
    setState(() {
      _userRole = role ?? '';
      _requestsFuture = _requestService.getRequests();
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _requestService.getCategories();
    if (mounted) {
      setState(() {
        _serverCategories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickDateFilter() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryMint,
              onPrimary: Colors.white,
              onSurface: AppColors.darkBackground,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryMint,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateFilter = picked);
    } else {
      setState(() => _selectedDateFilter = null);
    }
  }

  void _showSelectionSheet({
    required String title,
    required List<String> options,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) {
    String? tempSelection = currentValue ?? 'Все';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = tempSelection == option;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempSelection = option),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 24, width: 24,
                                    child: Checkbox(value: isSelected, onChanged: (val) => setModalState(() => tempSelection = option), activeColor: AppColors.primaryMint),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(option, style: TextStyle(fontSize: 15, color: isSelected ? AppColors.primaryMint : Colors.grey[600], fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), foregroundColor: AppColors.textGrey, elevation: 0), onPressed: () => Navigator.pop(context), child: const Text('Отмена'))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, foregroundColor: Colors.white, elevation: 0), onPressed: () {
                          onSelected(tempSelection == 'Все' ? null : tempSelection);
                          Navigator.pop(context);
                        }, child: const Text('Применить'))),
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

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return AppColors.statusNewBg;
      case 'in_progress': return AppColors.statusInProgressBg;
      case 'done': return AppColors.statusDoneBg;
      case 'cancelled': return Colors.red.shade100;
      default: return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return AppColors.statusNewText;
      case 'in_progress': return AppColors.statusInProgressText;
      case 'done': return AppColors.statusDoneText;
      case 'cancelled': return Colors.red.shade800;
      default: return Colors.grey.shade700;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new': return 'новая';
      case 'in_progress': return 'в работе';
      case 'done': return 'исполнено';
      case 'cancelled': return 'Отменена';
      default: return status;
    }
  }

  String _translateUrgency(String urgencyEn) {
    switch (urgencyEn.toLowerCase()) {
      case 'low': return 'Низкая';
      case 'medium': return 'Средняя';
      case 'critical': return 'Критичная';
      default: return 'Средняя';
    }
  }

  String _getCategoryNameById(dynamic id) {
    if (id == null) return 'Без категории';
    try {
      final cat = _serverCategories.firstWhere((c) => c['id'].toString() == id.toString());
      return cat['name'];
    } catch (e) {
      return 'Без категории';
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
    // === ИЗМЕНЕНО: По умолчанию пишем "Все" вместо "Сегодня" ===
    String centerDateText = 'Все';
    if (_selectedDateFilter != null) {
      final now = DateTime.now();
      if (_selectedDateFilter!.year == now.year && _selectedDateFilter!.month == now.month && _selectedDateFilter!.day == now.day) {
        centerDateText = 'Сегодня'; // Если юзер вручную выбрал сегодняшний день
      } else {
        centerDateText = "${_selectedDateFilter!.day.toString().padLeft(2, '0')}.${_selectedDateFilter!.month.toString().padLeft(2, '0')}.${_selectedDateFilter!.year}";
      }
    }

    String dateFilterLabel = 'Дата';
    if (_selectedDateFilter != null) {
      dateFilterLabel = "${_selectedDateFilter!.day.toString().padLeft(2, '0')}.${_selectedDateFilter!.month.toString().padLeft(2, '0')}";
    }

    List<String> dynamicCategoryNames = ['Все'];
    if (!_isLoadingCategories) {
      dynamicCategoryNames.addAll(_serverCategories.map((c) => c['name'].toString()));
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Заявки', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                // === ИЗМЕНЕНО: Показываем кнопку создания ТОЛЬКО если это не подрядчик ===
                if (_userRole != 'contractor')
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRequestScreen())).then((_) => _loadAllData()),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Создать заявку'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildFilterChip(dateFilterLabel, _pickDateFilter, isActive: _selectedDateFilter != null)),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip(_isLoadingCategories ? 'Загрузка...' : (_selectedCategoryFilter ?? 'Категория'), () {
                  if (!_isLoadingCategories) _showSelectionSheet(title: 'Фильтр по категории', options: dynamicCategoryNames, currentValue: _selectedCategoryFilter, onSelected: (val) => setState(() => _selectedCategoryFilter = val));
                }, isActive: _selectedCategoryFilter != null)),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip(_selectedStatusFilter ?? 'Статус', () => _showSelectionSheet(title: 'Фильтр по статусу', options: _statuses, currentValue: _selectedStatusFilter, onSelected: (val) => setState(() => _selectedStatusFilter = val)), isActive: _selectedStatusFilter != null)),
              ],
            ),
            const SizedBox(height: 24),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text(centerDateText, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _requestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || _isLoadingCategories) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryMint));
                  }
                  if (snapshot.hasError) return Center(child: Text('Ошибка: ${snapshot.error}', style: const TextStyle(color: Colors.red)));

                  var requests = snapshot.data ?? [];

                  if (_selectedStatusFilter != null) {
                    final statusEn = _selectedStatusFilter == 'Новая' ? 'new' : _selectedStatusFilter == 'В работе' ? 'in_progress' : 'done';
                    requests = requests.where((r) => r['status'] == statusEn).toList();
                  }

                  if (_selectedCategoryFilter != null) {
                    final selectedCatObj = _serverCategories.firstWhere((c) => c['name'] == _selectedCategoryFilter, orElse: () => null);
                    if (selectedCatObj != null) {
                      requests = requests.where((r) {
                        final catId = r['category']?['id'] ?? r['category_id'];
                        return catId.toString() == selectedCatObj['id'].toString();
                      }).toList();
                    }
                  }

                  if (_selectedDateFilter != null) {
                    requests = requests.where((r) {
                      final createdAtString = r['created_at'] ?? r['createdAt'];
                      if (createdAtString == null) return false;
                      try {
                        final requestDate = DateTime.parse(createdAtString.toString());
                        return requestDate.year == _selectedDateFilter!.year && requestDate.month == _selectedDateFilter!.month && requestDate.day == _selectedDateFilter!.day;
                      } catch (e) {
                        return false;
                      }
                    }).toList();
                  }

                  if (requests.isEmpty) {
                    return const Center(child: Text('Заявок не найдено', style: TextStyle(color: AppColors.textGrey, fontSize: 16)));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadAllData(),
                    color: AppColors.primaryMint,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final status = req['status'] ?? 'new';

                        final categoryName = req['category']?['name'] ?? _getCategoryNameById(req['category_id']);

                        final location = req['location'] ?? 'Адрес не указан';
                        final idString = req['id']?.toString() ?? '???';

                        final serverRequestNumber = req['request_number']?.toString();
                        final shortId = serverRequestNumber ?? (idString.length > 8 ? idString.substring(0, 8).toUpperCase() : idString.toUpperCase());

                        final urgency = req['urgency'] != null ? _translateUrgency(req['urgency']) : 'Неизвестно';
                        final rawCreatedAt = req['created_at'] ?? req['createdAt'];
                        final rawDeadline = req['deadline'];
                        final imageUrl = req['photo_url'] ?? req['photo'] ?? req['imageUrl'];

                        return ExpandableRequestCard(
                          rawId: idString,
                          number: shortId,
                          statusText: _translateStatus(status),
                          statusBgColor: _getStatusBgColor(status),
                          statusTextColor: _getStatusTextColor(status),
                          category: categoryName,
                          address: location,
                          urgency: urgency,
                          createdAtDate: _formatDateString(rawCreatedAt),
                          deadlineDate: _formatDateString(rawDeadline),
                          imageUrlPath: imageUrl,
                          onReturnFromDetail: () {
                            _loadAllData();
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap, {bool isActive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: isActive ? AppColors.primaryMint : Colors.grey.shade600, fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500))),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: isActive ? AppColors.primaryMint : Colors.grey.shade600, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandableRequestCard extends StatefulWidget {
  final String rawId;
  final String number;
  final String statusText;
  final Color statusBgColor;
  final Color statusTextColor;
  final String category;
  final String address;
  final String urgency;
  final String createdAtDate;
  final String deadlineDate;
  final String? imageUrlPath;
  final VoidCallback onReturnFromDetail;

  const ExpandableRequestCard({
    super.key,
    required this.rawId,
    required this.number,
    required this.statusText,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.category,
    required this.address,
    required this.urgency,
    required this.createdAtDate,
    required this.deadlineDate,
    this.imageUrlPath,
    required this.onReturnFromDetail,
  });

  @override
  State<ExpandableRequestCard> createState() => _ExpandableRequestCardState();
}

class _ExpandableRequestCardState extends State<ExpandableRequestCard> {
  bool _isExpanded = false;
  void _toggleExpand() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final String baseUrl = 'https://city-service-production.up.railway.app';
    String rawPhotoUrl = widget.imageUrlPath ?? '';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Заявка №${widget.number}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(width: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: widget.statusBgColor, borderRadius: BorderRadius.circular(12)), child: Text(widget.statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.statusTextColor))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(widget.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Row(children: [const Text('Подробнее', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))), Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: const Color(0xFF94A3B8))]),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.address, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_isExpanded ? const SizedBox.shrink() : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 4,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('От', 'Монитор Байболды А.'),
                              _buildDetailRow('Кому', 'ИП CleanUralskCar'),
                              _buildDetailRow('Категория', widget.category),
                              _buildDetailRow('Взято на работу', 'Да'),
                              _buildDetailRow('Дата принятия', widget.createdAtDate),
                              _buildDetailRow('Срок', widget.deadlineDate),
                              _buildDetailRow('Срочность', widget.urgency),
                            ]
                        )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        flex: 3,
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                child: fullImageUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: fullImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMint)),
                                    errorWidget: (context, url, error) => const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 40),
                                  ),
                                )
                                    : const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 40)
                            )
                        )
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => RequestDetailScreen(requestNumber: widget.rawId)));
                          widget.onReturnFromDetail();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint.withValues(alpha: 0.12), foregroundColor: AppColors.primaryMint, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Посмотреть', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, fontFamily: 'Roboto'),
          children: [
            TextSpan(text: '$title ', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}