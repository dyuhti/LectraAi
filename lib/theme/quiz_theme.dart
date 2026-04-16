import 'package:flutter/material.dart';

class QuizColors {
  static const Color navy = Color(0xFF0A2A8A);
  static const Color royalStart = Color(0xFF1E4ED8);
  static const Color royalEnd = Color(0xFF3B82F6);
  static const Color softBackground = Color(0xFFF7F9FC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFDCE6FF);
  static const Color selectedOptionBg = Color(0xFFE8F0FF);
  static const Color selectedOptionBorder = Color(0xFF3B82F6);
  static const Color correctBg = Color(0xFFE6FFF5);
  static const Color correctBorder = Color(0xFF10B981);
  static const Color wrongBg = Color(0xFFFFF1F2);
  static const Color wrongBorder = Color(0xFFEF4444);
  static const Color infoBg = Color(0xFFEEF4FF);
  static const Color successButton = Color(0xFF1E4ED8);
  static const Color shadowColor = Color.fromRGBO(30, 78, 216, 0.12);
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
