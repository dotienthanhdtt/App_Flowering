import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import 'chat_waveform_bars.dart';

/// Recording bar: cancel (X) + waveform area (red dot, timer, bars) + send.
/// Controller-agnostic — driven by raw Rx values and callbacks so any chat
/// feature can reuse it (onboarding chat, scenario chat, etc).
class ChatRecordingBar extends StatelessWidget {
  final Rx<Duration> duration;
  final RxDouble amplitude;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const ChatRecordingBar({
    super.key,
    required this.duration,
    required this.amplitude,
    required this.onCancel,
    required this.onSend,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCancel,
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
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.errorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.space2),
        Obx(() => AppText(
              _formatDuration(duration.value.inSeconds),
              variant: AppTextVariant.label,
              color: AppColors.textPrimaryColor,
            )),
        const SizedBox(width: AppSizes.space3),
        Expanded(
          child: Obx(() => ChatWaveformBars(amplitude: amplitude.value)),
        ),
        const SizedBox(width: AppSizes.space3),
        GestureDetector(
          onTap: onSend,
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
