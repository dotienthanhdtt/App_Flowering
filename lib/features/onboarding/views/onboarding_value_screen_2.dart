import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/onboarding_value_layout.dart';

/// Onboarding value screen 2 — "Learn once. Remember forever."
/// Exempt from BaseStatelessScreen: OnboardingValueLayout provides its own Scaffold.
class OnboardingValueScreen2 extends StatelessWidget {
  const OnboardingValueScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingValueLayout(
      imagePath: 'assets/images/onboarding/onboarding_value_2.png',
      headlineKey: 'onboarding_value_headline_2',
      bodyKey: 'onboarding_value_body_2',
      ctaKey: 'onboarding_next',
      ctaVariant: AppButtonVariant.primary,
      onCtaPressed: () => Get.offNamed(AppRoutes.onboardingWelcome3),
    );
  }
}
