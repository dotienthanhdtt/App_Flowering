import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app-route-constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Screen 10 — Email signup with full name, email, password, confirm password.
class SignupEmailScreen extends StatelessWidget {
  const SignupEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button
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
                  key: ctrl.signupFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.font6XL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: AppSizes.trackingSnug,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSM),
                      Text(
                        'Start your language journey',
                        style: GoogleFonts.outfit(
                          fontSize: AppSizes.fontM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing3XL),
                      AuthTextField(
                        label: 'Full Name',
                        hint: 'Your name',
                        controller: ctrl.fullNameController,
                        validator: ctrl.validateFullName,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      AuthTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: ctrl.emailController,
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'Password',
                            hint: 'At least 8 characters',
                            controller: ctrl.passwordController,
                            validator: ctrl.validatePassword,
                            obscureText: ctrl.obscurePassword.value,
                            onToggleObscure: ctrl.obscurePassword.toggle,
                          )),
                      const SizedBox(height: AppSizes.spacingL),
                      Obx(() => AuthTextField(
                            label: 'Confirm Password',
                            hint: 'Repeat your password',
                            controller: ctrl.confirmPasswordController,
                            validator: (v) => ctrl.validateConfirmPassword(
                              v,
                              ctrl.passwordController.text,
                            ),
                            obscureText: ctrl.obscureConfirmPassword.value,
                            onToggleObscure: ctrl.obscureConfirmPassword.toggle,
                            textInputAction: TextInputAction.done,
                          )),
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
                            onTap: ctrl.isLoading.value ? null : ctrl.register,
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
                                      'Create Account',
                                      style: GoogleFonts.outfit(
                                        fontSize: AppSizes.fontXL,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          )),
                      const SizedBox(height: AppSizes.spacingXL),
                      // Login link
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.login),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: AppSizes.fontM,
                                color: AppColors.textSecondary,
                              ),
                              children: const [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Log in',
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
