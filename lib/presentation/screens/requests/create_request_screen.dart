import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/global_header.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? _selectedCategory;
  String? _selectedCriticality;
  String? _selectedComplexity;
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Нарушение благоустройства', 'Твердо Бытовые Отходы', 'Крупно Габаритные Отходы',
    'Отчистка снега', 'Светофоры и ТСРДД', 'Освещение', 'Стихийные свалки', 'Покос травы', 'Обрезка деревьев'
  ];
  final List<String> _criticalities = ['Низкая', 'Средняя', 'Высокая', 'Критичная'];
  final List<String> _complexities = ['Легкий', 'Средний', 'Сложный'];

  // === МЕТОД ДЛЯ ВЫЗОВА КАЛЕНДАРЯ ===
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMint),
            ),
          ),
          child: child!,
        );
      },
    );

    // Если пользователь выбрал дату и нажал ОК
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Общий метод для шторки с галочками
  void _showSelectionSheet({
    required String title,
    required List<String> options,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) {
    String? tempSelection = currentValue;
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
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) => setModalState(() => tempSelection = option),
                                      activeColor: AppColors.primaryMint,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(option, style: TextStyle(fontSize: 15, color: isSelected ? AppColors.primaryMint : Colors.grey[600], fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal)),
                                        if (option == 'Отчистка снега') ...[
                                          const Text('содержание дорожно мостового хозяйства', style: TextStyle(fontSize: 11, color: AppColors.textGrey))
                                        ]
                                      ],
                                    ),
                                  ),
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
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), foregroundColor: AppColors.textGrey, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () { onSelected(tempSelection); Navigator.pop(context); }, child: const Text('Выбрать', style: TextStyle(fontWeight: FontWeight.bold)))),
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

  @override
  Widget build(BuildContext context) {
    String? formattedDate;
    if (_selectedDate != null) {
      formattedDate = MaterialLocalizations.of(context).formatMediumDate(_selectedDate!);
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const GlobalHeader(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkBackground, size: 24)),
                  const SizedBox(width: 12),
                  const Text('Создать заявку', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkBackground)),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Название заявки'),
              _buildTextField('Введите название проблемы'),

              _buildLabel('Категория'),
              _buildDropdownField(hint: 'Выберите проблему', selectedValue: _selectedCategory, onTap: () => _showSelectionSheet(title: 'Выбрать проблему', options: _categories, currentValue: _selectedCategory, onSelected: (val) => setState(() => _selectedCategory = val))),

              _buildLabel('Опишите проблему'),
              _buildTextField('Комментарий', maxLines: 4),

              _buildLabel('Выберите срочность'),
              _buildDropdownField(hint: 'Критичность', selectedValue: _selectedCriticality, onTap: () => _showSelectionSheet(title: 'Выбрать срочность', options: _criticalities, currentValue: _selectedCriticality, onSelected: (val) => setState(() => _selectedCriticality = val))),

              _buildLabel('Выбор сложности'),
              _buildDropdownField(hint: 'Сложность (Легкий, Средний...)', selectedValue: _selectedComplexity, onTap: () => _showSelectionSheet(title: 'Выбрать сложность', options: _complexities, currentValue: _selectedComplexity, onSelected: (val) => setState(() => _selectedComplexity = val))),

              // === НАШЕ НОВОЕ ПОЛЕ С ДАТОЙ ===
              _buildLabel('Укажите срок'),
              _buildDropdownField(
                hint: 'Срок заявки',
                selectedValue: formattedDate,
                onTap: _pickDate,
              ),

              _buildLabel('Укажите место'),
              _buildTextField('Адрес'),

              const SizedBox(height: 12),
              Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFEBE6D8), borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), fit: BoxFit.cover, opacity: 0.5)),
                child: const Center(child: Icon(Icons.location_on, color: Colors.blue, size: 40)),
              ),
              const SizedBox(height: 24),

              _buildLabel('Прикрепите изображение'),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: AppColors.primaryMint),
                  label: const Text('Загрузить фото', style: TextStyle(color: AppColors.primaryMint, fontSize: 16, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primaryMint, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Создать заявку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---
  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)));
  }

  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: TextField(maxLines: maxLines, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    );
  }

  Widget _buildDropdownField({required String hint, required String? selectedValue, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(selectedValue ?? hint, style: TextStyle(color: selectedValue == null ? AppColors.textGrey : AppColors.textDark, fontSize: 14, fontWeight: selectedValue == null ? FontWeight.normal : FontWeight.w500)),
            Icon(hint == 'Срок заявки' ? Icons.calendar_today : Icons.chevron_right, color: AppColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}