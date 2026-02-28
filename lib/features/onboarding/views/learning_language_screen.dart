import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_language_model.dart';
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
                top: 40,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Text(
                    "What do you want\nto learn?",
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
                    "Choose a language to get started",
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

            // Language grid
            Expanded(
              child: Obx(
                () => GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: OnboardingLanguage.learningLanguages.map((lang) {
                    return LanguageGridCard(
                      language: lang,
                      isSelected: controller.selectedLearningLanguage.value ==
                          lang.code,
                      onTap: () =>
                          controller.selectLearningLanguage(lang.code),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
