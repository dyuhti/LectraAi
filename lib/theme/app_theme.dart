import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF001F6B);
  static const Color primaryDark = Color(0xFF0D2A7A);
  static const Color primaryLight = Color(0xFF5B7FFF);
  static const Color background = Colors.white;
  static const Color textSecondary = Color(0xFF7A8AB8);
  static const Color border = Color(0xFFE8EDEF);
}

class AppDecorations {
  static BoxDecoration card({Color color = AppColors.background}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration heroCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration iconContainer({double radius = 14}) {
    return BoxDecoration(
      color: AppColors.primaryLight.withOpacity(0.12),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class AppButtonStyles {
  static ButtonStyle primary({double radius = 16}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
