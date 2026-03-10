import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/vocabulary-controller.dart';

/// Vocabulary tab — search bar + word list or empty state.
/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold.
class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VocabularyController>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(controller),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingXXL,
        right: AppSizes.paddingXXL,
        top: AppSizes.paddingL,
        bottom: AppSizes.paddingXS,
      ),
      child: AppText('vocabulary_title'.tr, variant: AppTextVariant.h2),
    );
  }

  Widget _buildSearchBar(VocabularyController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXXL,
        vertical: AppSizes.paddingXS,
      ),
      child: TextField(
        onChanged: controller.updateSearch,
        decoration: InputDecoration(
          hintText: 'vocabulary_search'.tr,
          hintStyle: AppTextStyles.caption,
          prefixIcon: const Icon(
            LucideIcons.search,
            size: AppSizes.iconL,
            color: AppColors.textTertiary,
          ),
          filled: true,
          fillColor: AppColors.surfaceMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSizes.paddingSM,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(VocabularyController controller) {
    return Obx(() {
      final words = controller.filteredWords;
      if (words.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.languages,
                size: AppSizes.icon3XL,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSizes.spacingL),
              AppText(
                'vocabulary_empty'.tr,
                variant: AppTextVariant.bodyMedium,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        itemCount: words.length,
        itemBuilder: (context, index) {
          final word = words[index];
          return ListTile(
            title: AppText(word['term'] ?? '', variant: AppTextVariant.label),
            subtitle: AppText(word['translation'] ?? '', variant: AppTextVariant.caption),
          );
        },
      );
    });
  }
}
