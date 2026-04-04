import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends BaseScreen<SplashController> {
  const SplashScreen({super.key});

  static const Color _splashBg = Color(0xFFFF8762);

  @override
  bool get useSafeArea => false;

  @override
  bool get showLoadingOverlay => false;

  @override
  Color? get backgroundColor => _splashBg;

  @override
  Widget buildContent(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn,
          builder: (context, opacity, child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: AppText(
            'app_name'.tr,
            variant: AppTextVariant.h1,
            fontSize: AppSizes.fontSize5XLarge,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
