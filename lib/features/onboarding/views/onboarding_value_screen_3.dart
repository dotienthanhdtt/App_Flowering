import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/auth/widgets/login_gate_bottom_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/onboarding_value_layout.dart';

/// Onboarding value screen 3 — "Fluency isn't a test. It's a feeling."
/// Exempt from BaseStatelessScreen: OnboardingValueLayout provides its own Scaffold.
///
/// For returning users (hasCompletedLogin flag), the "I'm ready" CTA shows the
/// auth bottom sheet instead of proceeding to language selection.
class OnboardingValueScreen3 extends StatelessWidget {
  const OnboardingValueScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingValueLayout(
      imagePath: 'assets/images/onboarding/onboarding_value_3.png',
      headlineKey: 'onboarding_value_headline_3',
      bodyKey: 'onboarding_value_body_3',
      ctaKey: 'onboarding_ready',
      ctaVariant: AppButtonVariant.primary,
      onCtaPressed: () {
        if (Get.find<StorageService>().hasCompletedLogin) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const LoginGateBottomSheet(),
          );
        } else {
          Get.offNamed(AppRoutes.onboardingNativeLanguage);
        }
      },
    );
  }
}
