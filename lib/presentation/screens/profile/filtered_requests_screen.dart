import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/request_service.dart';
import '../requests/requests_screen.dart';

class FilteredRequestsScreen extends StatefulWidget {
  final String title;
  final String statusFilter;
  final DateTimeRange? dateRange; // <--- ДОБАВИЛИ ПРИЕМ ДАТЫ

  const FilteredRequestsScreen({
    super.key,
    required this.title,
    required this.statusFilter,
    this.dateRange, // <--- СОХРАНЯЕМ ДАТУ
  });

  @override
  State<FilteredRequestsScreen> createState() => _FilteredRequestsScreenState();
}

class _FilteredRequestsScreenState extends State<FilteredRequestsScreen> {
  final RequestService _requestService = RequestService();
  Future<List<dynamic>>? _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _requestsFuture = _requestService.getRequests();
    });
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
      case 'new': return 'Новая';
      case 'in_progress': return 'В работе';
      case 'done': return 'Исполнено';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkBackground, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryMint));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ошибка загрузки данных', style: TextStyle(color: Colors.red)));
          }

          final allRequests = snapshot.data ?? [];

          // 1. Фильтруем по статусу
          var requests = allRequests.where((r) => r['status'] == widget.statusFilter).toList();

          // 2. === ФИЛЬТРУЕМ ПО ВРЕМЕНИ (Умный выбор даты) ===
          if (widget.dateRange != null) {
            requests = requests.where((r) {
              String? dateStr;

              // Выбираем правильное поле даты в зависимости от того, какой список открыт
              if (widget.statusFilter == 'new') {
                dateStr = r['created_at'] ?? r['createdAt'];
              } else if (widget.statusFilter == 'in_progress') {
                dateStr = r['taken_at'] ?? r['updated_at'] ?? r['created_at'];
              } else if (widget.statusFilter == 'done') {
                dateStr = r['updated_at'] ?? r['created_at'];
              } else if (widget.statusFilter == 'cancelled') {
                dateStr = r['updated_at'] ?? r['created_at'];
              }

              if (dateStr == null) return false;

              try {
                final date = DateTime.parse(dateStr.toString());
                final dateObj = DateTime(date.year, date.month, date.day);
                final startObj = DateTime(widget.dateRange!.start.year, widget.dateRange!.start.month, widget.dateRange!.start.day);
                final endObj = DateTime(widget.dateRange!.end.year, widget.dateRange!.end.month, widget.dateRange!.end.day);

                return !dateObj.isBefore(startObj) && !dateObj.isAfter(endObj);
              } catch (e) {
                return false;
              }
            }).toList();
          }

          if (requests.isEmpty) {
            return Center(
              child: Text('За этот период заявок нет', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: AppColors.primaryMint,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
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
                  onReturnFromDetail: () => _loadData(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}