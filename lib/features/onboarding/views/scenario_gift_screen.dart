import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../../auth/widgets/login_gate_bottom_sheet.dart';
import '../controllers/onboarding_controller.dart';
import '../models/scenario_model.dart';
import '../widgets/scenario_card.dart';

/// Displays AI-generated learning scenarios in a 2-column grid.
/// Navigates to Login Gate (bottom sheet) via CTA.
class ScenarioGiftScreen extends BaseScreen<OnboardingController> {
  const ScenarioGiftScreen({super.key});

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.backgroundColor;

  @override
  Widget buildContent(BuildContext context) {
    final scenarios = controller.onboardingProfile?.scenarios ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(),
          Expanded(child: _ScenarioGrid(scenarios: scenarios)),
          _CtaButton(onTap: () => _showLoginGate(context)),
        ],
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
          AppSizes.space6, AppSizes.space6, AppSizes.space6, AppSizes.space4),
      child: AppText(
        'scenario_title'.tr,
        style: AppTextStyles.h3.copyWith(
          fontSize: AppSizes.fontSize2XLarge,
          fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space8),
          child: AppText(
            'scenario_empty'.tr,
            variant: AppTextVariant.bodyLarge,
            fontSize: AppSizes.fontSizeMedium,
            color: AppColors.textTertiaryColor,
            height: AppSizes.lineHeightBase,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space4, vertical: AppSizes.space2),
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
          AppSizes.space3, AppSizes.space6, AppSizes.space3, AppSizes.space8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSizes.buttonHeightLarge,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
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
          child: AppText(
            'scenario_cta'.tr,
            variant: AppTextVariant.bodyLarge,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
