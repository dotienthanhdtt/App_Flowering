import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_language_model.dart';
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
              padding: const EdgeInsets.only(top: 16, left: 24),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppColors.radiusM),
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
                top: 24,
                left: 24,
                right: 24,
                bottom: 16,
              ),
              child: Column(
                children: [
                  Text(
                    "What's your native\nlanguage?",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We'll personalize your learning experience",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Language list
            Expanded(
              child: Obx(
                () => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: OnboardingLanguage.nativeLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = OnboardingLanguage.nativeLanguages[index];
                    return LanguageListCard(
                      language: lang,
                      isSelected:
                          controller.selectedNativeLanguage.value == lang.code,
                      onTap: () => controller.selectNativeLanguage(lang.code),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
