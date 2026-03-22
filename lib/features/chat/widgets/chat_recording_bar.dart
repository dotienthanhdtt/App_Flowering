import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/ai_chat_controller.dart';
import 'chat_waveform_bars.dart';

/// Recording bar: cancel (X) + waveform area (red dot, timer, bars) + send.
class ChatRecordingBar extends StatelessWidget {
  final AiChatController controller;

  const ChatRecordingBar({super.key, required this.controller});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel button
        GestureDetector(
          onTap: controller.cancelRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMutedColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: AppSizes.iconSM, color: AppColors.textTertiaryColor),
          ),
        ),
        const SizedBox(width: AppSizes.space3),
        // Red dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.errorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.space2),
        // Timer
        Obx(() => AppText(
              _formatDuration(controller.recordingDuration.value),
              variant: AppTextVariant.label,
              color: AppColors.textPrimaryColor,
            )),
        const SizedBox(width: AppSizes.space3),
        // Waveform bars
        const Expanded(child: ChatWaveformBars()),
        const SizedBox(width: AppSizes.space3),
        // Send button
        GestureDetector(
          onTap: controller.stopRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, size: AppSizes.iconSM, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
