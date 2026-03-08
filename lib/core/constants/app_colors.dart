import 'package:flutter/material.dart';
import 'app_sizes.dart';

/// App color palette — Flowering Warm Neutral (Pencil Design System)
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF7A27);
  static const Color primaryLight = Color(0xFFFFB380);
  static const Color primaryDark = Color(0xFFD4621A);
  static const Color primarySoft = Color(0xFFFFEADB);

  // Neutrals
  static const Color background = Color(0xFFF8F4E3);
  static const Color backgroundWarm = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2EED8);

  // Text
  static const Color textPrimary = Color(0xFF191919);
  static const Color textSecondary = Color(0xFF5C5646);
  static const Color textTertiary = Color(0xFF9C9585);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE5DFC9);
  static const Color borderLight = Color(0xFFF0ECDA);
  static const Color borderStrong = Color(0xFFD4CEAE);

  // Semantic
  static const Color success = Color(0xFF6BAF7A);
  static const Color successLight = Color(0xFFE2F3E5);
  static const Color warning = Color(0xFFE8C460);
  static const Color warningLight = Color(0xFFFDF5DC);
  static const Color error = Color(0xFFD97B7B);
  static const Color errorLight = Color(0xFFFBEAEA);
  static const Color info = Color(0xFF7AACCC);
  static const Color infoLight = Color(0xFFE0F0FA);

  // Accent — Blue
  static const Color accentBlue = Color(0xFF7AACCC);
  static const Color accentBlueDark = Color(0xFF5A8DAD);
  static const Color accentBlueLight = Color(0xFFE0F0FA);

  // Accent — Green
  static const Color accentGreen = Color(0xFF6BAF7A);
  static const Color accentGreenDark = Color(0xFF4A8A58);
  static const Color accentGreenLight = Color(0xFFE2F3E5);

  // Accent — Lavender
  static const Color accentLavender = Color(0xFFB8A9D4);
  static const Color accentLavenderDark = Color(0xFF8E7DB8);
  static const Color accentLavenderLight = Color(0xFFEDE8F5);

  // Accent — Rose
  static const Color accentRose = Color(0xFFE8A0A0);
  static const Color accentRoseDark = Color(0xFFC47878);
  static const Color accentRoseLight = Color(0xFFFBE8E8);

  // Shadow
  static const Color shadow = Color(0x10191919);

  // Chat
  static const Color userBubble = Color(0xFFFF7A27);
  static const Color aiBubble = Color(0xFFFFFFFF);

  // Radius constants (delegated to AppSizes for single source of truth)
  static const double radiusS = AppSizes.radiusS;
  static const double radiusM = AppSizes.radiusM;
  static const double radiusL = AppSizes.radiusL;
  static const double radiusXL = AppSizes.radiusXL;
  static const double radiusPill = AppSizes.radiusPill;
}
