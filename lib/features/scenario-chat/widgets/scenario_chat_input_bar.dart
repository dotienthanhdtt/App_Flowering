import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Simple text-only input bar for the scenario chat screen.
/// Decoupled from AiChatController — sends via [onSend] callback.
/// Uses raw TextField (not AppTextField) because the chat pill-outline
/// variant requires `enabled` prop + custom border radii not supported
/// by AppTextField's form-focused API.
class ScenarioChatInputBar extends StatefulWidget {
  final bool enabled;
  final void Function(String text) onSend;

  const ScenarioChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
  });

  @override
  State<ScenarioChatInputBar> createState() => _ScenarioChatInputBarState();
}

class _ScenarioChatInputBarState extends State<ScenarioChatInputBar> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceColor,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space4,
        AppSizes.space2,
        AppSizes.space2,
        AppSizes.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: widget.enabled
                    ? AppColors.textPrimaryColor
                    : AppColors.textTertiaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'chat_type_message'.tr,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiaryColor,
                  fontSize: AppSizes.fontSizeMedium,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space4,
                  vertical: AppSizes.space3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  borderSide: const BorderSide(color: AppColors.borderLightColor),
                ),
                filled: true,
                fillColor: widget.enabled
                    ? AppColors.surfaceColor
                    : AppColors.surfaceMutedColor,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.space2),
          IconButton(
            onPressed: widget.enabled ? _submit : null,
            icon: Icon(
              Icons.send_rounded,
              color: widget.enabled
                  ? AppColors.primaryColor
                  : AppColors.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
