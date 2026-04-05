import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../requests/requests_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/global_header.dart';
import '../settings/settings_screen.dart';
import '../../../data/storage/secure_storage.dart';
import '../admin/admin_dashboard_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  String _userRole = '';
  bool _isLoadingRole = true; // <--- ДОБАВИЛИ ФЛАГ ЗАГРУЗКИ РОЛИ

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await SecureStorage.getRole();
    if (mounted) {
      setState(() {
        _userRole = role ?? 'user';
        _isLoadingRole = false; // <--- РОЛЬ ОПРЕДЕЛЕНА
      });
    }
  }

  List<Widget> get _screens => [
    _userRole == 'admin' ? const AdminDashboardScreen() : const RequestsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Пока не поймем, админ это или нет - показываем загрузку,
    // чтобы старые экраны не делали запросы (ошибка 403)
    if (_isLoadingRole) {
      return const Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryMint)),
      );
    }

    String firstTabLabel = 'Заявки';
    if (_userRole == 'contractor') {
      firstTabLabel = 'Задачи';
    } else if (_userRole == 'admin') {
      firstTabLabel = 'Дашборд';
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: (_userRole == 'admin' && _currentIndex == 0)
          ? null
          : const GlobalHeader(),
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
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment),
              label: firstTabLabel,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
            const BottomNavigationBarItem(
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