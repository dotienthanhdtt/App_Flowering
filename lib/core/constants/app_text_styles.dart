import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

/// App typography styles
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.inter(
        fontSize: AppSizes.fontSize5XLarge,
        fontWeight: FontWeight.w700,
        height: AppSizes.lineHeight5XLarge,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: AppSizes.fontSize4XLarge,
        fontWeight: FontWeight.w700,
        height: AppSizes.lineHeight4XLarge,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: AppSizes.fontSize2XLarge,
        fontWeight: FontWeight.w600,
        height: AppSizes.lineHeight2XLarge,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeXLarge,
        fontWeight: FontWeight.w600,
        height: AppSizes.lineHeightXLarge,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: AppSizes.fontSize3XLarge,
        fontWeight: FontWeight.w600,
        height: AppSizes.lineHeight3XLarge,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.w400,
        height: AppSizes.lineHeightMedium,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeSmall,
        fontWeight: FontWeight.w400,
        height: AppSizes.lineHeightSmall,
        color: AppColors.textPrimaryColor,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeXSmall,
        fontWeight: FontWeight.w600,
        height: AppSizes.lineHeightXSmall,
        color: AppColors.textSecondaryColor,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeLarge,
        fontWeight: FontWeight.w600,
        height: AppSizes.lineHeightLarge,
        color: Colors.white,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeXSmall,
        fontWeight: FontWeight.w400,
        height: AppSizes.lineHeightXSmall,
        color: AppColors.textTertiaryColor,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: AppSizes.fontSizeSmall,
        fontWeight: FontWeight.w500,
        height: AppSizes.lineHeightBase,
        color: AppColors.textSecondaryColor,
      );
}
