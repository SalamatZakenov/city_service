import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double width; // Теперь нам нужна только общая ширина логотипа

  const LogoWidget({
    super.key,
    this.width = 150, // Размер по умолчанию
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png', // Указываем путь к твоей картинке
      width: width,
      fit: BoxFit.contain, // Картинка будет пропорционально вписываться в ширину
    );
  }
}