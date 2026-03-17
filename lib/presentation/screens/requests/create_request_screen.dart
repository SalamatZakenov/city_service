import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/global_header.dart';
import '../../../data/api/request_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final RequestService _requestService = RequestService();

  String? _selectedCategoryName;
  String? _selectedCriticality;
  DateTime? _selectedDate;

  bool _isLoading = false;
  bool _isLoadingCategories = true; // Крутилка для загрузки категорий

  // Сюда будем сохранять категории с сервера
  List<dynamic> _serverCategories = [];

  final List<String> _criticalities = ['Низкая', 'Средняя', 'Высокая', 'Критичная'];

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Запускаем скачивание категорий при открытии экрана
  }

  // Метод для скачивания категорий
  Future<void> _loadCategories() async {
    final categories = await _requestService.getCategories();
    if (mounted) {
      setState(() {
        _serverCategories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  // Превращаем русскую срочность в английскую
  String _getUrgencyValue(String urgency) {
    if (urgency == 'Низкая') return 'low';
    if (urgency == 'Критичная') return 'critical';
    return 'medium';
  }

  // === ГЛАВНЫЙ МЕТОД ОТПРАВКИ ===
  Future<void> _submitRequest() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty || desc.isEmpty || address.isEmpty || _selectedCategoryName == null || _selectedCriticality == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    String? deadline;
    if (_selectedDate != null) {
      deadline = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    }

    // НАХОДИМ ПРАВИЛЬНЫЙ ID КАТЕГОРИИ
    final selectedCategoryObj = _serverCategories.firstWhere((cat) => cat['name'] == _selectedCategoryName);
    final categoryId = selectedCategoryObj['id'] as int;

    // Отправляем на сервер
    final error = await _requestService.createRequest(
      title: title,
      categoryId: categoryId, // Передаем реальный ID
      description: desc,
      urgency: _getUrgencyValue(_selectedCriticality!),
      location: address,
      deadline: deadline,
    );

    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Заявка успешно создана!'), backgroundColor: AppColors.primaryMint));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
      }
    }
  }

  // Шторка календаря
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryMint, onPrimary: Colors.white, onSurface: AppColors.darkBackground)), child: child!);
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Шторка выбора
  void _showSelectionSheet({required String title, required List<String> options, required String? currentValue, required ValueChanged<String?> onSelected}) {
    String? tempSelection = currentValue;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true, physics: const BouncingScrollPhysics(), itemCount: options.length,
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
                                  SizedBox(height: 24, width: 24, child: Checkbox(value: isSelected, onChanged: (val) => setModalState(() => tempSelection = option), activeColor: AppColors.primaryMint)),
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
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, foregroundColor: Colors.white, elevation: 0), onPressed: () { onSelected(tempSelection); Navigator.pop(context); }, child: const Text('Выбрать'))),
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
    if (_selectedDate != null) formattedDate = "${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}";

    // Извлекаем только имена категорий для шторки
    List<String> categoryNames = _serverCategories.map((c) => c['name'].toString()).toList();

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
              _buildTextField('Введите название проблемы', _titleController),

              _buildLabel('Категория'),
              // Если категории еще грузятся, показываем текст "Загрузка..."
              _isLoadingCategories
                  ? _buildDropdownField(hint: 'Загрузка категорий...', selectedValue: null, onTap: () {})
                  : _buildDropdownField(
                  hint: 'Выберите проблему',
                  selectedValue: _selectedCategoryName,
                  onTap: () => _showSelectionSheet(title: 'Выбрать проблему', options: categoryNames, currentValue: _selectedCategoryName, onSelected: (val) => setState(() => _selectedCategoryName = val))
              ),

              _buildLabel('Опишите проблему'),
              _buildTextField('Комментарий', _descController, maxLines: 4),

              _buildLabel('Выберите срочность'),
              _buildDropdownField(hint: 'Критичность', selectedValue: _selectedCriticality, onTap: () => _showSelectionSheet(title: 'Выбрать срочность', options: _criticalities, currentValue: _selectedCriticality, onSelected: (val) => setState(() => _selectedCriticality = val))),

              _buildLabel('Укажите срок'),
              _buildDropdownField(hint: 'Срок заявки', selectedValue: formattedDate, onTap: _pickDate),

              _buildLabel('Укажите место'),
              _buildTextField('Адрес', _addressController),

              const SizedBox(height: 12),
              Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFEBE6D8), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.location_on, color: Colors.blue, size: 40))),
              const SizedBox(height: 24),

              _buildLabel('Прикрепите изображение'),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, color: AppColors.primaryMint), label: const Text('Загрузить фото', style: TextStyle(color: AppColors.primaryMint, fontSize: 16)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primaryMint, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Создать заявку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)));
  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1}) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))));
  Widget _buildDropdownField({required String hint, required String? selectedValue, required VoidCallback onTap}) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(selectedValue ?? hint, style: TextStyle(color: selectedValue == null ? AppColors.textGrey : AppColors.textDark, fontSize: 14)), Icon(hint == 'Срок заявки' || hint == 'Загрузка категорий...' ? Icons.calendar_today : Icons.chevron_right, color: AppColors.textGrey, size: 20)])));
}