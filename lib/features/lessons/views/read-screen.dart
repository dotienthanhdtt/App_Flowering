import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/read-controller.dart';

/// Read tab — shows reading sections or empty state
class ReadScreen extends StatelessWidget {
  const ReadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReadController>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text('read_title'.tr, style: AppTextStyles.h2),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.search,
              color: AppColors.textSecondary,
              size: AppSizes.iconXL,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ReadController controller) {
    if (controller.sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.bookOpen,
              size: AppSizes.icon3XL,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSizes.spacingL),
            Text(
              'read_empty'.tr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      itemCount: controller.sections.length,
      itemBuilder: (context, index) {
        return const SizedBox.shrink();
      },
    );
  }
}
