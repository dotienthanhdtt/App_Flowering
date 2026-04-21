import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../../scenarios/views/flowering_tab.dart';
import '../../scenarios/views/for_you_tab.dart';
import '../controllers/chat-home-controller.dart';
import '../widgets/home-language-button.dart';
import '../widgets/language-picker-sheet.dart';

/// Chat home tab — hosts the language flag button and two top-tabs
/// (For You / Flowering) backed by the scenarios API v2.
/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold.
class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatHomeController>();
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        initialIndex: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, controller),
            _buildTabBar(),
            const Expanded(
              child: TabBarView(
                children: [ForYouTab(), FloweringTab()],
              ),
            ),
          ],
        ),
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

  Widget _buildTabBar() {
    return TabBar(
      indicatorColor: AppColors.primaryColor,
      indicatorWeight: 3,
      labelColor: AppColors.textPrimaryColor,
      unselectedLabelColor: AppColors.textTertiaryColor,
      dividerColor: AppColors.borderLightColor,
      tabs: [
        Tab(child: AppText('tab_for_you'.tr, variant: AppTextVariant.button)),
        Tab(child: AppText('tab_flowering'.tr, variant: AppTextVariant.button)),
      ],
    );
  }
}
