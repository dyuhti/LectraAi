import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryDark = Color(0xFF172554);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD1D5DB);
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
        colors: [AppColors.primary, AppColors.secondary],
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
      color: AppColors.primaryLight.withOpacity(0.10),
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
