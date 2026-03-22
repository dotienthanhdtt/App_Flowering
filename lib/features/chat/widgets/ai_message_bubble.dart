import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_tappable_phrase.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/chat_message_model.dart';
import 'ai_avatar.dart';
import 'text_action_button.dart';

/// AI message bubble with avatar, "Flora" label, text, optional translation,
/// and translate/play text-style action buttons.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: AppSizes.space2),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppSizes.radiusL),
                bottomLeft: Radius.circular(AppSizes.radiusL),
                bottomRight: Radius.circular(AppSizes.radiusL),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08191919),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSizes.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flora label
                AppText(
                  'ai_name'.tr,
                  variant: AppTextVariant.label,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: AppSizes.space1),
                // Message text — tappable words for translation
                AppTappablePhrase(
                  message.text ?? '',
                  variant: AppTextVariant.bodyLarge,
                  color: AppColors.textPrimaryColor,
                  onWordTap: onWordTap != null
                      ? (word, _) => onWordTap!(word)
                      : null,
                ),
                // Translation section
                if (message.showTranslation &&
                    message.translatedText != null) ...[
                  Container(
                    margin: const EdgeInsets.only(top: AppSizes.space2),
                    padding: const EdgeInsets.only(top: AppSizes.space2),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.borderLightColor),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.translate,
                                size: AppSizes.iconXXS, color: AppColors.infoColor),
                            const SizedBox(width: AppSizes.space1),
                            AppText(
                              'translation_target_language'.tr,
                              fontSize: AppSizes.fontSizeXSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.infoColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.space1),
                        AppText(
                          message.translatedText!,
                          variant: AppTextVariant.bodyMedium,
                          color: AppColors.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                          height: AppSizes.lineHeightBase,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.space2),
                // Action buttons — text style with icons
                Row(
                  children: [
                    TextActionButton(
                      icon: Icons.translate_rounded,
                      label: message.showTranslation
                          ? 'chat_hide_translation'.tr
                          : 'chat_translate'.tr,
                      color: AppColors.infoColor,
                      onTap: onTranslate,
                    ),
                    const SizedBox(width: AppSizes.space4),
                    TextActionButton(
                      icon: Icons.volume_up_rounded,
                      label: 'chat_play_audio'.tr,
                      color: AppColors.textTertiaryColor,
                      onTap: onPlayAudio,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
