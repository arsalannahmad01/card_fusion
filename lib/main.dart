import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'config/theme.dart';

void main() {
  runApp(const CardFusion());
}

class CardFusion extends StatelessWidget {
  const CardFusion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Fusion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
