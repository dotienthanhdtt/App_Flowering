import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_tappable_phrase.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/chat_message_model.dart';
import 'text_action_button.dart';

/// AI message bubble: white card with shadow, tappable text,
/// optional translation inside card, action pill buttons below card.
class AiMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTranslate;
  final VoidCallback? onPlayAudio;
  final void Function(String word)? onWordTap;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onTranslate,
    this.onPlayAudio,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowMediumColor,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSizes.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTappablePhrase(
                  message.text ?? '',
                  variant: AppTextVariant.bodyLarge,
                  color: AppColors.textPrimaryColor,
                  onWordTap: onWordTap != null
                      ? (word, _) => onWordTap!(word)
                      : null,
                ),
                // Translation section inside card
                if (message.showTranslation &&
                    message.translatedText != null) ...[
                  Container(
                    margin: const EdgeInsets.only(top: AppSizes.space3),
                    padding: const EdgeInsets.only(top: AppSizes.space3),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.infoColor),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.translate,
                            size: AppSizes.iconSM, color: AppColors.infoColor),
                        const SizedBox(width: AppSizes.space2),
                        Expanded(
                          child: AppText(
                            message.translatedText!,
                            variant: AppTextVariant.bodyLarge,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action buttons below card
          const SizedBox(height: AppSizes.space2),
          Row(
            children: [
              TextActionButton(
                icon: Icons.translate_rounded,
                label: message.showTranslation
                    ? 'chat_hide_translation'.tr
                    : 'chat_translate'.tr,
                color: AppColors.infoColor,
                onTap: onTranslate,
                hasPillBackground: true,
              ),
              const SizedBox(width: AppSizes.space4),
              TextActionButton(
                icon: Icons.volume_up_rounded,
                label: 'chat_play_audio'.tr,
                color: AppColors.textTertiaryColor,
                onTap: onPlayAudio,
                hasPillBackground: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
