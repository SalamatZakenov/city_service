import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../requests/requests_screen.dart';
import '../../widgets/global_header.dart';
import '../settings/settings_screen.dart';
import '../../../data/storage/secure_storage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Проверяем роль при запуске
  }

  // Загружаем роль из защищенного хранилища
  Future<void> _loadUserRole() async {
    final role = await SecureStorage.getRole();
    if (mounted && role != null) {
      setState(() {
        _userRole = role;
      });
    }
  }

  // Список экранов для каждой вкладки
  final List<Widget> _screens = [
    const RequestsScreen(),
    const Center(child: Text('Профиль')),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const GlobalHeader(),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.cardWhite,
          selectedItemColor: AppColors.primaryMint,
          unselectedItemColor: AppColors.textGrey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: _userRole == 'contractor' ? 'Задачи' : 'Заявки',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}