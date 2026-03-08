import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Send (orange) or Mic (orange) button depending on input state.
class ChatActionButton extends StatelessWidget {
  final bool showSend;
  final VoidCallback? onSend;
  final VoidCallback? onMic;

  const ChatActionButton({
    super.key,
    required this.showSend,
    this.onSend,
    this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showSend ? onSend : onMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: AppSizes.inputHeight,
        height: AppSizes.inputHeight,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          showSend ? Icons.send_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: AppSizes.iconM,
        ),
      ),
    );
  }
}
