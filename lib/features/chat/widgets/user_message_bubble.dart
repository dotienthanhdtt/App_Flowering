import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/chat_message_model.dart';
import 'grammar_correction_section.dart';

/// Orange user text bubble, right-aligned, rounded [16,16,0,16].
/// Shows grammar correction section when correctedText is available.
class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onToggleCorrection;

  const UserMessageBubble({
    super.key,
    required this.message,
    this.onToggleCorrection,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space4, vertical: AppSizes.space3),
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusL),
            topRight: Radius.circular(AppSizes.radiusL),
            bottomLeft: Radius.circular(AppSizes.radiusL),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              message.text ?? '',
              variant: AppTextVariant.label,
              color: Colors.white,
            ),
            if (message.correctedText != null) ...[
              const SizedBox(height: AppSizes.space2),
              GrammarCorrectionSection(
                correctedText: message.correctedText!,
                isExpanded: message.showCorrection,
                onToggle: () => onToggleCorrection?.call(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
