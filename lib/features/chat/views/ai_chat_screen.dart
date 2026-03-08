import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/chat_message_model.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_top_bar.dart';
import '../widgets/user_message_bubble.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Screen 07 — AI onboarding chat with Flora using real /onboarding/* APIs.
class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiChatController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Obx(() => ChatTopBar(
                progress: controller.progress.value,
                onSkip: controller.skipOnboarding,
              )),
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
              Expanded(child: _ChatList(controller: controller)),
              const ChatInputBar(),
            ],
          ),
        ),
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
          horizontal: AppSizes.paddingL, vertical: AppSizes.paddingXS),
      color: const Color(0xFFFFF3CD),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: AppSizes.iconSM, color: Color(0xFF856404)),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                  fontSize: AppSizes.fontXS, color: const Color(0xFF856404)),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSizes.spacingS),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.outfit(
                  fontSize: AppSizes.fontXS,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF856404),
                ),
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
            padding: const EdgeInsets.all(AppSizes.paddingL),
            itemCount: controller.messages.length +
                (controller.isTyping.value ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spacingL),
            itemBuilder: (_, index) {
              if (index == controller.messages.length) {
                return const AiTypingBubble();
              }
              return _buildMessageItem(controller.messages[index]);
            },
          ),
          if (controller.isLoading.value)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.aiText:
        return AiMessageBubble(
          message: message,
          onTranslate: () => controller.toggleTranslation(message.id),
          onPlayAudio: () => controller.playAudio(message.id),
        );

      case ChatMessageType.userText:
        return UserMessageBubble(text: message.text ?? '');

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
