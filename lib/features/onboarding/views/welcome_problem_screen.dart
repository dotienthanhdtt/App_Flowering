import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/onboarding_top_bar.dart';
import '../widgets/step_dots_indicator.dart';

class _WelcomeStepData {
  final String headline;
  final String subtext;
  final int activeStep;
  final bool showCta;
  final String? ctaLabel;

  const _WelcomeStepData({
    required this.headline,
    required this.subtext,
    required this.activeStep,
    this.showCta = false,
    this.ctaLabel,
  });
}

const _welcomeSteps = [
  _WelcomeStepData(
    headline: "Your brain\nwasn't built\nto memorize.",
    subtext:
        "It was built to speak. Flowering works with your brain — not against it.",
    activeStep: 0,
  ),
  _WelcomeStepData(
    headline: "You forget\nbecause nothing\nwas built for you.",
    subtext:
        "Generic apps give everyone the same lesson. Flowering remembers what you struggled with — and brings it back at the right moment.",
    activeStep: 1,
  ),
  _WelcomeStepData(
    headline: "Finally, an app\nthat knows\nonly you.",
    subtext:
        "Your pace. Your interests. Your goals. Flowering builds a living path that evolves as you do — nobody else gets the same one.",
    activeStep: 2,
    showCta: true,
    ctaLabel: "Make it mine",
  ),
];

class WelcomeProblemScreen extends StatelessWidget {
  final int step;

  const WelcomeProblemScreen({super.key, required this.step});

  void _onTap() {
    switch (step) {
      case 0:
        Get.toNamed(AppRoutes.onboardingWelcome2);
        break;
      case 1:
        Get.toNamed(AppRoutes.onboardingWelcome3);
        break;
      case 2:
        Get.toNamed(AppRoutes.onboardingNativeLanguage);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _welcomeSteps[step];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              top: 48,
              bottom: 60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section: dots + headline + subtext
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepDotsIndicator(activeStep: data.activeStep),
                    const SizedBox(height: 32),
                    Text(
                      data.headline,
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      data.subtext,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),

                // Bottom section: tap hint or CTA
                if (data.showCta)
                  _buildCtaButton(data.ctaLabel!)
                else
                  _buildTapHint(),
              ],
            ),
          ),
        ),
      ],
    );

    Widget scaffold;
    if (!data.showCta) {
      scaffold = Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: body,
        ),
      );
    } else {
      scaffold = Scaffold(
        backgroundColor: AppColors.background,
        body: body,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: scaffold,
    );
  }

  Widget _buildTapHint() {
    return Center(
      child: Text(
        'Tap anywhere to continue',
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildCtaButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
