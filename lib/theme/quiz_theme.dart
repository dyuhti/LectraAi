import 'package:flutter/material.dart';

class QuizColors {
  static const Color navy = Color(0xFF1E3A8A);
  static const Color royalStart = Color(0xFF1E3A8A);
  static const Color royalEnd = Color(0xFF3B82F6);
  static const Color softBackground = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color selectedOptionBg = Color(0xFFEFF6FF);
  static const Color selectedOptionBorder = Color(0xFF3B82F6);
  static const Color correctBg = Color(0xFFEFF6FF);
  static const Color correctBorder = Color(0xFF3B82F6);
  static const Color wrongBg = Color(0xFFF3F4F6);
  static const Color wrongBorder = Color(0xFF9CA3AF);
  static const Color infoBg = Color(0xFFF8FAFC);
  static const Color successButton = Color(0xFF1E3A8A);
  static const Color shadowColor = Color.fromRGBO(30, 58, 138, 0.12);
}

class QuizShadows {
  static List<BoxShadow> card = [
    const BoxShadow(
      color: QuizColors.shadowColor,
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}

class QuizGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [QuizColors.royalStart, QuizColors.royalEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
