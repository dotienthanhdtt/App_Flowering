import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';

class NativeLanguageScreen extends StatelessWidget {
  const NativeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.paddingL, left: AppSizes.paddingXXL),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: AppSizes.inputHeight,
                  height: AppSizes.inputHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.paddingXXL,
                left: AppSizes.paddingXXL,
                right: AppSizes.paddingXXL,
                bottom: AppSizes.paddingL,
              ),
              child: Column(
                children: [
                  Text(
                    "What's your native\nlanguage?",
                    style: GoogleFonts.outfit(
                      fontSize: AppSizes.font6XL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: AppSizes.trackingSnug,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    "We'll personalize your learning experience",
                    style: GoogleFonts.outfit(
                      fontSize: AppSizes.fontM,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: AppSizes.lineHeightNormal,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),

            // Language list
            Expanded(
              child: Obx(() {
                if (controller.isLoadingLanguages.value) {
                  return _buildSkeleton();
                }
                if (controller.nativeLanguages.isEmpty) {
                  return _buildError(controller);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXXL,
                    vertical: AppSizes.paddingXS,
                  ),
                  itemCount: controller.nativeLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSizes.spacingM),
                  itemBuilder: (context, index) {
                    final lang = controller.nativeLanguages[index];
                    return LanguageListCard(
                      language: lang,
                      isSelected:
                          controller.selectedNativeLanguage.value == lang.code,
                      onTap: () =>
                          controller.selectNativeLanguage(lang.code, id: lang.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXXL, vertical: AppSizes.paddingXS),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.spacingM),
      itemBuilder: (_, _) => Container(
        height: AppSizes.cardHeightCompact,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.borderLight),
        ),
      ),
    );
  }

  Widget _buildError(OnboardingController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load languages',
            style: GoogleFonts.outfit(
              fontSize: AppSizes.fontM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          GestureDetector(
            onTap: controller.loadLanguages,
            child: Text(
              'Retry',
              style: GoogleFonts.outfit(
                fontSize: AppSizes.fontM,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
