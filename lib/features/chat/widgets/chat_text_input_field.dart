import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Text input field inside the chat input bar.
class ChatTextInputField extends StatelessWidget {
  final TextEditingController textController;
  final bool enabled;
  final bool isComplete;
  final void Function(String) onSubmitted;

  const ChatTextInputField({
    super.key,
    required this.textController,
    required this.enabled,
    required this.onSubmitted,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.buttonHeightMedium,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: textController,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: GoogleFonts.inter(fontSize: AppSizes.fontSizeSmall, color: AppColors.textPrimaryColor),
        decoration: InputDecoration.collapsed(
          hintText: isComplete ? 'chat_complete'.tr : 'chat_type_message'.tr,
          hintStyle: GoogleFonts.inter(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textTertiaryColor,
          ),
        ),
      ),
    );
  }
}
