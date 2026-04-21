import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/auth/widgets/login_gate_bottom_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/onboarding_value_layout.dart';

/// Onboarding value screen 1 — "A path shaped around you"
/// Exempt from BaseStatelessScreen: OnboardingValueLayout provides its own Scaffold.
///
/// For returning users (hasCompletedLogin flag), the auth bottom sheet is shown
/// automatically on entry so they can log back in with a single tap.
class OnboardingValueScreen1 extends StatefulWidget {
  const OnboardingValueScreen1({super.key});

  @override
  State<OnboardingValueScreen1> createState() => _OnboardingValueScreen1State();
}

class _OnboardingValueScreen1State extends State<OnboardingValueScreen1> {
  @override
  void initState() {
    super.initState();
    if (Get.find<StorageService>().hasCompletedLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAuthSheet());
    }
  }

  void _showAuthSheet() {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginGateBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingValueLayout(
      imagePath: 'assets/images/onboarding/onboarding_value_1.png',
      headlineKey: 'onboarding_value_headline_1',
      bodyKey: 'onboarding_value_body_1',
      ctaKey: 'onboarding_next',
      ctaVariant: AppButtonVariant.primary,
      onCtaPressed: () => Get.offNamed(AppRoutes.onboardingWelcome2),
    );
  }
}
