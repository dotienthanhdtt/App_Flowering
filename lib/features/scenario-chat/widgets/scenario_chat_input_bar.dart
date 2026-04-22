import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../chat/widgets/chat_action_button.dart';
import '../../chat/widgets/chat_recording_bar.dart';
import '../../chat/widgets/chat_text_input_field.dart';
import '../controllers/scenario_chat_controller.dart';

/// Bottom input bar for the scenario chat screen. Mirrors the onboarding
/// chat's three states: empty (mic), has text (send), recording
/// (cancel + waveform + send). Backed by [ScenarioChatController] so
/// voice input + STT flows match the onboarding chat experience.
class ScenarioChatInputBar extends StatelessWidget {
  const ScenarioChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScenarioChatController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space4,
        AppSizes.space2,
        AppSizes.space4,
        AppSizes.space4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(top: BorderSide(color: AppColors.borderLightColor)),
      ),
      child: Obx(() {
        final isComplete = controller.completed.value;
        final isSending = controller.isSending.value;
        final isRecording = controller.isRecording.value;
        final sttAvailable = controller.voiceInputService.sttAvailable.value;
        final enabled = !isComplete && !isSending;

        if (isRecording) {
          return ChatRecordingBar(
            duration: controller.recordingDuration,
            amplitude: controller.recordingAmplitude,
            onCancel: controller.cancelRecording,
            onSend: controller.stopRecording,
          );
        }

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.textEditingController,
          builder: (_, textValue, child) {
            final hasText = textValue.text.trim().isNotEmpty;
            return Row(
              children: [
                Expanded(
                  child: ChatTextInputField(
                    textController: controller.textEditingController,
                    enabled: enabled,
                    onSubmitted: controller.sendText,
                    isComplete: isComplete,
                  ),
                ),
                const SizedBox(width: 10),
                ChatActionButton(
                  showSend: hasText && enabled,
                  onSend: (hasText && enabled)
                      ? () => controller.sendText(
                            controller.textEditingController.text,
                          )
                      : null,
                  onMic: (enabled && !hasText && sttAvailable)
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
