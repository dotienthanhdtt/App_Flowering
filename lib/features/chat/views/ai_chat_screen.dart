import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/chat_message_model.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_typing_bubble.dart';
import '../widgets/chat-context-card.dart';
import '../widgets/quick_reply_row.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_top_bar.dart';
import '../widgets/grammar_correction_section.dart';
import '../widgets/user_message_bubble.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Screen 07 — AI chat with updated design (08A-08E).
class AiChatScreen extends BaseScreen<AiChatController> {
  const AiChatScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Column(
        children: [
          Obx(() => ChatTopBar(title: controller.chatTitle.value)),
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return _ErrorBanner(
                message: controller.errorMessage.value,
                onRetry: controller.messages.isEmpty
                    ? controller.retrySession
                    : null,
              );
            }
            return const SizedBox.shrink();
          }),
          // Context card
          Obx(() {
            if (controller.contextDescription.value.trim().isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.space4, AppSizes.space3, AppSizes.space4, 0,
                ),
                child: ChatContextCard(
                  description: controller.contextDescription.value,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(child: _ChatList(controller: controller)),
          // Partial text overlay during voice input
          Obx(() {
            final isListening = controller.voiceInputService.isListening.value;
            final partial = controller.voiceInputService.partialText.value;
            if (!isListening) return const SizedBox.shrink();
            return _VoiceInputOverlay(partial: partial);
          }),
          const ChatInputBar(),
        ],
      ),
    );
  }
}

class _VoiceInputOverlay extends StatelessWidget {
  final String partial;
  const _VoiceInputOverlay({required this.partial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: AppSizes.space2,
      ),
      color: AppColors.surfaceMutedColor,
      child: Row(
        children: [
          const Icon(
            Icons.mic_rounded,
            size: AppSizes.iconSM,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: AppSizes.space2),
          Expanded(
            child: AppText(
              partial.isEmpty ? 'chat_listening'.tr : partial,
              variant: AppTextVariant.bodyLarge,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space4, vertical: AppSizes.space2),
      color: AppColors.warningBannerColor,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: AppSizes.iconSM, color: AppColors.warningDarkColor),
          const SizedBox(width: AppSizes.space2),
          Expanded(
            child: AppText(
              message,
              variant: AppTextVariant.caption,
              color: AppColors.warningDarkColor,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSizes.space2),
            GestureDetector(
              onTap: onRetry,
              child: AppText(
                'retry'.tr,
                variant: AppTextVariant.caption,
                fontWeight: FontWeight.w600,
                color: AppColors.warningDarkColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final AiChatController controller;

  const _ChatList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          ListView.separated(
            controller: controller.scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space4, AppSizes.space3, AppSizes.space4, AppSizes.space2,
            ),
            itemCount: controller.messages.length +
                (controller.isTyping.value ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: AppSizes.space2),
            itemBuilder: (_, index) {
              if (index == controller.messages.length) {
                return const AiTypingBubble();
              }
              return _buildMessageItem(controller, controller.messages[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(AiChatController controller, ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.aiText:
        return Builder(
          builder: (context) => Obx(() => AiMessageBubble(
                message: message,
                onTranslate: () => controller.toggleTranslation(message.id),
                onPlayAudio: () => controller.playAudio(message.id),
                onWordTap: (word) => controller.onWordTap(word, context),
                isSpeaking: controller.ttsService.currentText.value == message.text,
              )),
        );

      case ChatMessageType.userText:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            UserMessageBubble(message: message),
            if (message.correctedText != null) ...[
              const SizedBox(height: AppSizes.space2),
              Align(
                alignment: Alignment.centerRight,
                child: GrammarCorrectionSection(
                  correctedText: message.correctedText!,
                ),
              ),
            ],
          ],
        );

      case ChatMessageType.quickReplies:
        return QuickReplyRow(
          options: message.quickReplies ?? [],
          onSelect: controller.sendMessage,
        );

      case ChatMessageType.aiTyping:
        return const AiTypingBubble();
    }
  }
}
