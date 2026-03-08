import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

/// Screen 11 — Email login with social auth options and forgot password link.
class LoginEmailScreen extends StatelessWidget {
  const LoginEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: Get.back,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingXXL, AppSizes.paddingXS, AppSizes.paddingXXL, AppSizes.paddingXXL),
                child: Form(
                  key: ctrl.loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.font6XL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: AppSizes.trackingSnug,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      Text(
                        'Log in to continue your journey',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.fontM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing3XL),
                      // Social auth
                      SocialAuthButton(
                        provider: SocialProvider.apple,
                        onTap: ctrl.signInWithApple,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      SocialAuthButton(
                        provider: SocialProvider.google,
                        onTap: ctrl.signInWithGoogle,
                      ),
                      const SizedBox(height: AppSizes.spacingXL),
                      // "or" divider
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.borderLight)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
                            child: Text(
                              'or',
                              style: GoogleFonts.outfit(
                                fontSize: AppSizes.fontSM,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.borderLight)),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingXL),
                      AuthTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: ctrl.loginEmailController,
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'Password',
                            hint: 'Your password',
                            controller: ctrl.loginPasswordController,
                            validator: ctrl.validatePassword,
                            obscureText: ctrl.obscurePassword.value,
                            onToggleObscure: ctrl.obscurePassword.toggle,
                            textInputAction: TextInputAction.done,
                          )),
                      const SizedBox(height: AppSizes.spacingS),
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.outfit(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      // Error message
                      Obx(() {
                        if (ctrl.errorMessage.value.isEmpty) {
                          return const SizedBox(height: AppSizes.spacingL);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSizes.spacingM),
                          child: Text(
                            ctrl.errorMessage.value,
                            style: GoogleFonts.outfit(
                              fontSize: AppSizes.fontSM,
                              color: AppColors.error,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppSizes.spacingXXL),
                      // Submit button
                      Obx(() => GestureDetector(
                            onTap: ctrl.isLoading.value ? null : ctrl.login,
                            child: Container(
                              height: AppSizes.buttonHeightM,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusPill),
                              ),
                              alignment: Alignment.center,
                              child: ctrl.isLoading.value
                                  ? const SizedBox(
                                      width: AppSizes.iconL,
                                      height: AppSizes.iconL,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Log In',
                                      style: GoogleFonts.outfit(
                                        fontSize: AppSizes.fontXL,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          )),
                      const SizedBox(height: AppSizes.spacingXL),
                      // Signup link
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.signup),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: AppSizes.fontM,
                                color: AppColors.textSecondary,
                              ),
                              children: const [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign up',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
