import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/language_card.dart';

class LearningLanguageScreen extends StatelessWidget {
  const LearningLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.inputHeight,
                left: AppSizes.paddingXXL,
                right: AppSizes.paddingXXL,
                bottom: AppSizes.paddingXXL,
              ),
              child: Column(
                children: [
                  Text(
                    "What do you want\nto learn?",
                    style: GoogleFonts.outfit(
                      fontSize: AppSizes.font6XL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: AppSizes.trackingSnug,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    "Choose a language to get started",
                    style: GoogleFonts.outfit(
                      fontSize: AppSizes.fontM,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: AppSizes.lineHeightNormal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Language grid
            Expanded(
              child: Obx(() {
                if (controller.isLoadingLanguages.value) {
                  return _buildSkeleton();
                }
                if (controller.learningLanguages.isEmpty) {
                  return _buildError(controller);
                }
                return GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.spacingL,
                  crossAxisSpacing: AppSizes.spacingL,
                  childAspectRatio: 0.95,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
                  children: controller.learningLanguages.map((lang) {
                    return LanguageGridCard(
                      language: lang,
                      isSelected:
                          controller.selectedLearningLanguage.value == lang.code,
                      onTap: () => controller.selectLearningLanguage(
                        lang.code,
                        id: lang.id,
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSizes.spacingL,
      crossAxisSpacing: AppSizes.spacingL,
      childAspectRatio: 0.95,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: Border.all(color: AppColors.borderLight),
          ),
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
