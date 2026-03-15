import 'package:flutter/material.dart';
import 'presentation/screens/welcome/welcome_screen.dart';

void main() {
  runApp(const CityServiceApp());
}

class CityServiceApp extends StatelessWidget {
  const CityServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uralsk Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', // Можно заменить на шрифт из макета (например, Inter или Montserrat)
      ),
      home: const WelcomeScreen(),
    );
  }
}