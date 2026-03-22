import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/read-controller.dart';

/// Read tab — shows reading sections or empty state.
/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold.
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
        horizontal: AppSizes.space6,
        vertical: AppSizes.space4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText('read_title'.tr, variant: AppTextVariant.h2),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.search,
              color: AppColors.textSecondaryColor,
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
              color: AppColors.textTertiaryColor,
            ),
            const SizedBox(height: AppSizes.space4),
            AppText(
              'read_empty'.tr,
              variant: AppTextVariant.bodyMedium,
              color: AppColors.textTertiaryColor,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
      itemCount: controller.sections.length,
      itemBuilder: (context, index) {
        return const SizedBox.shrink();
      },
    );
  }
}
