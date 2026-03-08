import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/widgets/login_gate_bottom_sheet.dart';
import '../controllers/onboarding_controller.dart';
import '../models/scenario_model.dart';
import '../widgets/scenario_card.dart';

/// Displays AI-generated learning scenarios in a 2-column grid.
/// Navigates to Login Gate (bottom sheet) via CTA.
class ScenarioGiftScreen extends StatelessWidget {
  const ScenarioGiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    final scenarios = controller.onboardingProfile?.scenarios ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              Expanded(child: _ScenarioGrid(scenarios: scenarios)),
              _CtaButton(onTap: () => _showLoginGate(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginGate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginGateBottomSheet(),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingXXL, AppSizes.paddingXXL, AppSizes.paddingXXL, AppSizes.paddingL),
      child: Text(
        'scenario_title'.tr,
        style: GoogleFonts.outfit(
          fontSize: AppSizes.font5XL,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: AppSizes.trackingSnug,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ScenarioGrid extends StatelessWidget {
  final List<Scenario> scenarios;

  const _ScenarioGrid({required this.scenarios});

  @override
  Widget build(BuildContext context) {
    if (scenarios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding3XL),
          child: Text(
            'scenario_empty'.tr,
            style: GoogleFonts.outfit(
              fontSize: AppSizes.fontL,
              color: AppColors.textTertiary,
              height: AppSizes.lineHeightLoose,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL, vertical: AppSizes.spacingS),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 230,
      ),
      itemCount: scenarios.length,
      itemBuilder: (_, i) => ScenarioCard(scenario: scenarios[i]),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CtaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingSM, AppSizes.paddingXXL, AppSizes.paddingSM, AppSizes.padding3XL),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSizes.buttonHeightM,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30FF7A27),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'scenario_cta'.tr,
            style: GoogleFonts.outfit(
              fontSize: AppSizes.fontXL,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
