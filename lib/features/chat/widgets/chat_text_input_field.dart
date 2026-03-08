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
      height: AppSizes.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: textController,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: GoogleFonts.outfit(fontSize: AppSizes.fontM, color: AppColors.textPrimary),
        decoration: InputDecoration.collapsed(
          hintText: isComplete ? 'chat_complete'.tr : 'chat_type_message'.tr,
          hintStyle: GoogleFonts.outfit(
            fontSize: AppSizes.fontM,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
