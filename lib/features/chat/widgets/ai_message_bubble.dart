import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/chat_message_model.dart';

/// AI message bubble with avatar, "Flora" label, text, optional translation,
/// and translate/play text-style action buttons.
class AiMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTranslate;
  final VoidCallback? onPlayAudio;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onTranslate,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiAvatar(),
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
                Text(
                  'Flora',
                  style: GoogleFonts.outfit(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                // Message text
                Text(
                  message.text ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: AppSizes.fontM,
                    color: AppColors.textPrimary,
                    height: AppSizes.lineHeightLoose,
                  ),
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
                            Text(
                              'Vietnamese',
                              style: GoogleFonts.outfit(
                                fontSize: AppSizes.fontXXS,
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingXS),
                        Text(
                          message.translatedText!,
                          style: GoogleFonts.outfit(
                            fontSize: AppSizes.fontSM,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: AppSizes.lineHeightLoose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.spacingS),
                // Action buttons — text style with icons
                Row(
                  children: [
                    _TextActionButton(
                      icon: Icons.translate_rounded,
                      label: message.showTranslation
                          ? 'chat_hide_translation'.tr
                          : 'chat_translate'.tr,
                      color: AppColors.info,
                      onTap: onTranslate,
                    ),
                    const SizedBox(width: AppSizes.spacingL),
                    _TextActionButton(
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

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.avatarM,
      height: AppSizes.avatarM,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Image.asset('assets/logos/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Text button with leading icon for message actions.
class _TextActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _TextActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconXS, color: color),
          const SizedBox(width: AppSizes.spacingXS),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick-reply chip row — goal selection buttons shown under Flora's first message.
class QuickReplyRow extends StatelessWidget {
  final List<String> options;
  final void Function(String) onSelect;

  const QuickReplyRow({
    super.key,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.inputHeight),
      child: Wrap(
        spacing: AppSizes.spacingS,
        runSpacing: AppSizes.spacingS,
        children: options
            .map(
              (opt) => GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM, vertical: AppSizes.paddingXS),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08191919),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.outfit(
                      fontSize: AppSizes.fontSM,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Animated three-dot AI typing indicator.
class AiTypingBubble extends StatefulWidget {
  const AiTypingBubble({super.key});

  @override
  State<AiTypingBubble> createState() => _AiTypingBubbleState();
}

class _AiTypingBubbleState extends State<AiTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiAvatar(),
        const SizedBox(width: AppSizes.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.font3XL, vertical: AppSizes.paddingM),
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
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final offset = (i / 3);
                final val =
                    ((_ctrl.value - offset) % 1.0).clamp(0.0, 1.0);
                final scale = 0.6 + 0.4 * (val < 0.5 ? val * 2 : (1 - val) * 2);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? AppSizes.spacingSM : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: AppSizes.spacingS,
                      height: AppSizes.spacingS,
                      decoration: BoxDecoration(
                        color: i == 1
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
