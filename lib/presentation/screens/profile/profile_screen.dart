import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/storage/secure_storage.dart';
import '../../../data/api/request_service.dart';
import 'filtered_requests_screen.dart';
import '../auth/login_screen.dart'; // <--- Добавили импорт экрана логина для выхода

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RequestService _requestService = RequestService();

  bool _isLoading = true;
  String _userRole = '';
  String _userName = 'Загрузка...';
  String _userEmail = '';

  // Все заявки с сервера
  List<dynamic> _allRequests = [];

  // === Переменная для выбранного промежутка "ОТ и ДО" ===
  DateTimeRange? _selectedDateRange;

  // ПЕРЕМЕННЫЕ ДЛЯ СТАТИСТИКИ
  int _totalRequests = 0;
  int _newCount = 0;
  int _inProgressCount = 0;
  int _doneCount = 0;
  int _cancelledCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final role = await SecureStorage.getRole();

      if (mounted) {
        setState(() {
          _userRole = role ?? 'monitor';

          if (_userRole == 'contractor') {
            _userName = 'ИП Жумадилов';
            _userEmail = 'ipzhumadilovov@cityservice.com';
          } else if (_userRole == 'admin') {
            _userName = 'Администратор';
            _userEmail = 'admin@cityservice.com';
          } else {
            _userName = 'Акбергенов Даулет';
            _userEmail = 'daulet@cityservice.com';
          }
        });
      }

      // === УМНАЯ ЗАГРУЗКА: Админу не нужно скачивать заявки для статистики ===
      if (_userRole != 'admin') {
        final requests = await _requestService.getRequests();
        if (mounted) {
          setState(() {
            _allRequests = requests;
          });
          _calculateStats();
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    int tCount = 0, nCount = 0, ipCount = 0, dCount = 0, cCount = 0;

    for (var r in _allRequests) {
      final status = r['status'];
      String? dateStr;

      // Выбираем, на какую дату смотреть в зависимости от статуса!
      if (status == 'new') {
        dateStr = r['created_at'] ?? r['createdAt'];
      } else if (status == 'in_progress') {
        dateStr = r['taken_at'] ?? r['updated_at'] ?? r['created_at'];
      } else if (status == 'done') {
        dateStr = r['updated_at'] ?? r['created_at'];
      } else if (status == 'cancelled') {
        dateStr = r['updated_at'] ?? r['created_at'];
      } else {
        dateStr = r['created_at']; // На всякий случай
      }

      bool inRange = true;
      if (_selectedDateRange != null && dateStr != null) {
        try {
          final date = DateTime.parse(dateStr.toString());
          final dateObj = DateTime(date.year, date.month, date.day);
          final startObj = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final endObj = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);

          inRange = !dateObj.isBefore(startObj) && !dateObj.isAfter(endObj);
        } catch (e) {
          inRange = false;
        }
      } else if (_selectedDateRange != null && dateStr == null) {
        inRange = false; // Если дата пустая, а фильтр есть - не показываем
      }

      // Если заявка попадает в промежуток - плюсуем
      if (inRange) {
        tCount++;
        if (status == 'new') nCount++;
        else if (status == 'in_progress') ipCount++;
        else if (status == 'done') dCount++;
        else if (status == 'cancelled') cCount++;
      }
    }

    setState(() {
      _totalRequests = tCount;
      _newCount = nCount;
      _inProgressCount = ipCount;
      _doneCount = dCount;
      _cancelledCount = cCount;
    });
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      saveText: 'ПРИМЕНИТЬ',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryMint, // Главный зеленый цвет
              onPrimary: Colors.white,
              onSurface: AppColors.darkBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    } else {
      setState(() => _selectedDateRange = null);
    }

    _calculateStats();
  }

  // === ПРАВИЛЬНЫЙ МЕТОД ВЫХОДА ===
  void _logout() async {
    await SecureStorage.deleteToken();
    await SecureStorage.deleteRole();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Убирает всю историю экранов, чтобы нельзя было нажать "Назад"
    );
  }

  void _openRequestList(String title, String statusFilter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredRequestsScreen(
          title: title,
          statusFilter: statusFilter,
          dateRange: _selectedDateRange,
        ),
      ),
    ).then((_) {
      _loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryMint));
    }

    final isContractor = _userRole == 'contractor';
    final isAdmin = _userRole == 'admin'; // <--- ПРОВЕРЯЕМ АДМИНА

    final roleDisplay = isContractor ? 'Подрядчик' : (isAdmin ? 'Администратор' : 'Монитор');
    final mainStatLabel = isContractor ? 'Получено заявок' : 'Отправлено заявок';
    final mainStatIcon = isContractor ? Icons.move_to_inbox_outlined : Icons.send_outlined;

    String dateText = 'За все время';
    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      final startStr = "${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year.toString().substring(2)}";
      final endStr = "${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year.toString().substring(2)}";

      if (startStr == endStr) {
        dateText = startStr;
      } else {
        dateText = "$startStr - $endStr";
      }
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // === ШАПКА ПРОФИЛЯ ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), // <--- ДОБАВИЛИ ОТСТУПЫ ПО БОКАМ
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryMint.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 40, color: AppColors.primaryMint),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              roleDisplay.toUpperCase(),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === ПОКАЗЫВАЕМ СТАТИСТИКУ ТОЛЬКО ЕСЛИ ЭТО НЕ АДМИН ===
            if (!isAdmin) ...[
              // ЗАГОЛОВОК СТАТИСТИКИ И ВЫБОР ДИАПАЗОНА ДАТ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Статистика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                    GestureDetector(
                      onTap: _pickDateRange,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Text(dateText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryMint)),
                          const SizedBox(width: 4),
                          const Icon(Icons.calendar_month_outlined, color: AppColors.primaryMint, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ТАБЛИЦА СТАТИСТИКИ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(mainStatLabel, _totalRequests.toString(), mainStatIcon, Colors.blue, null, showArrow: false),
                      const Divider(height: 1, thickness: 1.5, color: Color(0xFFF1F5F9), indent: 48),

                      _buildStatRow('В обработке', _newCount.toString(), Icons.hourglass_empty_rounded, Colors.amber, () => _openRequestList('В обработке', 'new')),
                      const Divider(height: 1, thickness: 1.5, color: Color(0xFFF1F5F9), indent: 48),

                      _buildStatRow('В работе', _inProgressCount.toString(), Icons.play_circle_outline, Colors.green, () => _openRequestList('В работе', 'in_progress')),
                      const Divider(height: 1, thickness: 1.5, color: Color(0xFFF1F5F9), indent: 48),

                      _buildStatRow('Исполнено', _doneCount.toString(), Icons.check_circle_outline, AppColors.primaryMint, () => _openRequestList('Исполнено', 'done')),
                      const Divider(height: 1, thickness: 1.5, color: Color(0xFFF1F5F9), indent: 48),

                      _buildStatRow('Отменено', _cancelledCount.toString(), Icons.cancel_outlined, Colors.redAccent, () => _openRequestList('Отменено', 'cancelled')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // === МЕНЮ НАСТРОЕК ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(Icons.help_outline, 'Служба поддержки', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('В разработке')));
                    }),
                    const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String count, IconData icon, Color iconColor, VoidCallback? onTap, {bool showArrow = true}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkBackground)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(count, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              if (showArrow) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap, Color iconColor = AppColors.darkBackground, Color textColor = AppColors.darkBackground, bool showArrow = true}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null,
    );
  }
}