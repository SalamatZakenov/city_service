import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/logo_widget.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String? _activeFilter;

  // 1. Храним состояние галочек
  final Map<String, bool> _statusFilters = {
    'Новое': true,
    'В работе': false,
    'Исполнено': false,
  };

  final Map<String, bool> _categoryFilters = {
    'Нарушение благоустройства': true,
    'Твердо Бытовые Отходы': true,
    'Крупно Габаритные Отходы': false,
    'Очистка снега': false,
  };

  void _openFilterSheet(String filterType, Widget content) {
    setState(() => _activeFilter = filterType);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => content,
    ).whenComplete(() {
      setState(() => _activeFilter = null);
    });
  }

  // ... МЕТОД build ОСТАЕТСЯ БЕЗ ИЗМЕНЕНИЙ (до виджетов шторок) ...
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LogoWidget(width: 110, color: AppColors.darkBackground),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Заявки', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Создать заявку'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMint,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildFilterButton(text: 'Дата', isActive: _activeFilter == 'date', onTap: () => _openFilterSheet('date', _buildDateContent()))),
                const SizedBox(width: 10),
                Expanded(child: _buildFilterButton(text: 'Категория', isActive: _activeFilter == 'category', onTap: () => _openFilterSheet('category', _buildCategoryContent()))),
                const SizedBox(width: 10),
                Expanded(child: _buildFilterButton(text: 'Статус', isActive: _activeFilter == 'status', onTap: () => _openFilterSheet('status', _buildStatusContent()))),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Text('Сегодня', style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildRequestCard(number: '№1K202526', statusText: 'новая', statusBgColor: AppColors.statusNewBg, statusTextColor: AppColors.statusNewText, category: 'Нарушение благоустройства', address: 'Ул. Сейфуллина, 20/1'),
                  _buildRequestCard(number: '№1S202562', statusText: 'исполнено', statusBgColor: AppColors.statusDoneBg, statusTextColor: AppColors.statusDoneText, category: 'Светофоры и ТСРДД', address: 'Ул. Сейфуллина, 20/1'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({required String text, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryMint : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(text, style: TextStyle(color: isActive ? Colors.white : AppColors.textGrey, fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 2),
            Icon(isActive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: isActive ? Colors.white : AppColors.textGrey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetLayout({required Widget child}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: AppColors.textGrey,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Показать', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // === ЖИВЫЕ ГАЛОЧКИ ДЛЯ СТАТУСА ===
  Widget _buildStatusContent() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        bool isAllSelected = _statusFilters.values.every((v) => v);
        return _buildSheetLayout(
          child: Column(
            children: [
              _buildCheckboxRow('Выбрать всё', isAllSelected, (val) {
                setModalState(() {
                  _statusFilters.updateAll((key, value) => val ?? false);
                });
              }),
              ..._statusFilters.keys.map((key) => _buildCheckboxRow(key, _statusFilters[key]!, (val) {
                setModalState(() {
                  _statusFilters[key] = val ?? false;
                });
              })),
            ],
          ),
        );
      },
    );
  }

  // === ЖИВЫЕ ГАЛОЧКИ ДЛЯ КАТЕГОРИЙ ===
  Widget _buildCategoryContent() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        bool isAllSelected = _categoryFilters.values.every((v) => v);
        return _buildSheetLayout(
          child: Column(
            children: [
              _buildCheckboxRow('Выбрать всё', isAllSelected, (val) {
                setModalState(() {
                  _categoryFilters.updateAll((key, value) => val ?? false);
                });
              }),
              ..._categoryFilters.keys.map((key) => _buildCheckboxRow(key, _categoryFilters[key]!, (val) {
                setModalState(() {
                  _categoryFilters[key] = val ?? false;
                });
              })),
            ],
          ),
        );
      },
    );
  }

  // === КАЛЕНДАРЬ С ЗЕЛЕНЫМ КВАДРАТОМ ===
  Widget _buildDateContent() {
    return _buildSheetLayout(
      child: SizedBox(
        height: 280,
        child: Theme(
          // Переопределяем тему только для календаря
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryMint, // Цвет выделения (Зеленый)
              onPrimary: Colors.white, // Текст на зеленом
              onSurface: AppColors.darkBackground, // Обычный текст
            ),
            datePickerTheme: DatePickerThemeData(
              // Делаем выделение квадратным с небольшим закруглением!
              dayShape: WidgetStatePropertyAll(
                RoundedRectangleBorder (
                  borderRadius: BorderRadius.circular(6),
                )
              ),
            ),
          ),
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) {
              // Логика при выборе даты
            },
          ),
        ),
      ),
    );
  }

  // Обновленный метод чекбокса (теперь он кликабельный)
  Widget _buildCheckboxRow(String title, bool isChecked, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () => onChanged(!isChecked), // Можно кликать по всей строке
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: onChanged,
                activeColor: AppColors.primaryMint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isChecked ? AppColors.primaryMint : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard({required String number, required String statusText, required Color statusBgColor, required Color statusTextColor, required String category, required String address}) {
    // ... (без изменений) ...
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Заявка $number', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Row(children: [Text('Подробнее', style: TextStyle(fontSize: 12, color: AppColors.textGrey)), Icon(Icons.chevron_right, size: 16, color: AppColors.textGrey)]),
            ],
          ),
          const SizedBox(height: 8),
          Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}