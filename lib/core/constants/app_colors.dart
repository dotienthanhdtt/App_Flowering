import 'package:flutter/material.dart';
import 'app_sizes.dart';

/// App color palette — Flowering Design System (Pencil)
/// Token names match design file: flowering_design.pen
class AppColors {
  AppColors._();

  // Primary — primary_color
  static const Color primaryColor = Color(0xFFFD9029);
  static const Color primaryLightColor = Color(0xFFFFB380);
  static const Color primarySoftColor = Color(0xFFFFEADB);

  // Secondary — secondary_color
  static const Color secondaryColor = Color(0xFF0077BA);
  static const Color secondaryDarkColor = Color(0xFF005A8D);
  static const Color secondaryLightColor = Color(0xFFE0F0FA);

  // Tertiary — tertiary_color
  static const Color tertiaryColor = Color(0xFF1447E6);

  // Neutral — neutral_color
  static const Color neutralColor = Color(0xFF545F71);

  // Background — background_color
  static const Color backgroundColor = Color(0xFFF9F7F2);
  static const Color backgroundWarmColor = Color(0xFFFFF8F0);

  // Surface — surface_color
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceMutedColor = Color(0xFFF2EED8);

  // Text
  static const Color textPrimaryColor = Color(0xFF191919);
  static const Color textSecondaryColor = Color(0xFF5C5646);
  static const Color textTertiaryColor = Color(0xFF9C9585);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);

  // Borders
  static const Color borderColor = Color(0xFFE5DFC9);
  static const Color borderLightColor = Color(0xFFF0ECDA);
  static const Color borderStrongColor = Color(0xFFD4CEAE);

  // Success — success_color
  static const Color successColor = Color(0xFF60993E);
  static const Color successDarkColor = Color(0xFF4A8A58);
  static const Color successLightColor = Color(0xFFE2F3E5);

  // Warning — warning_color
  static const Color warningColor = Color(0xFFFFB830);
  static const Color warningLightColor = Color(0xFFFDF5DC);

  // Error — error_color
  static const Color errorColor = Color(0xFFE63950);
  static const Color errorLightColor = Color(0xFFFBEAEA);

  // Info — info_color
  static const Color infoColor = Color(0xFF9CB0CF);

  // Accent
  static const Color lavenderLightColor = Color(0xFFEDE8F5);
  static const Color roseLightColor = Color(0xFFFBE8E8);

  // Shadow
  static const Color shadowColor = Color(0x10191919);

  // Radius constants (delegated to AppSizes for single source of truth)
  static const double radiusS = AppSizes.radiusS;
  static const double radiusM = AppSizes.radiusM;
  static const double radiusL = AppSizes.radiusL;
  static const double radiusXL = AppSizes.radiusXL;
  static const double radiusPill = AppSizes.radiusPill;
}
