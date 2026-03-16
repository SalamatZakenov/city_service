import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'logo_widget.dart';

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlobalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const LogoWidget(width: 110, color: AppColors.darkBackground),
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Белый кружок для колокольчика
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.darkBackground),
                    onPressed: () {},
                  ),
                ),
                // Красный бейдж уведомлений
                // Positioned(
                //   right: 0,
                //   top: 0,
                //   child: Container(
                //     padding: const EdgeInsets.all(4),
                //     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                //     child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Задаем фиксированную высоту для шапки
  @override
  Size get preferredSize => const Size.fromHeight(60);
}