import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../shared/widgets/empty_or_error_view.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../chat/widgets/chat_top_bar.dart';
import '../controllers/scenario_detail_controller.dart';
import '../widgets/scenario_detail_cta.dart';

class ScenarioDetailScreen extends BaseScreen<ScenarioDetailController> {
  const ScenarioDetailScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    return Obx(() {
      final detail = controller.detail.value;
      final loading = controller.isLoading.value;
      final notFound = controller.notFound.value;
      final errMsg = controller.errorMessage.value;

      if (loading && detail == null) {
        return const Center(child: LoadingWidget());
      }

      if (notFound) {
        return Column(
          children: [
            ChatTopBar(title: 'scenario_detail_title'.tr),
            Expanded(
              child: EmptyOrErrorView(
                icon: LucideIcons.searchX,
                message: 'scenario_detail_not_found'.tr,
              ),
            ),
          ],
        );
      }

      if (detail == null && errMsg.isNotEmpty) {
        return Column(
          children: [
            ChatTopBar(title: 'scenario_detail_title'.tr),
            Expanded(
              child: EmptyOrErrorView(
                icon: LucideIcons.alertCircle,
                message: errMsg,
                onRetry: controller.fetch,
                retryLabel: 'retry'.tr,
              ),
            ),
          ],
        );
      }

      if (detail == null) {
        return const Center(child: LoadingWidget());
      }

      return Column(
        children: [
          ChatTopBar(title: detail.title),
          const Divider(height: 1, thickness: 1, color: AppColors.borderColor),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroImage(imageUrl: detail.imageUrl),
                  _InfoSection(
                    title: detail.title,
                    description: detail.description,
                    difficulty: detail.difficulty,
                    category: detail.category.name,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderColor),
          Container(
            color: AppColors.surfaceColor,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: ScenarioDetailCta(
              detail: detail,
              onStart: controller.startChat,
              onPracticeAgain: controller.practiceAgain,
              onUpgrade: controller.openPaywall,
            ),
          ),
        ],
      );
    });
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  const _HeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (ctx, url2) => _placeholder(),
              errorWidget: (ctx, url2, err) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceMutedColor,
      child: const Icon(
        LucideIcons.image,
        color: AppColors.textTertiaryColor,
        size: AppSizes.icon4XL,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String? description;
  final String difficulty;
  final String category;

  const _InfoSection({
    required this.title,
    this.description,
    required this.difficulty,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            fontSize: AppSizes.fontSize2XLarge,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor,
          ),
          const SizedBox(height: AppSizes.space2),
          Row(
            children: [
              _Chip(difficulty),
              const SizedBox(width: AppSizes.space2),
              if (category.isNotEmpty) _Chip(category),
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space4),
            AppText(
              description!,
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textSecondaryColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space3,
        vertical: AppSizes.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: AppText(
        label,
        fontSize: AppSizes.fontSizeSmall,
        color: AppColors.textSecondaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
