import 'package:flutter/material.dart';

class AppColors {
  // Основные акценты
  static const Color primary = Color(0xFF9B5CFF);
  static const Color primaryDark = Color(0xFF7A33FF);
  static const Color secondary = Color(0xFF5CE1E6);

  // Фон и поверхности
  static const Color background = Color(0xFF0B0F1A);
  static const Color surface = Color(0xFF111728);
  static const Color card = Color(0xFF151C2F);
  static const Color cardDarker = Color(0xFF0F1423);
  static const Color border = Color(0xFF24314A);

  // Текст
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8C0CC);
  static const Color textMuted = Color(0xFF7C8598);

  // Состояния
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);

  // Градиенты
  static const List<Color> primaryGradient = [
    Color(0xFF9B5CFF),
    Color(0xFF6E8BFF),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF1B1F35),
    Color(0xFF0F1324),
  ];
}
