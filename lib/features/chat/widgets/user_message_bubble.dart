import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/chat_message_model.dart';

/// Blue user text bubble, right-aligned, rounded 12px all corners.
/// Grammar correction is rendered separately in the chat list.
class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const UserMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(AppSizes.space4),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: AppText(
          message.text ?? '',
          fontSize: AppSizes.fontSizeLarge,
          color: Colors.white,
        ),
      ),
    );
  }
}
