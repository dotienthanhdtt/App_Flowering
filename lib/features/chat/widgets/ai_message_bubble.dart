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
        const AiAvatar(),
        const SizedBox(width: AppSizes.spacingS),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
            padding: const EdgeInsets.all(AppSizes.paddingSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flora label
                AppText(
                  'ai_name'.tr,
                  variant: AppTextVariant.label,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSizes.spacingXS),
                // Message text — tappable words for translation
                AppTappablePhrase(
                  message.text ?? '',
                  variant: AppTextVariant.bodyLarge,
                  color: AppColors.textPrimary,
                  onWordTap: onWordTap != null
                      ? (word, _) => onWordTap!(word)
                      : null,
                ),
                // Translation section
                if (message.showTranslation &&
                    message.translatedText != null) ...[
                  Container(
                    margin: const EdgeInsets.only(top: AppSizes.spacingS),
                    padding: const EdgeInsets.only(top: AppSizes.spacingS),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.translate,
                                size: AppSizes.iconXXS, color: AppColors.info),
                            const SizedBox(width: AppSizes.spacingXS),
                            AppText(
                              'translation_target_language'.tr,
                              fontSize: AppSizes.fontXXS,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingXS),
                        AppText(
                          message.translatedText!,
                          variant: AppTextVariant.bodyMedium,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: AppSizes.lineHeightLoose,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.spacingS),
                // Action buttons — text style with icons
                Row(
                  children: [
                    TextActionButton(
                      icon: Icons.translate_rounded,
                      label: message.showTranslation
                          ? 'chat_hide_translation'.tr
                          : 'chat_translate'.tr,
                      color: AppColors.info,
                      onTap: onTranslate,
                    ),
                    const SizedBox(width: AppSizes.spacingL),
                    TextActionButton(
                      icon: Icons.volume_up_rounded,
                      label: 'chat_play_audio'.tr,
                      color: AppColors.textTertiary,
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
