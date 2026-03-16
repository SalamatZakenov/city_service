import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RequestDetailScreen extends StatelessWidget {
  final String requestNumber;

  const RequestDetailScreen({super.key, required this.requestNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        title: Text('Заявка $requestNumber', style: const TextStyle(color: AppColors.darkBackground, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.darkBackground),
        elevation: 0,
      ),
      body: const Center(
        child: Text('Здесь будет полная информация о заявке', style: TextStyle(color: AppColors.textGrey)),
      ),
    );
  }
}