import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';

/// Reusable form text field matching the app's design language.
/// Supports label, hint, validation, and password visibility toggle.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.label,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.space2),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: GoogleFonts.inter(fontSize: AppSizes.fontSizeMedium, color: AppColors.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: AppSizes.fontSizeMedium, color: AppColors.textTertiaryColor),
            filled: true,
            fillColor: AppColors.surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSizes.space4, vertical: AppSizes.space4),
            border: _border(AppColors.borderLightColor),
            enabledBorder: _border(AppColors.borderLightColor),
            focusedBorder: _border(AppColors.primaryColor),
            errorBorder: _border(AppColors.errorColor),
            focusedErrorBorder: _border(AppColors.errorColor),
            suffixIcon: onToggleObscure != null
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: AppSizes.iconL,
                      color: AppColors.textTertiaryColor,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: BorderSide(color: color, width: AppSizes.borderMedium),
      );
}
