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
        // Cancel button — 48px
        GestureDetector(
          onTap: controller.cancelRecording,
          child: Container(
            width: AppSizes.avatarXL,
            height: AppSizes.avatarXL,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMutedColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: AppSizes.iconXL, color: AppColors.textTertiaryColor),
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
              _formatDuration(controller.recordingDuration.value.inSeconds),
              variant: AppTextVariant.label,
              color: AppColors.textPrimaryColor,
            )),
        const SizedBox(width: AppSizes.space3),
        // Waveform bars driven by real microphone amplitude
        Expanded(child: Obx(() => ChatWaveformBars(
          amplitude: controller.recordingAmplitude.value,
        ))),
        const SizedBox(width: AppSizes.space3),
        // Send button — 48px
        GestureDetector(
          onTap: controller.stopRecording,
          child: Container(
            width: AppSizes.avatarXL,
            height: AppSizes.avatarXL,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, size: AppSizes.iconXL, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
