import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double width;
  final Color? color;

  const LogoWidget({
    super.key,
    this.width = 150,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      color: color,
      fit: BoxFit.contain,
    );
  }
}