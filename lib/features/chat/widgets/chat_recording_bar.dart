import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
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
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: AppSizes.iconSM, color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        // Red dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        // Timer
        Obx(() => Text(
              _formatDuration(controller.recordingDuration.value),
              style: GoogleFonts.outfit(
                fontSize: AppSizes.fontM,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            )),
        const SizedBox(width: AppSizes.spacingM),
        // Waveform bars
        const Expanded(child: ChatWaveformBars()),
        const SizedBox(width: AppSizes.spacingM),
        // Send button
        GestureDetector(
          onTap: controller.stopRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, size: AppSizes.iconSM, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
