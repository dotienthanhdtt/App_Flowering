import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends BaseScreen<SplashController> {
  const SplashScreen({super.key});

  @override
  bool get useSafeArea => false;

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => AppColors.primary;

  @override
  Widget buildContent(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/logo.png',
              width: 180,
              height: 180,
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.spacingL),
                  AppText(
                    'app_name'.tr,
                    variant: AppTextVariant.h1,
                    fontSize: AppSizes.font10XL,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  AppText(
                    'splash_subtitle'.tr,
                    variant: AppTextVariant.bodyLarge,
                    fontSize: AppSizes.fontL,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
