import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/chat-home-controller.dart';
import '../widgets/chat-conversation-tile.dart';

/// Chat home tab — shows conversation list or empty state
class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatHomeController>();

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXXL,
        vertical: AppSizes.paddingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText('chat_home_title'.tr, variant: AppTextVariant.h2),
          IconButton(
            onPressed: () => Get.find<ChatHomeController>().startNewChat(),
            icon: const Icon(
              LucideIcons.plus,
              color: AppColors.primary,
              size: AppSizes.iconXL,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ChatHomeController controller) {
    if (controller.conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      itemCount: controller.conversations.length,
      itemBuilder: (context, index) {
        final conversation = controller.conversations[index];
        return ChatConversationTile(
          title: conversation['title'] ?? '',
          subtitle: conversation['subtitle'] ?? '',
          timestamp: conversation['timestamp'] ?? '',
          onTap: () {},
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.messageCircle,
            size: AppSizes.icon3XL,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.spacingL),
          AppText(
            'chat_home_empty'.tr,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSizes.spacingS),
          AppText(
            'chat_home_start'.tr,
            variant: AppTextVariant.label,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
