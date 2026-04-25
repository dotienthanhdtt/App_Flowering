import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text.dart';
import '../../chat/models/chat_message_model.dart';
import '../../chat/widgets/ai_message_bubble.dart';
import '../../chat/widgets/ai_typing_bubble.dart';
import '../../chat/widgets/chat_top_bar.dart';
import '../../chat/widgets/grammar_correction_section.dart';
import '../../chat/widgets/user_message_bubble.dart';
import '../controllers/scenario_chat_controller.dart';
import '../widgets/scenario_chat_input_bar.dart';

class ScenarioChatScreen extends BaseScreen<ScenarioChatController> {
  const ScenarioChatScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        Obx(() => ChatTopBar(title: controller.scenarioTitle)),
        Expanded(child: _MessageList()),
        // Partial transcript overlay shown while the mic is live
        Obx(() {
          final isListening = controller.voiceInputService.isListening.value;
          final partial = controller.voiceInputService.partialText.value;
          if (!isListening) return const SizedBox.shrink();
          return _VoiceInputOverlay(partial: partial);
        }),
        Obx(() {
          if (controller.completed.value) return const _ViewResultBar();
          if (controller.kickoffFailed.value) {
            return _KickoffErrorBanner(onRetry: controller.retryKickoff);
          }
          return const ScenarioChatInputBar();
        }),
      ],
    );
  }
}

class _MessageList extends GetView<ScenarioChatController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msgs = controller.messages;
      return ListView.separated(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space4,
          vertical: AppSizes.space4,
        ),
        itemCount: msgs.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.space4),
        itemBuilder: (ctx, i) => _buildMessage(ctx, msgs[i]),
      );
    });
  }

  Widget _buildMessage(BuildContext context, ChatMessage msg) {
    switch (msg.type) {
      case ChatMessageType.aiTyping:
        return const AiTypingBubble();
      case ChatMessageType.userText:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            UserMessageBubble(message: msg),
            if (msg.correctedText != null) ...[
              const SizedBox(height: AppSizes.space2),
              Align(
                alignment: Alignment.centerRight,
                child: GrammarCorrectionSection(
                  correctedText: msg.correctedText!,
                ),
              ),
            ],
          ],
        );
      case ChatMessageType.aiText:
        return Obx(() => AiMessageBubble(
              message: msg,
              onTranslate: () => controller.toggleTranslation(msg.id),
              onPlayAudio: () => controller.playAudio(msg.id),
              onWordTap: (word) => controller.onWordTap(word),
              isSpeaking:
                  controller.ttsService.currentText.value == msg.text,
            ));
      default:
        return const SizedBox.shrink();
    }
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

class _ViewResultBar extends StatelessWidget {
  const _ViewResultBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: AppSizes.space3,
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          text: 'scenario_chat_view_result'.tr,
          onPressed: () {},
        ),
      ),
    );
  }
}

class _KickoffErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _KickoffErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceColor,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space4,
        AppSizes.space3,
        AppSizes.space4,
        AppSizes.space3,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorColor, size: AppSizes.iconL),
          const SizedBox(width: AppSizes.space3),
          Expanded(
            child: AppText(
              'scenario_chat_error_send'.tr,
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(width: AppSizes.space3),
          AppButton(
            text: 'retry'.tr,
            onPressed: onRetry,
            isFullWidth: false,
            height: AppSizes.icon3XL,
          ),
        ],
      ),
    );
  }
}
