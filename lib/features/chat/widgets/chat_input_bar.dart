import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/ai_chat_controller.dart';

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
          return _RecordingBar(controller: controller);
        }

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.textEditingController,
          builder: (_, textValue, child) {
            final hasText = textValue.text.isNotEmpty;
            return Row(
              children: [
                Expanded(
                  child: _TextInputField(
                    textController: controller.textEditingController,
                    enabled: !isComplete,
                    onSubmitted: controller.sendMessage,
                    isComplete: isComplete,
                  ),
                ),
                const SizedBox(width: 10),
                _ActionButton(
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

class _TextInputField extends StatelessWidget {
  final TextEditingController textController;
  final bool enabled;
  final bool isComplete;
  final void Function(String) onSubmitted;

  const _TextInputField({
    required this.textController,
    required this.enabled,
    required this.onSubmitted,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: textController,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: GoogleFonts.outfit(fontSize: AppSizes.fontM, color: AppColors.textPrimary),
        decoration: InputDecoration.collapsed(
          hintText: isComplete ? 'chat_complete'.tr : 'chat_type_message'.tr,
          hintStyle: GoogleFonts.outfit(
            fontSize: AppSizes.fontM,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// Send (orange) or Mic (orange) button depending on input state.
class _ActionButton extends StatelessWidget {
  final bool showSend;
  final VoidCallback? onSend;
  final VoidCallback? onMic;

  const _ActionButton({required this.showSend, this.onSend, this.onMic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showSend ? onSend : onMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: AppSizes.inputHeight,
        height: AppSizes.inputHeight,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          showSend ? Icons.send_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: AppSizes.iconM,
        ),
      ),
    );
  }
}

/// Recording bar: cancel (X) + waveform area (red dot, timer, bars) + send.
class _RecordingBar extends StatelessWidget {
  final AiChatController controller;

  const _RecordingBar({required this.controller});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel button
        GestureDetector(
          onTap: controller.cancelRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: AppSizes.iconSM, color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        // Red dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        // Timer
        Obx(() => Text(
              _formatDuration(controller.recordingDuration.value),
              style: GoogleFonts.outfit(
                fontSize: AppSizes.fontM,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            )),
        const SizedBox(width: AppSizes.spacingM),
        // Waveform bars
        Expanded(child: _WaveformBars()),
        const SizedBox(width: AppSizes.spacingM),
        // Send button
        GestureDetector(
          onTap: controller.stopRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, size: AppSizes.iconSM, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Animated waveform bars for recording visualization.
class _WaveformBars extends StatefulWidget {
  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(20, (i) {
          final phase = (i / 20 + _ctrl.value) % 1.0;
          final height = 6.0 + 18.0 * (0.5 + 0.5 * _sin(phase * 3.14159 * 2));
          return Container(
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }

  double _sin(double x) {
    // Simple sine approximation for animation
    x = x % (3.14159 * 2);
    if (x > 3.14159) x -= 3.14159 * 2;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
