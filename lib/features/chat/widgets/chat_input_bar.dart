import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/ai_chat_controller.dart';
import 'chat_action_button.dart';
import 'chat_recording_bar.dart';
import 'chat_text_input_field.dart';

/// Bottom input bar — text field + send/mic button + recording state.
/// Three states: empty (mic), has text (send), recording (cancel+waveform+send).
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiChatController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingL, AppSizes.paddingXS, AppSizes.paddingL, AppSizes.paddingL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Obx(() {
        final isComplete = controller.isChatComplete.value;
        final isRecording = controller.isRecording.value;

        if (isRecording) {
          return ChatRecordingBar(controller: controller);
        }

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.textEditingController,
          builder: (_, textValue, child) {
            final hasText = textValue.text.isNotEmpty;
            return Row(
              children: [
                Expanded(
                  child: ChatTextInputField(
                    textController: controller.textEditingController,
                    enabled: !isComplete,
                    onSubmitted: controller.sendMessage,
                    isComplete: isComplete,
                  ),
                ),
                const SizedBox(width: 10),
                ChatActionButton(
                  showSend: hasText && !isComplete,
                  onSend: (hasText && !isComplete)
                      ? () => controller.sendMessage(
                            controller.textEditingController.text,
                          )
                      : null,
                  onMic: (!isComplete && !hasText)
                      ? controller.startRecording
                      : null,
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
