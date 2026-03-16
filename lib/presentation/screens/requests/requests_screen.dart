import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'request_detail_screen.dart';
import 'create_request_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String? _activeFilter;

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Заявки', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
                    );
                  },
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
            // 5. Список карточек
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  ExpandableRequestCard(
                    number: '№1K202526',
                    statusText: 'новая',
                    statusBgColor: AppColors.statusNewBg,
                    statusTextColor: AppColors.statusNewText,
                    category: 'Нарушение благоустройства',
                    address: 'Ул. Сейфуллина, 20/1',
                  ),
                  ExpandableRequestCard(
                    number: '№1S202562',
                    statusText: 'исполнено',
                    statusBgColor: AppColors.statusDoneBg,
                    statusTextColor: AppColors.statusDoneText,
                    category: 'Светофоры и ТСРДД',
                    address: 'Ул. Иманбаева, 20/1',
                  ),
                  ExpandableRequestCard(
                    number: '№1T202510',
                    statusText: 'в работе',
                    statusBgColor: AppColors.statusInProgressBg,
                    statusTextColor: AppColors.statusInProgressText,
                    category: 'Твердо Бытовые Отходы',
                    address: 'ул. Абая 5А, пересечение с ул. Момышулы',
                  ),
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

  Widget _buildDateContent() {
    return _buildSheetLayout(
      child: SizedBox(
        height: 280,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryMint,
              onPrimary: Colors.white,
              onSurface: AppColors.darkBackground,
            ),
            datePickerTheme: DatePickerThemeData(
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String title, bool isChecked, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () => onChanged(!isChecked),
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
}

// === НОВЫЙ ВИДЖЕТ РАСКРЫВАЮЩЕЙСЯ КАРТОЧКИ ===
class ExpandableRequestCard extends StatefulWidget {
  final String number;
  final String statusText;
  final Color statusBgColor;
  final Color statusTextColor;
  final String category;
  final String address;

  const ExpandableRequestCard({
    super.key,
    required this.number,
    required this.statusText,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.category,
    required this.address,
  });

  @override
  State<ExpandableRequestCard> createState() => _ExpandableRequestCardState();
}

class _ExpandableRequestCardState extends State<ExpandableRequestCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Верхняя часть
          GestureDetector(
            onTap: _toggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Заявка ${widget.number}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBackground),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: widget.statusBgColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.statusTextColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(widget.category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Row(
                      children: [
                        const Text('Подробнее', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        // Стрелочка меняет направление
                        Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.textGrey),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.address, style: const TextStyle(fontSize: 12, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // 2. Раскрывающаяся часть (Детали + Фото + Кнопка)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_isExpanded
                ? const SizedBox.shrink() // Если закрыто - занимает 0 пикселей
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: AppColors.dividerColor, height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левая колонка с текстом
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('От', 'Монитор Байболды А.'),
                          _buildInfoRow('Кому', 'ИП CleanUralskCar'),
                          _buildInfoRow('Категория', 'Благоустройство'),
                          _buildInfoRow('Взято на работу', 'Да'),
                          _buildInfoRow('Дата принятие', '10 мая, 2025'),
                          _buildInfoRow('Срок', '12 мая, 2025'),
                          _buildInfoRow('Срочность', 'Низкая'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Правая колонка с фото (пока заглушка)
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Кнопка "Посмотреть"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Переход на полный экран заявки
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestDetailScreen(requestNumber: widget.number),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint.withValues(alpha: 0.15), // Светло-зеленый фон
                      foregroundColor: AppColors.primaryMint, // Темно-зеленый текст
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Посмотреть', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный виджет для строк "Ключ: Значение"
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, fontFamily: 'Roboto'),
          children: [
            TextSpan(text: '$title ', style: const TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}