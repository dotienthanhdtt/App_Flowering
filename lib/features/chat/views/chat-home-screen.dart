import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull-to-refresh-list.dart';
import '../../lessons/models/lesson-models.dart';
import '../../lessons/widgets/scenario-card.dart';
import '../controllers/chat-home-controller.dart';
import '../widgets/home-language-button.dart';
import '../widgets/language-picker-sheet.dart';

/// Chat home tab — shows /lessons scenarios grouped by category for selection.
/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold.
class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatHomeController>();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, controller),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  /// Header: language-flag dropdown (left) per `09_chat_screen`.
  /// Right side reserved for future streak pill (design node `6Rcjp`).
  Widget _buildHeader(BuildContext context, ChatHomeController controller) {
    return SizedBox(
      height: AppSizes.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => HomeLanguageButton(
                  active: controller.activeLanguage.value,
                  onTap: () => _openLanguagePicker(context, controller),
                )),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _openLanguagePicker(
    BuildContext context,
    ChatHomeController controller,
  ) async {
    await controller.loadAvailableLanguages();
    if (!context.mounted) return;
    await LanguagePickerSheet.show(
      context,
      languages: controller.availableLanguages.toList(),
      activeCode: controller.activeLanguage.value?.code,
      onSelect: controller.switchActiveLanguage,
    );
  }

  Widget _buildBody(ChatHomeController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.categories.isEmpty) {
        return const LoadingWidget();
      }

      if (controller.categories.isEmpty) {
        return _buildEmptyState(controller);
      }

      return PullToRefreshList(
        isRefreshing: controller.isRefreshing,
        onRefresh: controller.refreshLessons,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: controller.categories.length,
          itemBuilder: (_, i) =>
              _buildCategorySection(controller.categories[i]),
        ),
      );
    });
  }

  Widget _buildEmptyState(ChatHomeController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.messageCircle,
            size: AppSizes.icon3XL,
            color: AppColors.textTertiaryColor,
          ),
          const SizedBox(height: AppSizes.space4),
          AppText(
            'chat_home_empty'.tr,
            variant: AppTextVariant.bodyMedium,
            color: AppColors.textTertiaryColor,
          ),
          if (controller.errorMessage.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space2),
            AppText(
              controller.errorMessage.value,
              variant: AppTextVariant.caption,
              color: AppColors.errorColor,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// One section per category: title + 2-column scenario grid.
  Widget _buildCategorySection(LessonCategory category) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(category),
          const SizedBox(height: AppSizes.space3),
          _buildScenarioGrid(category),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(LessonCategory category) {
    final icon = category.icon;
    return Row(
      children: [
        if (icon != null && icon.isNotEmpty) ...[
          _buildCategoryIcon(icon),
          const SizedBox(width: AppSizes.space2),
        ],
        Expanded(
          child: AppText(
            category.name,
            variant: AppTextVariant.h2,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  /// Renders emoji as text, URLs as a small network image.
  Widget _buildCategoryIcon(String icon) {
    if (icon.startsWith('http')) {
      return Image.network(icon, width: 22, height: 22, fit: BoxFit.contain);
    }
    return Text(icon, style: const TextStyle(fontSize: 18));
  }

  /// 2-column grid matching design `Row` layout with gap 12.
  Widget _buildScenarioGrid(LessonCategory category) {
    final scenarios = category.scenarios;
    final rowCount = (scenarios.length / 2).ceil();

    return Column(
      children: List.generate(rowCount, (rowIdx) {
        final left = scenarios[rowIdx * 2];
        final right =
            rowIdx * 2 + 1 < scenarios.length ? scenarios[rowIdx * 2 + 1] : null;

        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIdx < rowCount - 1 ? AppSizes.space3 : 0,
          ),
          child: Row(
            children: [
              Expanded(child: ScenarioCard(scenario: left)),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? ScenarioCard(scenario: right)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }
}
