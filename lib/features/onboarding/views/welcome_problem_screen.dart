import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
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

class WelcomeProblemScreen extends StatefulWidget {
  const WelcomeProblemScreen({super.key});

  @override
  State<WelcomeProblemScreen> createState() => _WelcomeProblemScreenState();
}

class _WelcomeProblemScreenState extends State<WelcomeProblemScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_currentStep < _welcomeSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Get.toNamed(AppRoutes.onboardingNativeLanguage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _welcomeSteps[_currentStep];

    Widget body = Padding(
      padding: const EdgeInsets.only(
          left: AppSizes.padding3XL,
          right: AppSizes.padding3XL,
          top: AppSizes.spacing5XL,
          bottom: AppSizes.spacing6XL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed: step dots indicator
          StepDotsIndicator(activeStep: _currentStep),
          const SizedBox(height: AppSizes.spacing4XL),

          // Sliding: only headline + subtext
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              itemCount: _welcomeSteps.length,
              itemBuilder: (context, index) {
                final step = _welcomeSteps[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.headline,
                      style: GoogleFonts.outfit(
                        fontSize: AppSizes.font9XL,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: AppSizes.trackingTight,
                        height: AppSizes.lineHeightTight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXL),
                    Text(
                      step.subtext,
                      style: GoogleFonts.outfit(
                        fontSize: AppSizes.fontXL,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: AppSizes.lineHeightXLoose,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Fixed: bottom tap hint or CTA button
          if (data.showCta)
            _buildCtaButton(data.ctaLabel!)
          else
            _buildTapHint(),
        ],
      ),
    );

    // Wrap in GestureDetector for non-CTA steps
    if (!data.showCta) {
      body = GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: body,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed: top bar
            const OnboardingTopBar(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return Center(
      child: Text(
        'Tap anywhere to continue',
        style: GoogleFonts.outfit(
          fontSize: AppSizes.fontL,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildCtaButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightL,
      child: ElevatedButton(
        onPressed: _onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: AppSizes.fontXXL,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
