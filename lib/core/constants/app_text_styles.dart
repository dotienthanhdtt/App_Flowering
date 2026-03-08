import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

/// App typography styles
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: AppSizes.font8XL,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: AppSizes.font6XL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: AppSizes.font4XL,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: AppSizes.font3XL,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: AppSizes.fontM,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}
