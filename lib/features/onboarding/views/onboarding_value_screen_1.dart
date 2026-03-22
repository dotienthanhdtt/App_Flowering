import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/onboarding_value_layout.dart';

/// Onboarding value screen 1 — "A path shaped around you"
/// Exempt from BaseStatelessScreen: OnboardingValueLayout provides its own Scaffold.
class OnboardingValueScreen1 extends StatelessWidget {
  const OnboardingValueScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingValueLayout(
      imagePath: 'assets/images/onboarding/onboarding_value_1.png',
      headlineKey: 'onboarding_value_headline_1',
      bodyKey: 'onboarding_value_body_1',
      ctaKey: 'onboarding_next',
      ctaVariant: AppButtonVariant.outline,
      onCtaPressed: () => Get.offNamed(AppRoutes.onboardingWelcome2),
    );
  }
}
