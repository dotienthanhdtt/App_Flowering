import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
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

List<_WelcomeStepData> get _welcomeSteps => [
  _WelcomeStepData(
    headline: 'welcome_headline_1'.tr,
    subtext: 'welcome_body_1'.tr,
    activeStep: 0,
  ),
  _WelcomeStepData(
    headline: 'welcome_headline_2'.tr,
    subtext: 'welcome_body_2'.tr,
    activeStep: 1,
  ),
  _WelcomeStepData(
    headline: 'welcome_headline_3'.tr,
    subtext: 'welcome_body_3'.tr,
    activeStep: 2,
    showCta: true,
    ctaLabel: 'welcome_cta'.tr,
  ),
];

/// StatefulWidget — exempt from BaseScreen (needs State lifecycle for PageController).
class WelcomeProblemScreen extends StatefulWidget {
  const WelcomeProblemScreen({super.key});

  @override
  State<WelcomeProblemScreen> createState() => _WelcomeProblemScreenState();
}

class _WelcomeProblemScreenState extends State<WelcomeProblemScreen> {
  final _pageController = PageController();
  final _currentStep = ValueNotifier<int>(0);

  @override
  void dispose() {
    _pageController.dispose();
    _currentStep.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_currentStep.value < _welcomeSteps.length - 1) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ValueListenableBuilder<int>(
          valueListenable: _currentStep,
          builder: (context, step, _) {
            final data = _welcomeSteps[step];

            Widget body = Padding(
              padding: const EdgeInsets.only(
                  left: AppSizes.padding3XL,
                  right: AppSizes.padding3XL,
                  top: AppSizes.spacing5XL,
                  bottom: AppSizes.spacing6XL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepDotsIndicator(activeStep: step),
                  const SizedBox(height: AppSizes.spacing4XL),
                  Expanded(child: _buildPageView()),
                  if (data.showCta)
                    _buildCtaButton(data.ctaLabel!)
                  else
                    _buildTapHint(),
                ],
              ),
            );

            if (!data.showCta) {
              body = GestureDetector(
                onTap: _onTap,
                behavior: HitTestBehavior.opaque,
                child: body,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnboardingTopBar(),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => _currentStep.value = index,
      itemCount: _welcomeSteps.length,
      itemBuilder: (context, index) {
        final step = _welcomeSteps[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              step.headline,
              style: AppTextStyles.h1.copyWith(
                fontSize: AppSizes.font9XL,
                fontWeight: FontWeight.w800,
                letterSpacing: AppSizes.trackingTight,
                height: AppSizes.lineHeightTight,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXL),
            AppText(
              step.subtext,
              variant: AppTextVariant.bodyLarge,
              color: AppColors.textSecondary,
              height: AppSizes.lineHeightXLoose,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTapHint() {
    return Center(
      child: AppText(
        'welcome_tap_continue'.tr,
        variant: AppTextVariant.bodyLarge,
        fontSize: AppSizes.fontL,
        color: AppColors.textTertiary,
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
        child: AppText(
          label,
          variant: AppTextVariant.button,
          fontSize: AppSizes.fontXXL,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
