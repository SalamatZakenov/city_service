import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/global_header.dart';

class ContractorRequestsScreen extends StatelessWidget {
  const ContractorRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const GlobalHeader(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Мои задачи',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkBackground),
            ),
            const SizedBox(height: 20),
            // Тут будет список заявок, которые прилетают именно подрядчику
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('Новых задач пока нет', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}